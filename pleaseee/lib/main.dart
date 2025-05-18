import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sign_button/sign_button.dart';
import 'home_screen.dart';
import 'survey_screen.dart';
import 'auth_service.dart';
import 'splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyBAsHJtOasLD94KQ3se7FlkcTEyTHWQpSc",
      appId: "773072036609",
      messagingSenderId: "773072036609",
      projectId: "friendship-freedom-chart",
    ),
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FFFC',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        canvasColor: Colors.white,
        scaffoldBackgroundColor: Colors.white,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.teal,
            textStyle: TextStyle(fontSize: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LandingPage extends StatefulWidget {
  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  bool _loading = false;

  Future<void> _handleSignIn() async {
    setState(() => _loading = true);

    try {
      final user = await AuthService().signInWithGoogle();

      if (user != null) {
        final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
        final docSnapshot = await userRef.get();

        if (docSnapshot.exists) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
        } else {
          await userRef.set({
            'uid': user.uid,
            'name': user.displayName,
            'email': user.email,
            'photoUrl': user.photoURL,
            'createdAt': FieldValue.serverTimestamp(),
          });

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => SurveyScreen()),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google Sign-In failed or was canceled')),
        );
      }
    } catch (e, stackTrace) {
      print("Error during sign-in: $e");
      print("Stack trace: $stackTrace");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Something went wrong during sign-in')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return
      Container(
      decoration: BoxDecoration(
        color: Colors.white
      ),
        child: Stack(
        children: [
          Positioned.fill(
              child: Align(
                alignment: Alignment.topCenter,
                child: Transform.scale(
                  scaleX: 1,
                  scaleY: 1,
                  child: Container(
                    margin: EdgeInsets.only(top: 80),
                    decoration: BoxDecoration(
                      image: DecorationImage(image: AssetImage("assets/newgraphic.png"), fit: BoxFit.fitWidth),
                    ),
                  )
                ),
              )
        ),
      Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: const Color(0xFF10AF9C),
          title: const Text(
            'FFFC',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontFamily: 'Jersey 25',
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Container(
            width: MediaQuery.sizeOf(context).width,
            height: MediaQuery.sizeOf(context).height,
            decoration: const BoxDecoration(
              color: Colors.transparent,
            ),
            child: Stack(
              children: [
                const Positioned(
                  left: 60,
                  top: 30,
                  child: SizedBox(
                    width: 346,
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'THE ',
                            style: TextStyle(
                              color: Color(0xFF10AF9C),
                              fontSize: 50,
                              fontFamily: 'Jersey 25',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          TextSpan(
                            text: 'F',
                            style: TextStyle(
                              color: Color(0xFFFFD017),
                              fontSize: 50,
                              fontFamily: 'Jersey 25',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          TextSpan(
                            text: 'RIENDSHIP\n',
                            style: TextStyle(
                              color: Color(0xFF10AF9C),
                              fontSize: 50,
                              fontFamily: 'Jersey 25',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          TextSpan(
                            text: '          F',
                            style: TextStyle(
                              color: Color(0xFFFFD017),
                              fontSize: 50,
                              fontFamily: 'Jersey 25',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          TextSpan(
                            text: 'REEDOM\n',
                            style: TextStyle(
                              color: Color(0xFF10AF9C),
                              fontSize: 50,
                              fontFamily: 'Jersey 25',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          TextSpan(
                            text: '              F',
                            style: TextStyle(
                              color: Color(0xFFFFD017),
                              fontSize: 50,
                              fontFamily: 'Jersey 25',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          TextSpan(
                            text: 'INDER\n',
                            style: TextStyle(
                              color: Color(0xFF10AF9C),
                              fontSize: 50,
                              fontFamily: 'Jersey 25',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          TextSpan(
                            text: '               C',
                            style: TextStyle(
                              color: Color(0xFFFFD017),
                              fontSize: 50,
                              fontFamily: 'Jersey 25',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          TextSpan(
                            text: 'HART',
                            style: TextStyle(
                              color: Color(0xFF10AF9C),
                              fontSize: 50,
                              fontFamily: 'Jersey 25',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: 500),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        alignment: Alignment.center,
                        child: _loading
                            ? CircularProgressIndicator()
                            : SignInButton(
                          buttonType: ButtonType.google,
                          onPressed: _handleSignIn,
                        ),
                      ),
                    ],
                  )
                ),
              ],
            ),
          ),
        ),
      ),
      ]
        )
    );
  }
}

