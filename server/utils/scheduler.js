const { Op } = require('sequelize');
const ScheduledSms = require('../models/scheduledsms.model');
const FrequentSms = require('../models/frequentsms.model');
const User = require('../models/user.model');
const SimDetail = require('../models/simdetail.model');
const SmsLog = require('../models/smslog.model');
const admin = require('../config/firebase');
const { calculateNextRun } = require('./recurrence');

let schedulerTimer = null;

/**
 * Executes a single scheduled SMS job
 */
const processScheduledJob = async (job, io) => {
  try {
    const user = await User.findByPk(job.userId);
    if (!user) {
      job.status = 'failed';
      job.errorMessage = 'User account not found';
      job.executedAt = new Date();
      await job.save();
      return;
    }

    if (!user.fcmToken) {
      job.status = 'failed';
      job.errorMessage = 'Device not registered for push notifications (FCM)';
      job.executedAt = new Date();
      await job.save();
      return;
    }

    // Determine SIM to use
    let selectedSim = null;
    if (job.simId) {
      selectedSim = await SimDetail.findOne({
        where: { userId: user.id, simId: job.simId, isActive: true },
      });
    }

    if (!selectedSim) {
      const availableSims = await SimDetail.findAll({
        where: { userId: user.id, isActive: true },
        order: [['priority', 'ASC']],
      });
      if (availableSims.length > 0) {
        selectedSim = availableSims[0];
      }
    }

    // Create tracking SmsLog
    const log = await SmsLog.create({
      userId: user.id,
      receiverNumber: job.receiverNumber,
      message: job.message,
      simId: selectedSim ? selectedSim.simId : null,
      status: 'pending',
    });

    job.logId = log.id;
    job.status = 'completed';
    job.executedAt = new Date();
    await job.save();

    // Prepare FCM payload
    const payload = {
      token: user.fcmToken,
      data: {
        type: 'SEND_SMS',
        logId: log.id.toString(),
        phoneNumber: job.receiverNumber,
        message: job.message,
        simId: selectedSim ? selectedSim.simId : '',
      },
      android: {
        priority: 'high',
      },
    };

    if (admin.apps && admin.apps.length > 0) {
      await admin.messaging().send(payload);
    } else {
      console.warn(`[Scheduler] Firebase not initialized. Created log #${log.id} for scheduled job #${job.id}.`);
    }

    // Real-time notification over WebSockets
    if (io) {
      io.to(user.id.toString()).emit('stats_update');
      io.to(user.id.toString()).emit('schedules_update');
    }

    console.log(`[Scheduler] Successfully dispatched scheduled SMS #${job.id} to ${job.receiverNumber} for user ${user.id}`);
  } catch (error) {
    console.error(`[Scheduler] Error processing scheduled job #${job.id}:`, error.message);
    job.status = 'failed';
    job.errorMessage = error.message;
    job.executedAt = new Date();
    await job.save();
  }
};

/**
 * Executes a single recurring/frequent SMS job
 */
const processFrequentJob = async (rule, io) => {
  try {
    const user = await User.findByPk(rule.userId);
    if (!user) {
      rule.status = 'paused';
      await rule.save();
      return;
    }

    if (!user.fcmToken) {
      console.warn(`[Scheduler] User ${user.id} has no FCM token for recurring SMS #${rule.id}.`);
      return;
    }

    // Determine SIM to use
    let selectedSim = null;
    if (rule.simId) {
      selectedSim = await SimDetail.findOne({
        where: { userId: user.id, simId: rule.simId, isActive: true },
      });
    }

    if (!selectedSim) {
      const availableSims = await SimDetail.findAll({
        where: { userId: user.id, isActive: true },
        order: [['priority', 'ASC']],
      });
      if (availableSims.length > 0) {
        selectedSim = availableSims[0];
      }
    }

    // Create tracking SmsLog
    const log = await SmsLog.create({
      userId: user.id,
      receiverNumber: rule.receiverNumber,
      message: rule.message,
      simId: selectedSim ? selectedSim.simId : null,
      status: 'pending',
    });

    const now = new Date();
    rule.lastRunAt = now;
    rule.totalDispatchedCount = (rule.totalDispatchedCount || 0) + 1;
    // Calculate next run occurrence
    rule.nextRunAt = calculateNextRun(rule.frequencyType, rule.frequencyConfig, rule.dispatchTime, now);
    rule.status = 'active';
    await rule.save();

    // Prepare FCM payload
    const payload = {
      token: user.fcmToken,
      data: {
        type: 'SEND_SMS',
        logId: log.id.toString(),
        phoneNumber: rule.receiverNumber,
        message: rule.message,
        simId: selectedSim ? selectedSim.simId : '',
      },
      android: {
        priority: 'high',
      },
    };

    if (admin.apps && admin.apps.length > 0) {
      await admin.messaging().send(payload);
    }

    if (io) {
      io.to(user.id.toString()).emit('stats_update');
      io.to(user.id.toString()).emit('frequent_update');
    }

    console.log(`[Scheduler] Successfully dispatched Recurring SMS #${rule.id} to ${rule.receiverNumber}. Next run: ${rule.nextRunAt.toISOString()}`);
  } catch (error) {
    console.error(`[Scheduler] Error processing recurring job #${rule.id}:`, error.message);
  }
};

/**
 * Polling tick that checks for due scheduled and recurring SMS jobs
 */
const runSchedulerTick = async (io) => {
  try {
    const now = new Date();

    // 1. One-time scheduled SMS
    const dueJobs = await ScheduledSms.findAll({
      where: {
        status: 'scheduled',
        scheduledAt: { [Op.lte]: now },
      },
      limit: 50,
      order: [['scheduledAt', 'ASC']],
    });

    if (dueJobs.length > 0) {
      console.log(`[Scheduler] Found ${dueJobs.length} due scheduled SMS job(s). Processing...`);
      for (const job of dueJobs) {
        job.status = 'processing';
        await job.save();
        await processScheduledJob(job, io);
      }
    }

    // 2. Recurring / Frequent SMS rules
    const dueFrequent = await FrequentSms.findAll({
      where: {
        status: 'active',
        nextRunAt: { [Op.lte]: now },
      },
      limit: 50,
      order: [['nextRunAt', 'ASC']],
    });

    if (dueFrequent.length > 0) {
      console.log(`[Scheduler] Found ${dueFrequent.length} due recurring SMS rule(s). Processing...`);
      for (const rule of dueFrequent) {
        await processFrequentJob(rule, io);
      }
    }
  } catch (error) {
    console.error('[Scheduler] Tick error:', error.message);
  }
};

/**
 * Starts the background scheduler loop
 */
const startScheduler = (io, intervalMs = 20000) => {
  if (schedulerTimer) {
    clearInterval(schedulerTimer);
  }

  console.log(`[Scheduler] SMS Scheduling background worker started (interval: ${intervalMs / 1000}s).`);

  // Initial immediate check
  runSchedulerTick(io);

  schedulerTimer = setInterval(() => {
    runSchedulerTick(io);
  }, intervalMs);
};

const stopScheduler = () => {
  if (schedulerTimer) {
    clearInterval(schedulerTimer);
    schedulerTimer = null;
    console.log('[Scheduler] Background worker stopped.');
  }
};

module.exports = {
  startScheduler,
  stopScheduler,
  runSchedulerTick,
};
