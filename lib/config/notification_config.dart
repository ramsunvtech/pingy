class NotificationConfig {
  // ========== NOTIFICATION TIMES - Change these to test ==========
  
  // Weekday reminder (Monday-Friday only)
  static const int weekdayHour = 12;
  static const int weekdayMinute = 35;
  
  // Evening reminder (Every day)
  static const int eveningHour = 20;
  static const int eveningMinute = 0;
  
  // Motivation reminder (For users without goals - 9 AM daily)
  static const int motivationHour = 9;
  static const int motivationMinute = 0;
  
  // Inactive user reminder (For users who haven't logged today - 8 PM)
  static const int inactiveHour = 20;
  static const int inactiveMinute = 0;
  
  // Daily reminder (For all users with goals - 9 PM)
  static const int dailyHour = 21;
  static const int dailyMinute = 0;
  
  // ========== NOTIFICATION IDs (Don't change these) ==========
  static const int weekdayReminderId = 1;
  static const int eveningReminderId = 2;
  static const int dailyReminderId = 100;
  static const int motivationReminderId = 101;
  static const int inactiveReminderId = 102;
  
  // ========== NOTIFICATION MESSAGES ==========
  static const String weekdayTitle = 'Steppy Reminder';
  static const String weekdayBody = 'Time to update your activities! Keep going! 💪';
  
  static const String eveningTitle = 'Steppy Reminder';
  static const String eveningBody = 'Good Evening, Time to update your activities :)';
}