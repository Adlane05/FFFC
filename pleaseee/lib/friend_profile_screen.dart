import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FriendProfilePage extends StatefulWidget {
  final String friendUid;
  final void Function(Color newColor) onColorChanged;

  const FriendProfilePage({
    Key? key,
    required this.friendUid,
    required this.onColorChanged,
  }) : super(key: key);

  @override
  State<FriendProfilePage> createState() => _FriendProfilePageState();
}

class _FriendProfilePageState extends State<FriendProfilePage> {
  Map<String, dynamic>? friendData;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadFriendData();
  }

  Future<void> _loadFriendData() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.friendUid)
        .get();

    if (doc.exists) {
      setState(() {
        friendData = doc.data();
        loading = false;
      });
    } else {
      setState(() {
        loading = false;
      });
    }
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
      final hexColor = '#${selectedColor.value.toRadixString(16).padLeft(8, '0')}';

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.friendUid)
          .update({'calendarColor': hexColor});

      widget.onColorChanged(selectedColor);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Calendar color updated')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF10AF9C),
          title: const Text(
            'Friend Profile',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontFamily: 'Jersey 25',
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (friendData == null) {
      return  Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF10AF9C),
          title: const Text(
            'Friend Profile',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontFamily: 'Jersey 25',
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        body: Center(child: Text('Friend not found.')),
      );
    }

    final name = friendData!['name'] ?? 'Friend';
    final email = friendData!['email'] ?? '';
    final photoUrl = friendData!['photoUrl'];
    final status = friendData!['customStatus'] ?? '';

    return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF10AF9C),
          title:  Text(
            name,
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontFamily: 'Jersey 25',
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        body: Center(child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (photoUrl != null)
                CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage(photoUrl),
                )
              else
                const CircleAvatar(
                  radius: 40,
                  child: Icon(Icons.person, size: 40),
                ),
              const SizedBox(height: 16),
              Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(email, style: const TextStyle(color: Colors.grey)),
              ],
              if (status.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Status: $status', style: const TextStyle(fontStyle: FontStyle.italic)),
              ],
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _changeCalendarColor,
                icon: const Icon(Icons.color_lens),
                label: const Text('Change Calendar Color'),
              ),
            ],
          ),
        ),)
    );
  }
}
