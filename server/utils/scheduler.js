const { Op } = require('sequelize');
const ScheduledSms = require('../models/scheduledsms.model');
const User = require('../models/user.model');
const SimDetail = require('../models/simdetail.model');
const SmsLog = require('../models/smslog.model');
const admin = require('../config/firebase');

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
 * Polling tick that checks for due scheduled SMS jobs
 */
const runSchedulerTick = async (io) => {
  try {
    const now = new Date();

    // Find up to 50 due jobs using indexed query
    const dueJobs = await ScheduledSms.findAll({
      where: {
        status: 'scheduled',
        scheduledAt: { [Op.lte]: now },
      },
      limit: 50,
      order: [['scheduledAt', 'ASC']],
    });

    if (dueJobs.length === 0) return;

    console.log(`[Scheduler] Found ${dueJobs.length} due scheduled SMS job(s). Processing...`);

    for (const job of dueJobs) {
      // Atomic Lock: Mark processing immediately
      job.status = 'processing';
      await job.save();

      // Process dispatch
      await processScheduledJob(job, io);
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
