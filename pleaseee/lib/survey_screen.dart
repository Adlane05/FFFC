// survey_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'home_screen.dart';

final List<Map<String, dynamic>> surveyQuestions = [
  {'field': 'busySlots', 'type': 'time-slots'},
  {'field': 'customStatus', 'type': 'text', 'title': 'What status would you like your friends to see?'},
];

class SurveyScreen extends StatefulWidget {
  const SurveyScreen({Key? key}) : super(key: key);

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  final PageController _pageController = PageController();
  final Map<String, dynamic> _answers = {
    'busySlots': <String, List<String>>{},
    'customStatus': '',
  };

  int _currentIndex = 0;

  void _nextPage() {
    if (_currentIndex < surveyQuestions.length - 1) {
      setState(() => _currentIndex++);
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _submitSurvey();
    }
  }

  void _prevPage() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  Future<void> _submitSurvey() async {
    final user = FirebaseAuth.instance.currentUser!;
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'busySlots': _answers['busySlots'],
        'customStatus': _answers['customStatus'],
        'usageType': _answers['usageType'],
      }, SetOptions(merge: true));

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()));
    } catch (e) {
      print('Error saving survey: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error saving survey')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Setup'),
        backgroundColor: Colors.teal,
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          BusySlotPicker(onSave: (busySlots) => _answers['busySlots'] = busySlots),
          CustomStatusPage(onChanged: (value) => _answers['customStatus'] = value),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_currentIndex > 0)
              ElevatedButton(
                onPressed: _prevPage,
                child: const Text('Back'),
              ),
            ElevatedButton(
              onPressed: _nextPage,
              child: Text(_currentIndex == surveyQuestions.length - 1 ? 'Finish' : 'Next'),
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
  final List<String> weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
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
          const Text('Select your busy time slots', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedDay,
            items: weekdays.map((day) => DropdownMenuItem(value: day, child: Text(day))).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedDay = value);
              }
            },
            decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Day'),
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
                      border: Border.all(color: isSelected ? Colors.teal : Colors.grey),
                    ),
                    child: Text(slot, style: TextStyle(color: isSelected ? Colors.white : Colors.black)),
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

class CustomStatusPage extends StatelessWidget {
  final Function(String) onChanged;

  const CustomStatusPage({required this.onChanged, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('Create a custom status for when you\'re free:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

