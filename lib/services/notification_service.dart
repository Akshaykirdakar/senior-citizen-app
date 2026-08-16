import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import '../models/member.dart';

/// Schedules a yearly morning (8:00 AM) notification for each member's birthday.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    } catch (_) {}
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);
    final impl = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await impl?.requestNotificationsPermission();
    _ready = true;
  }

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'birthdays',
      'वाढदिवस आठवण',
      channelDescription: 'सभासदांच्या वाढदिवसाची सकाळची आठवण',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  /// Re-schedule reminders for all members (call on start & after data changes).
  static Future<void> syncBirthdayReminders(List<Member> members) async {
    await init();
    await _plugin.cancelAll();
    var id = 1000;
    for (final m in members) {
      if (m.dob.isEmpty) continue;
      final d = DateTime.tryParse(m.dob);
      if (d == null) continue;
      final when = _nextBirthday8am(d);
      try {
        await _plugin.zonedSchedule(
  id++,
  'आज वाढदिवस 🎉',
  '${m.name} यांना वाढदिवसाच्या शुभेच्छा द्या (वय ${m.turningAge})',
  when,
  _details,
  androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
  uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
  matchDateTimeComponents: DateTimeComponents.dateAndTime,
);      } catch (_) {
        // ignore scheduling errors for individual members
      }
      if (id > 1300) break;
    }
  }

  static tz.TZDateTime _nextBirthday8am(DateTime dob) {
    final now = tz.TZDateTime.now(tz.local);
    var d = tz.TZDateTime(tz.local, now.year, dob.month, dob.day, 8, 0);
    if (d.isBefore(now)) d = tz.TZDateTime(tz.local, now.year + 1, dob.month, dob.day, 8, 0);
    return d;
  }
}
