import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
class ColorPickerDialog extends StatelessWidget {
  final Color initialColor;
  ColorPickerDialog({required this.initialColor});

  final colors = Colors.primaries;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Select Color'),
      content: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: colors.map((c) {
          return GestureDetector(
            onTap: () => Navigator.of(context).pop(c),
            child: Container(
              width: 30,
              height: 30,
              color: c,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class FriendProfilePage extends StatefulWidget {
  final String friendUid;
  const FriendProfilePage({required this.friendUid});

  @override
  State<FriendProfilePage> createState() => _FriendProfilePageState();
}

class _FriendProfilePageState extends State<FriendProfilePage> {
  late DocumentSnapshot<Map<String, dynamic>> friendSnap;
  Color? selectedColor;

  @override
  void initState() {
    super.initState();
    _loadFriend();
  }

  void _loadFriend() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(widget.friendUid).get();
    setState(() {
      friendSnap = doc;
      selectedColor = Colors.blue; // Default or pull from settings
    });
  }

  @override
  Widget build(BuildContext context) {
    if (friendSnap == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final data = friendSnap.data()!;
    return Scaffold(
      appBar: AppBar(title: Text(data['name'] ?? 'Friend'), backgroundColor: Colors.teal),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(data['photoUrl'] ?? ''),
              radius: 40,
            ),
            SizedBox(height: 12),
            Text(data['email'] ?? '', style: TextStyle(fontSize: 16)),
            SizedBox(height: 12),
            Text('Status: ${data['status'] ?? 'No status'}'),
            SizedBox(height: 20),
            Row(
              children: [
                Text('Calendar Color:'),
                SizedBox(width: 10),
                GestureDetector(
                  onTap: () async {
                    final color = await showDialog<Color>(
                      context: context,
                      builder: (_) => ColorPickerDialog(initialColor: selectedColor!),
                    );
                    if (color != null) {
                      setState(() => selectedColor = color);
                      // Save locally or persist in Firestore if needed
                    }
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    color: selectedColor,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
