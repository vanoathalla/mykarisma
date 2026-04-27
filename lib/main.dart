import 'package:flutter/material.dart';
import 'views/home_view.dart'; // Ubah import-nya ke home_view

void main() {
  runApp(
    const MaterialApp(
      home: HomeView(), // Langsung tembak ke HomeView
      debugShowCheckedModeBanner: false,
    ),
  );
}
