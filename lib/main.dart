import 'package:flutter/material.dart';
import 'package:resume_checker/widget/modern_ui.dart';
// import 'package:resume_checker/pdf_screen.dart';


void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

 @override
 Widget build(BuildContext context) {
   return MaterialApp(
     debugShowCheckedModeBanner: false,
     title: 'Resume Skills Analyzer',
     theme: ThemeData(primarySwatch: Colors.blue),
     home: const PDFReaderHome(),
   );
 }
}


