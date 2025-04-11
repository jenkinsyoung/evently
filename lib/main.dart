import 'package:flutter/material.dart';
import 'package:evently/app/app_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ytitnwyszqopaqcuemat.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl0aXRud3lzenFvcGFxY3VlbWF0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDM4NTA4NzMsImV4cCI6MjA1OTQyNjg3M30.VIPmNeWWOsrk7ezDginy14bVMwOQduKM3wOPUan1YsM',


  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      theme: ThemeData(
        primaryColor: const Color(0xFF872341),
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF872341)),
        fontFamily: 'Montserrat',
      ),
      onGenerateRoute: AppRouter.generateRoute,
      initialRoute: '/',
      debugShowCheckedModeBanner: false,
    );
  }
}