import 'package:flutter/material.dart';
import '../../../../features/little_brain/presentation/widgets/little_brain_dashboard.dart';

class LittleBrainDashboardPage extends StatelessWidget {
  const LittleBrainDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧠 Little Brain Dashboard'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: const SafeArea(
          child: LittleBrainDashboard(),
        ),
      ),
    );
  }
}
