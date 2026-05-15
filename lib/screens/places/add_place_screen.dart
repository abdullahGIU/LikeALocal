import 'package:flutter/material.dart';

class AddPlaceScreen extends StatelessWidget {
  const AddPlaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Place')),
      body: const Center(
        child: Text('Add Place Screen'),
      ),
    );
  }
}
