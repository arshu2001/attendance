import 'package:attendance/controller/login_controller.dart';
import 'package:attendance/customText.dart';
import 'package:attendance/view/login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool isAttendanceMarked = false;
  DateTime currentTime = DateTime.now();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  

   @override
  void initState() {
    super.initState();
    // Update time every second
    Stream.periodic(const Duration(seconds: 1)).listen((_) {
      setState(() {
        currentTime = DateTime.now();
      });
    });
    
    // Check if attendance is already marked for today
    checkTodayAttendance();
  }

  Future<void> checkTodayAttendance() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        
        final attendanceDoc = await _firestore
            .collection('attendance')
            .doc(user.uid)
            .collection('records')
            .doc(today)
            .get();

        setState(() {
          isAttendanceMarked = attendanceDoc.exists && 
                              attendanceDoc.data()?['entry'] != null &&
                              attendanceDoc.data()?['exit'] == null;
        });
      }
    } catch (e) {
      print('Error checking attendance: $e');
    }
  }

  Future<void> markAttendance() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final today = DateFormat('yyyy-MM-dd').format(currentTime);
      final currentTimeStr = DateFormat('HH:mm:ss').format(currentTime);
      
      // Reference to today's attendance document
      final attendanceRef = _firestore
          .collection('attendance')
          .doc(user.uid)
          .collection('records')
          .doc(today);

      if (!isAttendanceMarked) {
        // Marking entry
        await attendanceRef.set({
          'entry': currentTimeStr,
          'date': today,
          'userId': user.uid,
        });
      } else {
        // Marking exit
        await attendanceRef.update({
          'exit': currentTimeStr,
        });
      }

      setState(() {
        isAttendanceMarked = !isAttendanceMarked;
      });

      // Show appropriate alert based on time
      showTimeBasedAlert();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error marking attendance'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

   void showTimeBasedAlert() {
    final hour = currentTime.hour;
    final minute = currentTime.minute;
    
    String message;
    Color color;

    if (!isAttendanceMarked) {
      // Entry time check (9:00 AM)
      if (hour == 9 && minute == 0) {
        message = 'Attendance marked on time!';
        color = Colors.green;
      } else if (hour > 9 || (hour == 9 && minute > 0)) {
        message = 'You are late!';
        color = Colors.red;
      } else {
        message = 'You are early!';
        color = Colors.grey;
      }
    } else {
      // Exit time check (6:00 PM)
      if (hour == 18 && minute == 0) {
        message = 'Exit marked on time!';
        color = Colors.green;
      } else if (hour > 18 || (hour == 18 && minute > 0)) {
        message = 'Working overtime!';
        color = Colors.red;
      } else {
        message = 'Early departure!';
        color = Colors.grey;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void logout(){
    final _user_loginController = User_LoginController();
    _user_loginController.signOut();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF009688),
        title: const Text('A t t e n d a n c e'),centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              showDialog(context: context, builder: (context) {
                        return AlertDialog(
                          title: CustomText(text: 'LogOut', size: 20,weight: FontWeight.w600,color: Colors.black,),
                          content: CustomText(text: 'Are you sure your you want to logout?', size: 16, weight: FontWeight.normal, color: Colors.black),
                actions: [
                  TextButton(onPressed: () {
                    logout();
                    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => Login(),),(route) => false,);
                    // Navigator.push(context, MaterialPageRoute(builder: (context) => Login(),));
                    
                  }, child: CustomText(text: 'yes', size: 16, weight: FontWeight.w400, color: Colors.green)),
                  TextButton(onPressed: () {
                    Navigator.pop(context);
                  }, child: CustomText(text: 'no', size: 16, weight: FontWeight.w400, color: Colors.red))
                ]
                        );
                      },);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Current Time: ${DateFormat('HH:mm:ss').format(currentTime)}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isAttendanceMarked ? Colors.orange : Colors.blue,
                ),
                onPressed: markAttendance,
                child: Text(
                  isAttendanceMarked ? 'Mark Exit' : 'Mark Attendance',
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}