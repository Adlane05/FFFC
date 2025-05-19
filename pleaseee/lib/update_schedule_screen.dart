import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'home_screen.dart';

class UpdateScheduleScreen extends StatefulWidget {
  const UpdateScheduleScreen({super.key});

  @override
  State<UpdateScheduleScreen> createState() => _UpdateScheduleScreenState();
}

class _UpdateScheduleScreenState extends State<UpdateScheduleScreen> {
  final PageController _pageController = PageController();

  final GlobalKey<_BusySlotPickerState> busySlotPickerGlobalKey = GlobalKey<_BusySlotPickerState>();

  Future<void> _submitSurvey() async {
    final user = FirebaseAuth.instance.currentUser!;
    final selectedSlots = busySlotPickerGlobalKey.currentState?._selectedSlots ?? {};

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'busySlots': selectedSlots,
      }, SetOptions(merge: true));

      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => HomeScreen()));
    } catch (e) {
      debugPrint('Error saving changes: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Error saving changes')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF10AF9C),
        title: const Text(
          'Update your schedule',
          style: TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontFamily: 'Jersey 25',
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          BusySlotPicker(key: busySlotPickerGlobalKey,),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(
              onPressed: _submitSurvey,
              child: Text('Finish'),
            ),
          ],
        ),
      ),
    );
  }
}

class BusySlotPicker extends StatefulWidget {

  const BusySlotPicker({Key? key}) : super(key: key);

  @override
  State<BusySlotPicker> createState() => _BusySlotPickerState();
}

class _BusySlotPickerState extends State<BusySlotPicker> {
  final user = FirebaseAuth.instance.currentUser!;
  Map<String, List<String>> _selectedSlots = {};

  final List<String> weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday'
  ];

  String _selectedDay = 'Monday';

  @override
  void initState() {
    super.initState();
    initBusySlots();
  }

  Future<Map<String, List<String>>> getBusySlots() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (snapshot.exists) {
        final data = snapshot.data();

        if (data != null) {
          Map<String, dynamic> mapData = data["busySlots"];
          Map<String, List<String>> busySlots = mapData.map((key, value) {
            List<String> list = List<String>.from(value);
            return MapEntry(key, list);
          });
          return busySlots;
        }
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  void initBusySlots() async {
    Map<String, List<String>> slots = await getBusySlots();
    setState(() {
      _selectedSlots = slots;
    });
  }

  List<String> _generateDaytimeSlots() {
    final slots = <String>[];
    for (int hour = 8; hour < 18; hour++) {
      slots.add('${hour.toString().padLeft(2, '0')}:00');
      slots.add('${hour.toString().padLeft(2, '0')}:30');
    }
    return slots;
  }

  @override
  Widget build(BuildContext context) {
    final timeSlots = _generateDaytimeSlots();
    final selected = _selectedSlots[_selectedDay] ?? [];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('Select your busy time slots',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedDay,
            items: weekdays
                .map((day) => DropdownMenuItem(value: day, child: Text(day)))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedDay = value);
              }
            },
            decoration: const InputDecoration(
                border: OutlineInputBorder(), labelText: 'Day'),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 3,
                crossAxisSpacing: 0,
                mainAxisSpacing: 0,
              ),
              itemCount: timeSlots.length,
              itemBuilder: (context, index) {
                final slot = timeSlots[index];
                final isSelected = selected.contains(slot);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedSlots[_selectedDay] ??= [];
                      if (isSelected) {
                        _selectedSlots[_selectedDay]!.remove(slot);
                      } else {
                        _selectedSlots[_selectedDay]!.add(slot);
                      }
                    });
                  },
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.teal : Colors.white,
                      border: Border.all(
                          color: isSelected ? Colors.teal : Colors.grey),
                    ),
                    child: Text(slot,
                        style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
