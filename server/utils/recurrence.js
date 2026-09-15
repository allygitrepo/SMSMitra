/**
 * Pure algorithm to calculate the next execution DateTime for a recurring SMS rule.
 * 
 * @param {string} frequencyType - 'daily' | 'alternate' | 'weekly' | 'monthly' | 'custom'
 * @param {object} frequencyConfig - configuration object
 * @param {string} dispatchTime - "HH:mm" (e.g. "09:30")
 * @param {Date|string} fromDate - calculation base date (defaults to now)
 * @returns {Date} - exact next execution DateTime
 */
const calculateNextRun = (frequencyType, frequencyConfig = {}, dispatchTime = '09:00', fromDate = new Date()) => {
  const baseDate = new Date(fromDate);
  const [hoursStr, minutesStr] = dispatchTime.split(':');
  const hours = parseInt(hoursStr, 10) || 0;
  const minutes = parseInt(minutesStr, 10) || 0;

  const now = new Date();

  // Helper to build a date on given year, month, day with the exact dispatchTime
  const createScheduledDate = (year, month, day) => {
    return new Date(year, month, day, hours, minutes, 0, 0);
  };

  switch (frequencyType) {
    case 'daily': {
      let candidate = createScheduledDate(baseDate.getFullYear(), baseDate.getMonth(), baseDate.getDate());
      if (candidate <= now) {
        candidate.setDate(candidate.getDate() + 1);
      }
      return candidate;
    }

    case 'alternate': {
      const startFrom = frequencyConfig.startFrom || 'today';
      let candidate = createScheduledDate(baseDate.getFullYear(), baseDate.getMonth(), baseDate.getDate());

      if (startFrom === 'tomorrow' && candidate.getDate() === baseDate.getDate()) {
        candidate.setDate(candidate.getDate() + 1);
      }

      while (candidate <= now) {
        candidate.setDate(candidate.getDate() + 2);
      }
      return candidate;
    }

    case 'weekly': {
      // daysOfWeek: array of integers 1 (Mon) to 7 (Sun)
      const rawDays = frequencyConfig.daysOfWeek && frequencyConfig.daysOfWeek.length > 0
        ? frequencyConfig.daysOfWeek
        : [1]; // default Monday
      
      const targetDays = rawDays.map(d => parseInt(d, 10));

      // Scan up to 14 days ahead to find the earliest matching day
      let candidate = createScheduledDate(baseDate.getFullYear(), baseDate.getMonth(), baseDate.getDate());
      for (let offset = 0; offset <= 14; offset++) {
        const testDate = new Date(candidate);
        testDate.setDate(testDate.getDate() + offset);
        
        // JS getDay(): 0=Sun, 1=Mon, ..., 6=Sat. Convert to 1=Mon ... 7=Sun
        const jsDay = testDate.getDay();
        const isoDay = jsDay === 0 ? 7 : jsDay;

        if (targetDays.includes(isoDay) && testDate > now) {
          return testDate;
        }
      }

      candidate.setDate(candidate.getDate() + 7);
      return candidate;
    }

    case 'monthly': {
      // daysOfMonth: array of integers (1..31)
      const rawDays = frequencyConfig.daysOfMonth && frequencyConfig.daysOfMonth.length > 0
        ? frequencyConfig.daysOfMonth
        : [1]; // default 1st
      
      const targetDays = rawDays.map(d => parseInt(d, 10)).sort((a, b) => a - b);

      let year = baseDate.getFullYear();
      let month = baseDate.getMonth();

      // Scan through current month and subsequent 3 months
      for (let mOffset = 0; mOffset < 4; mOffset++) {
        const currentMonth = (month + mOffset) % 12;
        const currentYear = year + Math.floor((month + mOffset) / 12);
        const daysInMonth = new Date(currentYear, currentMonth + 1, 0).getDate();

        for (const targetDay of targetDays) {
          const effectiveDay = Math.min(targetDay, daysInMonth);
          const candidate = createScheduledDate(currentYear, currentMonth, effectiveDay);
          if (candidate > now) {
            return candidate;
          }
        }
      }

      const nextMonthFirst = createScheduledDate(year, month + 1, 1);
      return nextMonthFirst;
    }

    case 'custom': {
      const customType = frequencyConfig.customType || 'weekdays';
      if (customType === 'weekdays') {
        return calculateNextRun('weekly', frequencyConfig, dispatchTime, fromDate);
      } else if (customType === 'monthdays') {
        return calculateNextRun('monthly', frequencyConfig, dispatchTime, fromDate);
      } else {
        return calculateNextRun('daily', frequencyConfig, dispatchTime, fromDate);
      }
    }

    default:
      return calculateNextRun('daily', frequencyConfig, dispatchTime, fromDate);
  }
};

/**
 * Generates user-friendly description of recurrence
 */
const formatFrequencyDescription = (frequencyType, frequencyConfig = {}, dispatchTime = '09:00') => {
  const [h, m] = dispatchTime.split(':');
  const hourNum = parseInt(h, 10);
  const period = hourNum >= 12 ? 'PM' : 'AM';
  const displayHour = hourNum % 12 === 0 ? 12 : hourNum % 12;
  const timeFormatted = `${displayHour.toString().padLeft ? displayHour.toString().padLeft(2, '0') : displayHour}:${m} ${period}`;

  switch (frequencyType) {
    case 'daily':
      return `Daily @ ${timeFormatted}`;
    case 'alternate':
      return `Alternate Days (${frequencyConfig.startFrom === 'tomorrow' ? 'From Tomorrow' : 'From Today'}) @ ${timeFormatted}`;
    case 'weekly': {
      const dayNames = { 1: 'Mon', 2: 'Tue', 3: 'Wed', 4: 'Thu', 5: 'Fri', 6: 'Sat', 7: 'Sun' };
      const days = (frequencyConfig.daysOfWeek || [1]).map(d => dayNames[d] || d).join(', ');
      return `Every ${days} @ ${timeFormatted}`;
    }
    case 'monthly': {
      const days = (frequencyConfig.daysOfMonth || [1]).map(d => `${d}${getOrdinal(d)}`).join(', ');
      return `Monthly on ${days} @ ${timeFormatted}`;
    }
    case 'custom':
      return `Custom Recurrence @ ${timeFormatted}`;
    default:
      return `Recurring @ ${timeFormatted}`;
  }
};

const getOrdinal = (n) => {
  const s = ['th', 'st', 'nd', 'rd'];
  const v = n % 100;
  return s[(v - 20) % 10] || s[v] || s[0];
};

module.exports = {
  calculateNextRun,
  formatFrequencyDescription,
};
