// survey_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'home_screen.dart';

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
    if (_currentIndex < 2) {
      setState(() => _currentIndex++);
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      // Last page: Finish survey
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
      // Save survey answers
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'busySlots': _answers['busySlots'],
        'customStatus': _answers['customStatus'],
      }, SetOptions(merge: true));

      // Now route home
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
          'Complete your setup',
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
          CustomStatusPage(onChanged: (v) => _answers['customStatus'] = v),
          AddFriendPage(), // NEW!
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

class AddFriendPage extends StatefulWidget {
  @override
  State<AddFriendPage> createState() => _AddFriendPageState();
}

class _AddFriendPageState extends State<AddFriendPage> {
  final _emailCtrl = TextEditingController();
  String? _feedback;
  bool _loading = false;

  Future<void> _addFriendByEmail() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _feedback = 'Please enter an email.');
      return;
    }

    setState(() {
      _loading = true;
      _feedback = null;
    });

    try {
      // Look up the user by email
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        setState(() => _feedback = 'No user found with that email.');
      } else {
        final friendDoc = query.docs.first;
        final friendUid = friendDoc.id;
        final currentUser = FirebaseAuth.instance.currentUser!;
        final currentUid = currentUser.uid;

        if (friendUid == currentUid) {
          setState(() => _feedback = 'You can’t add yourself as a friend.');
        } else {
          final userRef = FirebaseFirestore.instance.collection('users').doc(currentUid);
          final friendRef = FirebaseFirestore.instance.collection('users').doc(friendUid);

          // Run updates in a batch
          final batch = FirebaseFirestore.instance.batch();

          // Add friend to current user's list
          batch.update(userRef, {
            'friends': FieldValue.arrayUnion([friendUid])
          });

          // Add current user to friend's list
          batch.update(friendRef, {
            'friends': FieldValue.arrayUnion([currentUid])
          });

          await batch.commit();

          setState(() {
            _feedback = 'Friend added!';
            _emailCtrl.clear();
          });
        }
      }
    } catch (e) {
      setState(() => _feedback = 'Error adding friend.');
      debugPrint('Error adding friend: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('Add a friend by email',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            controller: _emailCtrl,
            decoration: const InputDecoration(
              labelText: 'Friend\'s email',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          _loading
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: _addFriendByEmail,
                  child: const Text('Add Friend')),
          if (_feedback != null) ...[
            const SizedBox(height: 12),
            Text(_feedback!, style: const TextStyle(color: Colors.red)),
          ],
          const Spacer(),
          const Text(
            'You can add more friends, then tap Finish above.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
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

class CustomStatusPage extends StatelessWidget {
  final Function(String) onChanged;

  const CustomStatusPage({required this.onChanged, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('Create a custom status for when you\'re free:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(
                labelText: 'Status', border: OutlineInputBorder()),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
