// home_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pleaseee/friend_profile_screen.dart';
import 'package:pleaseee/survey_screen.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:intl/intl.dart';

class _CalendarData {
  final List<Appointment> appointments;
  final List<LegendEntry> legend;
  _CalendarData(this.appointments, this.legend);
}
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final user = FirebaseAuth.instance.currentUser!;
  late Future<_CalendarData> _calendarDataFuture;

  @override
  void initState() {
    super.initState();
    _calendarDataFuture = _fetchCalendarData();
  }

  /// Holds both the appointments and the legend entries

  Future<_CalendarData> _fetchCalendarData() async {
  try {
  final today = DateTime.now();
  final monday = today.subtract(Duration(days: today.weekday - 1));
  final usersCol = FirebaseFirestore.instance.collection('users');

  // --- Fetch current user doc ---
  final meSnap = await usersCol.doc(user.uid).get();
  if (!meSnap.exists) {
  throw Exception("Logged-in user doc not found");
  }
  final meData = meSnap.data()!;
  debugPrint("🟢 [Home] meData = $meData");

  // --- Fetch friends docs ---
  final friendIds = List<String>.from(meData['friends'] ?? []);
  final friendSnaps = await Future.wait(
  friendIds.map((fid) => usersCol.doc(fid).get()),
  );

  // --- Build list of users with their busySlots maps ---
  final List<_UserData> allUsers = [];

  // Helper to extract busySlots map safely:
  Map<String,List<String>> extractBusy(Map<String,dynamic> data) {
  final raw = data['busySlots'];
  if (raw is Map<String, dynamic>) {
  return raw.map((k, v) {
  final list = v is List ? List<String>.from(v) : <String>[];
  return MapEntry(k, list);
  });
  }
  return {}; // missing field → treat as fully busy
  }

  allUsers.add(_UserData(
  uid: meSnap.id,
  name: meData['name'] ?? 'You',
  busySlots: extractBusy(meData),
  color: Colors.green,
  ));

  for (var snap in friendSnaps) {
  if (!snap.exists) {
  debugPrint("⚪ [Home] friend ${snap.id} doc missing");
  continue;
  }
  final data = snap.data()!;
  debugPrint("🟡 [Home] friendData(${snap.id}) = $data");
  allUsers.add(_UserData(
  uid: snap.id,
  name: data['name'] ?? data['email'] ?? 'Friend',
  busySlots: extractBusy(data),
  color: Colors.primaries[allUsers.length % Colors.primaries.length],
  ));
  }

  // --- Build legend ---
  final legend = allUsers
      .map((u) => LegendEntry(name: u.name, color: u.color))
      .toList();

  // --- Build appointments for Mon–Fri, 8–18 ---
  final List<Appointment> appts = [];
  for (int dayOff = 0; dayOff < 5; dayOff++) {
  final date = monday.add(Duration(days: dayOff));
  final dayName = DateFormat.EEEE().format(date); // ex: "Monday"
  for (var u in allUsers) {
  final busy = u.busySlots[dayName] ?? <String>[];
  for (int h = 8; h < 18; h++) {
  for (var m in [0, 30]) {
  final slot = '${h.toString().padLeft(2,'0')}:${m.toString().padLeft(2,'0')}';
  if (!busy.contains(slot)) {
  final start = DateTime(date.year, date.month, date.day, h, m);
  appts.add(Appointment(
    startTime: start,
    endTime: start.add(Duration(minutes: 30)),
    color: u.color.withOpacity(0.6),
    subject: u.uid, // Use uid to identify which friend this slot belongs to
  ));
  }
  }
  }
  }
  }

  return _CalendarData(appts, legend);
  } catch (e, st) {
  debugPrint('❗ Error fetching calendar data: $e\n$st');
  // Return empty data so UI can show an error or prompt
  return _CalendarData([], []);
  }
  }

  @override
  Widget build(BuildContext context) {
  return Scaffold(
  appBar: AppBar(
  title: const Text('Shared Calendar'),
  backgroundColor: Colors.teal,
  ),
  body: FutureBuilder<_CalendarData>(
  future: _calendarDataFuture,
  builder: (ctx, snap) {
  if (snap.connectionState == ConnectionState.waiting) {
  return const Center(child: CircularProgressIndicator());
  }
  if (snap.hasError) {
  return Center(child: Text('Error: ${snap.error}'));
  }
  final data = snap.data!;
  if (data.appointments.isEmpty) {
  return Center(
  child: Padding(
  padding: const EdgeInsets.all(24),
  child: Column(
  mainAxisSize: MainAxisSize.min,
  children: [
  const Text(
  'No free slots available.\nPlease complete your survey to populate your schedule.',
  textAlign: TextAlign.center,
  ),
  const SizedBox(height: 20),
  ElevatedButton(
  onPressed: () {
  Navigator.pushReplacement(
  context,
  MaterialPageRoute(builder: (_) => SurveyScreen()),
  );
  },
  child: const Text('Go to Survey'),
  ),
  ],
  ),
  ),
  );
  }

  return Column(
  children: [
  // Legend
  Container(
  height: 48,
  padding: const EdgeInsets.symmetric(horizontal: 16),
  child: ListView.separated(
  scrollDirection: Axis.horizontal,
  itemCount: data.legend.length,
  separatorBuilder: (_, __) => const SizedBox(width: 12),
  itemBuilder: (context, i) {
  final e = data.legend[i];
  return Row(children: [
  Container(width: 16, height: 16, color: e.color),
  const SizedBox(width: 4),
  Text(e.name),
  ]);
  },
  ),
  ),

  // Calendar
  Expanded(
  child: SfCalendar(
  view: CalendarView.workWeek,
  firstDayOfWeek: 1,
  timeSlotViewSettings: const TimeSlotViewSettings(
  startHour: 8,
  endHour: 18,
  timeInterval: Duration(minutes: 30),
  timeFormat: 'HH:mm',
  ),
  showCurrentTimeIndicator: true,
  dataSource: _AppointmentDataSource(data.appointments),
  onTap: (CalendarTapDetails details) {
  if (details.appointments != null && details.appointments!.isNotEmpty) {
  final tappedAppointment = details.appointments!.first as Appointment;
  final tappedUid = tappedAppointment.subject;

  // Prevent navigating for user's own slot
  if (tappedUid != FirebaseAuth.instance.currentUser!.uid) {
  Navigator.push(
  context,
  MaterialPageRoute(
  builder: (_) => FriendProfilePage(friendUid: tappedUid),
  ),
  );
  }
  }
  },
  ),
  ),

  // Free Now
  FutureBuilder<List<String>>(
  future: _computeFreeNow(),
  builder: (ctx, snap2) {
  final list = snap2.data ?? [];
  final text = list.isEmpty
  ? 'No one is free right now.'
      : 'People free now: ${list.join(', ')}';
  return Container(
  color: Colors.grey[200],
  padding: const EdgeInsets.all(12),
  child: Text(text, style: const TextStyle(fontSize: 16)),
  );
  },
  ),
  ],
  );
  },
  ),
  );
  }

  Future<List<String>> _computeFreeNow() async {
  final now = DateTime.now();
  if (now.weekday > 5) return [];
  final slot = '${now.hour.toString().padLeft(2,'0')}:${now.minute < 30 ? '00' : '30'}';
  final weekday = DateFormat.EEEE().format(now);

  final meSnap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
  final meBusy = List<String>.from(meSnap.data()?['busySlots']?[weekday] ?? []);
  final names = <String>[];
  if (!meBusy.contains(slot)) names.add('You');

  final friendIds = List<String>.from(meSnap.data()?['friends'] ?? []);
  for (var fid in friendIds) {
  final doc = await FirebaseFirestore.instance.collection('users').doc(fid).get();
  if (!doc.exists) continue;
  final data = doc.data()!;
  final busy = List<String>.from(data['busySlots']?[weekday] ?? []);
  if (!busy.contains(slot)) names.add(data['name'] ?? data['email'] ?? 'Friend');
  }
  return names;
  }
}

class _UserData {
  final String uid, name;
  final Map<String, List<String>> busySlots;
  final Color color;
  _UserData({required this.uid, required this.name, required this.busySlots, required this.color});
}

class LegendEntry {
  final String name;
  final Color color;
  LegendEntry({required this.name, required this.color});
}

class _AppointmentDataSource extends CalendarDataSource {
  _AppointmentDataSource(List<Appointment> source) {
    appointments = source;
  }
}
