import 'package:flutter/material.dart';
import 'screens/upload_screen.dart';

void main() {
  runApp(const BloodLinkApp());
}

class BloodLinkApp extends StatelessWidget {
  const BloodLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BloodLink',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.redAccent),
        useMaterial3: true,
      ),
      home: const UploadScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
