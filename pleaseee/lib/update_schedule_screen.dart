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
  final Map<String, dynamic> _answers = {
    'busySlots': <String, List<String>>{},
    'customStatus': '',
    'name': '',
  };


  int _currentIndex = 0;

  void _nextPage() {
    if (_currentIndex < 2) {
      setState(() => _currentIndex++);
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _submitSurvey();
    }
  }

  void _prevPage() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _pageController.previousPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  Future<void> _submitSurvey() async {
    final user = FirebaseAuth.instance.currentUser!;
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'busySlots': _answers['busySlots'],
        'customStatus': _answers['customStatus'],
        'name': _answers['name'],
      }, SetOptions(merge: true));

      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => HomeScreen()));
    } catch (e) {
      debugPrint('Error saving survey: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Error saving survey')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF10AF9C),
        title: const Text(
          'Update your setup',
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
          BusySlotPicker(onSave: (slots) => _answers['busySlots'] = slots),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_currentIndex > 0)
              ElevatedButton(onPressed: _prevPage, child: const Text('Back')),
            ElevatedButton(
              onPressed: _nextPage,
              child: Text(_currentIndex == 2 ? 'Finish' : 'Next'),
            ),
          ],
        ),
      ),
    );
  }
}

class BusySlotPicker extends StatefulWidget {
  final Function(Map<String, List<String>>) onSave;

  const BusySlotPicker({required this.onSave, Key? key}) : super(key: key);

  @override
  State<BusySlotPicker> createState() => _BusySlotPickerState();
}

class _BusySlotPickerState extends State<BusySlotPicker> {
  final List<String> weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday'
  ];
  String _selectedDay = 'Monday';
  final Map<String, List<String>> _selectedSlots = {};

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
                      widget.onSave(_selectedSlots);
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
