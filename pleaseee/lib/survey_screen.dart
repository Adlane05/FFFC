import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'home_screen.dart'; // Replace with your actual HomePage file

class SurveyScreen extends StatefulWidget {
  const SurveyScreen({Key? key}) : super(key: key);

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _answers = {};

  // You can easily expand or modify this list later
  final List<Map<String, dynamic>> surveyQuestions = [
    {
      'field': 'freeTimeSlots',
      'title': 'When are you usually free?',
      'type': 'multi-select',
      'options': [
        'Mon AM', 'Mon PM', 'Tue AM', 'Tue PM',
        'Wed AM', 'Wed PM', 'Thu AM', 'Thu PM',
        'Fri AM', 'Fri PM', 'Weekend'
      ],
    },
    {
      'field': 'customStatus',
      'title': 'What status would you like your friends to see?',
      'type': 'text',
    },
    {
      'field': 'usageType',
      'title': 'How do you plan to use this app?',
      'type': 'dropdown',
      'options': [
        'stalking my friends',
        'Group planning',
        'time management',
        'love and happiness',
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    for (var question in surveyQuestions) {
      _answers[question['field']] =
      question['type'] == 'multi-select' ? <String>[] : '';
    }
  }

  Future<void> _submitSurvey() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'fullName': user.displayName ?? '',
          'email': user.email ?? '',
          ..._answers,
        }, SetOptions(merge: true));

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } catch (e) {
        print("Error saving survey: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error saving survey")),
        );
      }
    }
  }

  Widget _buildQuestion(Map<String, dynamic> question) {
    final field = question['field'];
    final title = question['title'];
    final type = question['type'];

    switch (type) {
      case 'text':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: TextFormField(
            decoration: InputDecoration(labelText: title),
            onChanged: (val) => _answers[field] = val,
          ),
        );

      case 'dropdown':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(labelText: title),
            items: (question['options'] as List<String>)
                .map((String opt) => DropdownMenuItem<String>(
              value: opt,
              child: Text(opt),
            ))
                .toList(),
            onChanged: (val) => _answers[field] = val,
          ),
        );

      case 'multi-select':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ...question['options'].map<Widget>((opt) {
              final selected = (_answers[field] as List<String>).contains(opt);
              return CheckboxListTile(
                title: Text(opt),
                value: selected,
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      (_answers[field] as List<String>).add(opt);
                    } else {
                      (_answers[field] as List<String>).remove(opt);
                    }
                  });
                },
              );
            }).toList(),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Survey'),
        backgroundColor: Colors.teal,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ...surveyQuestions.map(_buildQuestion).toList(),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitSurvey,
              child: const Text('Submit'),
            )
          ],
        ),
      ),
    );
  }
}