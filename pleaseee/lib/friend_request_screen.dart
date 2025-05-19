import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendRequestScreen extends StatefulWidget {
  const FriendRequestScreen({super.key});

  @override
  State<FriendRequestScreen> createState() => _FriendRequestScreenState();
}

class _FriendRequestScreenState extends State<FriendRequestScreen> {
  final user = FirebaseAuth.instance.currentUser!;
  List<Map<String, dynamic>> users = [];

  @override
  void initState() {
    super.initState();
    initUsers();
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
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getUsersFromUid(List<String> uids) async {
    List<Map<String, dynamic>> users = [];

    for (String uid in uids) {
      try {
        DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection(
            'users').doc(uid).get();

        if (snapshot.exists) {
          final data = snapshot.data() as Map<String, dynamic>;
          // data['uid'] = uid;
          users.add(data);
        }
      } catch (e) {
        print(e);
      }
    }

    return users;
  }

  void initUsers() async {
    List<String> friendRequestUIDs = await getFriendRequests();
    List<Map<String, dynamic>> friendRequestUsers = await getUsersFromUid(friendRequestUIDs);
    setState(() {
      users = friendRequestUsers;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF10AF9C),
        title: const Text(
          'Friend Requests',
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
            Expanded(
              child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final friend = users[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(friend['photoUrl']),
                    ),
                    title: Text(friend['name'] ?? 'Unnamed'),
                    subtitle: Text(friend['email'] ?? ''),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                            onPressed: () {}, icon: Icon(Icons.add_circle, color: Colors.green,),
                        ),
                        IconButton(
                            onPressed: () {}, icon: Icon(Icons.remove_circle, color: Colors.red,)
                        )
                      ],
                    )
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
