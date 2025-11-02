import 'package:flutter/material.dart';
import 'package:final_task/widgets/app_background.dart';

class FeatureEditScreen extends StatelessWidget {
  final String featureName;
  const FeatureEditScreen({super.key, required this.featureName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(featureName, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.black.withOpacity(0.5),
        elevation: 0,
        centerTitle: true,
      ),
      body: AppBackground(
        child: Center(
          child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.construction, size: 96, color: Colors.white70),
              SizedBox(height: 16),
              Text(
                'This combined editor has been split into dedicated screens. Please use the Home tiles to open each feature.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}