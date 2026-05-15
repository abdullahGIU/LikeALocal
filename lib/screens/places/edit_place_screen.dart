import 'package:flutter/material.dart';

class EditPlaceScreen extends StatelessWidget {
  const EditPlaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Place')),
      body: const Center(
        child: Text('Edit Place Screen'),
      ),
    );
  }
}
