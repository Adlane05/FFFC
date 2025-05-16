import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _emailCtrl = TextEditingController();
  String? _feedback;
  bool _loading = false;
  List<DocumentSnapshot> _friends = [];

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    final currentUser = FirebaseAuth.instance.currentUser!;
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
    final friendIds = List<String>.from(userDoc.data()?['friends'] ?? []);

    if (friendIds.isEmpty) return;

    final friendsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where(FieldPath.documentId, whereIn: friendIds)
        .get();

    setState(() => _friends = friendsSnapshot.docs);
  }

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
          setState(() => _feedback = 'You can’t add yourself.');
        } else {
          final batch = FirebaseFirestore.instance.batch();

          batch.update(
            FirebaseFirestore.instance.collection('users').doc(currentUid),
            {'friends': FieldValue.arrayUnion([friendUid])},
          );

          batch.update(
            FirebaseFirestore.instance.collection('users').doc(friendUid),
            {'friends': FieldValue.arrayUnion([currentUid])},
          );

          await batch.commit();

          setState(() {
            _feedback = 'Friend added!';
            _emailCtrl.clear();
          });

          await _loadFriends();
        }
      }
    } catch (e) {
      setState(() => _feedback = 'Error adding friend.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _removeFriend(String friendUid) async {
    final currentUid = FirebaseAuth.instance.currentUser!.uid;

    final batch = FirebaseFirestore.instance.batch();

    batch.update(
      FirebaseFirestore.instance.collection('users').doc(currentUid),
      {'friends': FieldValue.arrayRemove([friendUid])},
    );

    batch.update(
      FirebaseFirestore.instance.collection('users').doc(friendUid),
      {'friends': FieldValue.arrayRemove([currentUid])},
    );

    await batch.commit();
    await _loadFriends();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF10AF9C),
        title: const Text(
          'Your Friends',
          style: TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontFamily: 'Jersey 25',
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(
                labelText: 'Add friend by email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _addFriendByEmail,
              child: const Text('Add Friend'),
            ),
            if (_feedback != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_feedback!, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 16),
            const Divider(),
            const Text('Your Friends:', style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: _friends.length,
                itemBuilder: (context, index) {
                  final friend = _friends[index];
                  return ListTile(
                    title: Text(friend['name'] ?? 'Unnamed'),
                    subtitle: Text(friend['email'] ?? ''),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () => _removeFriend(friend.id),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
