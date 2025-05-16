import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _statusCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();
  String? _profileImageUrl;
  bool _loading = true;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }
  Future<void> _changeCalendarColor() async {
    final selectedColor = await showDialog<Color>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Pick a calendar color'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: Colors.primaries.map((color) {
            return GestureDetector(
              onTap: () => Navigator.of(context).pop(color),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black12),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );

    if (selectedColor != null) {
      final user = FirebaseAuth.instance.currentUser!;
      final hexColor = '#${selectedColor.value.toRadixString(16).padLeft(8, '0')}';

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'calendarColor': hexColor}, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Calendar color updated')),
      );
    }
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser!;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data() ?? {};
    _nameCtrl.text = data['name'] ?? '';
    _statusCtrl.text = data['customStatus'] ?? '';
    _profileImageUrl = data['photoUrl'];
    setState(() => _loading = false);
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser!;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'name': _nameCtrl.text.trim(),
      'customStatus': _statusCtrl.text.trim(),
      'photoUrl': _profileImageUrl,
    }, SetOptions(merge: true));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated')),
    );
  }

  Future<void> _pickImageFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (picked != null) {
      setState(() => _uploading = true);
      try {
        final uid = FirebaseAuth.instance.currentUser!.uid;
        final ref = FirebaseStorage.instance.ref().child('profile_pictures/$uid.jpg');
        await ref.putFile(File(picked.path));
        final url = await ref.getDownloadURL();
        setState(() => _profileImageUrl = url);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      } finally {
        setState(() => _uploading = false);
      }
    }
  }

  void _setImageFromUrl() {
    final url = _imageUrlCtrl.text.trim();
    if (url.isNotEmpty) {
      setState(() => _profileImageUrl = url);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF10AF9C),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontFamily: 'Jersey 25',
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_profileImageUrl != null)
              CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(_profileImageUrl!),
              )
            else
               CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage(_profileImageUrl!),
                ),

            const SizedBox(height: 8),
            _uploading
                ? const CircularProgressIndicator()
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _pickImageFromGallery,
                  icon: const Icon(Icons.photo),
                  label: const Text('Gallery'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _showUrlDialog(context),
                  icon: const Icon(Icons.link),
                  label: const Text('Use Link'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _statusCtrl,
              decoration: const InputDecoration(labelText: 'Status'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _changeCalendarColor,
              icon: const Icon(Icons.color_lens),
              label: const Text('Change Calendar Color'),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _saveProfile,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showUrlDialog(BuildContext context) {
    _imageUrlCtrl.text = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Image URL'),
        content: TextField(
          controller: _imageUrlCtrl,
          decoration: const InputDecoration(hintText: 'https://example.com/image.jpg'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _setImageFromUrl();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
