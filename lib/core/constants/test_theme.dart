import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Test file to verify theme colors are working correctly
class ThemeTestScreen extends StatelessWidget {
  const ThemeTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white, // This should make the background white
      appBar: AppBar(
        backgroundColor: AppColors.secondaryBackground, // Orange header
        foregroundColor: AppColors.white, // White text on orange
        title: const Text('Theme Test'),
      ),
      body: Container(
        color: AppColors.white, // Explicitly set white background
        child: Column(
          children: [
            // Creative design element using secondary background color
            Container(
              color: AppColors.secondaryBackground,
              width: double.infinity,
              height: 100,
              child: const Center(
                child: Text(
                  'Creative Header Section',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // Main content on white background
            Expanded(
              child: Container(
                color: AppColors.white,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Main Content Area',
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'This text should be on a white background. If you see any other color, the theme is not working correctly.',
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Test card
                    Card(
                      color: AppColors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'This card should have a white background',
                          style: TextStyle(
                            color: AppColors.primaryText,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
