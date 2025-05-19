import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pleaseee/friend_profile_screen.dart';
import 'package:pleaseee/friends_screen.dart';
import 'package:pleaseee/main.dart';
import 'package:pleaseee/profile_screen.dart';
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

  List<_UserData> allUsers = [];
  List<String> friendRequests = [];

  CalendarController monthController = CalendarController();
  DateTime currentDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _calendarDataFuture = _fetchCalendarData();
    monthController.view = CalendarView.workWeek;
    monthController.displayDate = currentDate;
  }

  Future<_CalendarData> _fetchCalendarData() async {
    try {
      final today = DateTime.now();
      final monday = today.subtract(Duration(days: today.weekday - 1));
      final usersCol = FirebaseFirestore.instance.collection('users');

      final meSnap = await usersCol.doc(user.uid).get();
      if (!meSnap.exists) {
        throw Exception("Logged-in user doc not found");
      }
      final meData = meSnap.data()!;
      debugPrint("🟢 [Home] meData = $meData");

      final friendIds = List<String>.from(meData['friends'] ?? []);
      final friendSnaps = await Future.wait(
        friendIds.map((fid) => usersCol.doc(fid).get()),
      );

      Map<String, List<String>> extractBusy(Map<String, dynamic> data) {
        final raw = data['busySlots'];
        if (raw is Map<String, dynamic>) {
          return raw.map((k, v) {
            final list = v is List ? List<String>.from(v) : <String>[];
            return MapEntry(k, list);
          });
        }
        return {};
      }

      allUsers = [];

      Color colorFromHex(String hex) {
        hex = hex.replaceFirst('#', '');
        if (hex.length == 6) hex = 'ff' + hex;
        return Color(int.parse(hex, radix: 16));
      }

      allUsers.add(_UserData(
        uid: meSnap.id,
        name: meData['name'] ?? 'You',
        busySlots: extractBusy(meData),
        color: meData.containsKey('calendarColor')
            ? colorFromHex(meData['calendarColor'])
            : Colors.green,
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
          color: data.containsKey('calendarColor')
              ? colorFromHex(data['calendarColor'])
              : Colors.primaries[allUsers.length % Colors.primaries.length],
        ));
      }

      final legend = allUsers
          .map((u) => LegendEntry(name: u.name, color: u.color))
          .toList();

      final appointments = _buildAppointments(allUsers, monday);

      return _CalendarData(appointments, legend);
    } catch (e, st) {
      debugPrint('❗ Error fetching calendar data: $e\n$st');
      return _CalendarData([], []);
    }
  }

  List<Appointment> _buildAppointments(List<_UserData> users, DateTime monday) {
    final List<Appointment> appts = [];

    for (int dayOff = 0; dayOff < 5; dayOff++) {
      final date = monday.add(Duration(days: dayOff));
      final dayName = DateFormat.EEEE().format(date);
      for (var u in users) {
        final busy = u.busySlots[dayName] ?? <String>[];
        for (int h = 8; h < 18; h++) {
          for (var m in [0, 30]) {
            final slot = '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
            if (!busy.contains(slot)) {
              final start = DateTime(date.year, date.month, date.day, h, m);
              appts.add(Appointment(
                startTime: start,
                endTime: start.add(Duration(minutes: 30)),
                color: u.color.withOpacity(0.6),
                subject: '',
                notes: u.uid,
              ));
            }
          }
        }
      }
    }
    return appts;
  }

  void _updateFriendColor(String uid, Color newColor) {
    setState(() {
      final idx = allUsers.indexWhere((u) => u.uid == uid);
      if (idx != -1) {
        allUsers[idx] = _UserData(
          uid: allUsers[idx].uid,
          name: allUsers[idx].name,
          busySlots: allUsers[idx].busySlots,
          color: newColor,
        );

        final today = DateTime.now();
        final monday = today.subtract(Duration(days: today.weekday - 1));
        final appointments = _buildAppointments(allUsers, monday);
        final legend = allUsers
            .map((u) => LegendEntry(name: u.name, color: u.color))
            .toList();

        _calendarDataFuture = Future.value(_CalendarData(appointments, legend));
      }
    });
  }

  void goToNextMonth() {
    DateTime firstWorkdayOfNextMonth = DateTime(currentDate.year, currentDate.month + 1, 1);

    while (firstWorkdayOfNextMonth.weekday == DateTime.saturday ||
        firstWorkdayOfNextMonth.weekday == DateTime.sunday) {
      firstWorkdayOfNextMonth = firstWorkdayOfNextMonth.add(Duration(days: 1));
    }

    setState(() {
      currentDate = firstWorkdayOfNextMonth;
      monthController.displayDate = currentDate;
    });
  }

  void goToPreviousMonth() {
    DateTime firstWorkdayOfLastMonth = DateTime(currentDate.year, currentDate.month - 1, 1);

    while (firstWorkdayOfLastMonth.weekday == DateTime.saturday ||
        firstWorkdayOfLastMonth.weekday == DateTime.sunday) {
      firstWorkdayOfLastMonth = firstWorkdayOfLastMonth.add(Duration(days: 1));
    }

    setState(() {
      currentDate = firstWorkdayOfLastMonth;
      monthController.displayDate = currentDate;
    });
  }

  Future<List<String>> getFriendRequests() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (snapshot.exists) {
        final data = snapshot.data();

        if (data != null && data.containsKey('FriendRequests')) {
          List<dynamic> rawFriendRequests = data["FriendRequests"];
          List<String> friendRequests = rawFriendRequests.cast<String>();
          return friendRequests;
        }
      }
      return [];
    } catch (e) {
      return ["1", "2", "3"];
    }
  }

  void initFriendRequests() async {
    friendRequests = await getFriendRequests();
  }
  
  @override
  Widget build(BuildContext context) {
    initFriendRequests();
    return Scaffold(drawer: Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF10AF9C)),
            child: Text(
              'Menu',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: Icon(Icons.person),
            title: Text('Profile'),
            onTap: () async {
               await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
               setState(() {
                 _calendarDataFuture = _fetchCalendarData();
               });
            },
          ),
          ListTile(
            leading: Icon(Icons.group),
            title: Text('Friends'),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => FriendsScreen()),
              );
              setState(() {
                _calendarDataFuture = _fetchCalendarData();
              });
            },
          ),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Logout'),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => LandingPage()),
                    (Route<dynamic> route) => false,
              );
            },
          ),
        ],
      ),
    ),
      appBar: AppBar(
        backgroundColor: const Color(0xFF10AF9C),
        title: const Text(
          'Calendar',
          style: TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontFamily: 'Jersey 25',
            fontWeight: FontWeight.w400,
          ),
        ),
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
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
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
                    IconButton(
                        onPressed: () {
                          // TODO IMPLEMENT DROPDOWN OR SOME KIND OF MENU FOR FRIEND REQUESTS
                        },
                        icon: Icon(Icons.notifications)
                    ),
                    Text("${friendRequests.length}")
                  ]
                )
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back),
                      onPressed: goToPreviousMonth,
                    ),
                    Text(
                      "${currentDate.year} - ${currentDate.month.toString().padLeft(2, '0')}",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: Icon(Icons.arrow_forward),
                      onPressed: goToNextMonth,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SfCalendar(
                  view: CalendarView.workWeek,
                  firstDayOfWeek: 1,
                  headerHeight: 0,
                  controller: monthController,
                  // headerStyle: CalendarHeaderStyle(
                  //     textStyle: TextStyle(color: Colors.black),
                  //     textAlign: TextAlign.center
                  // ),
                  // showNavigationArrow: true,
                  timeSlotViewSettings: const TimeSlotViewSettings(
                    startHour: 8,
                    endHour: 18,
                    timeInterval: Duration(minutes: 30),
                    timeFormat: 'HH:mm',
                  ),
                  showCurrentTimeIndicator: true,
                  dataSource: _AppointmentDataSource(data.appointments),
                  onTap: (details) {
                    if (details.appointments == null || details.appointments!.isEmpty) return;

                    final tappedAppointment = details.appointments!.first as Appointment;
                    final tappedUid = tappedAppointment.notes;
                    if (tappedUid == null || tappedUid == user.uid) return;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FriendProfilePage(
                          friendUid: tappedUid,
                          onColorChanged: (newColor) {
                            _updateFriendColor(tappedUid, newColor);
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),

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
    final slot = '${now.hour.toString().padLeft(2, '0')}:${now.minute < 30 ? '00' : '30'}';
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
  _UserData({
    required this.uid,
    required this.name,
    required this.busySlots,
    required this.color,
  });
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
