import 'package:flutter/material.dart';

class SavedPlacesScreen extends StatelessWidget {
  const SavedPlacesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Places')),
      body: const Center(
        child: Text('Saved Places Screen'),
      ),
    );
  }
}
