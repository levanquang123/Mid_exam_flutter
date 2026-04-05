import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:mid_exam_flutter/app.dart';
import 'package:mid_exam_flutter/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const AdminApp());
}
