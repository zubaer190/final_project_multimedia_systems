import 'package:flutter/material.dart';
import 'package:webrtc/pages/webrtc/call_screen.dart';

Future<void> myMain() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() {
    return _MyAppState();
  }
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.purple),
      home: AppContent(),
    );
  }
}

class AppContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => onAfterBuild(context));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CallScreen(
        ip: '192.168.31.45',
      ),
    );
  }

  void onAfterBuild(BuildContext context) {}
}
