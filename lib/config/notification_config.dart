class NotificationConfig {
  // ========== NOTIFICATION TIMES ==========
  
  // Daily morning reminder (10 AM - every day including weekends, when goals exist)
  static const int dailyMorningHour = 10;
  static const int dailyMorningMinute = 0;
  
  // Daily evening reminder (8 PM - every day including weekends, when goals exist)
  static const int dailyEveningHour = 20;
  static const int dailyEveningMinute = 0;
  
  // Motivation reminder (11:30 AM - weekdays only, when NO goals exist)
  static const int motivationHour = 11;
  static const int motivationMinute = 30;
  
  // ========== NOTIFICATION IDs ==========
  static const int dailyMorningReminderId = 100;
  static const int dailyEveningReminderId = 101;
  
  // Weekday motivation IDs (Mon-Fri)
  static const int motivationMondayId = 102;
  static const int motivationTuesdayId = 103;
  static const int motivationWednesdayId = 104;
  static const int motivationThursdayId = 105;
  static const int motivationFridayId = 106;
}