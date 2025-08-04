import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SimpleHomeScreen extends StatelessWidget {
  const SimpleHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal英語学習'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '🐿️',
              style: TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 16),
            Text(
              'Squirrel',
              style: AppTheme.display2,
            ),
            const SizedBox(height: 8),
            Text(
              'Journal Language Learning',
              style: AppTheme.body2,
            ),
            const SizedBox(height: 32),
            Text(
              'アプリは準備中です',
              style: AppTheme.body1,
            ),
          ],
        ),
      ),
    );
  }
}