import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class StatisticsCards extends StatelessWidget {
  final List<StatCard> stats;

  const StatisticsCards({
    Key? key,
    required this.stats,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive grid layout
        int crossAxisCount = 1;
        if (constraints.maxWidth > 1200) {
          crossAxisCount = 4;
        } else if (constraints.maxWidth > 800) {
          crossAxisCount = 2;
        } else {
          crossAxisCount = 1;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: _getChildAspectRatio(constraints.maxWidth),
          ),
          itemCount: stats.length,
          itemBuilder: (context, index) {
            return _buildStatCard(stats[index]);
          },
        );
      },
    );
  }

  double _getChildAspectRatio(double width) {
    if (width > 1200) return 2.5; // Desktop: wider cards
    if (width > 800) return 2.0; // Tablet: medium cards
    return 1.8; // Mobile: taller cards
  }

  Widget _buildStatCard(StatCard stat) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            stat.primaryColor.withOpacity(0.1),
            stat.primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: stat.primaryColor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: stat.primaryColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Header with icon and title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: stat.primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: stat.primaryColor.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    stat.icon,
                    color: stat.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stat.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: stat.primaryColor.withOpacity(0.8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (stat.subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          stat.subtitle!,
                          style: TextStyle(
                            fontSize: 12,
                            color: stat.primaryColor.withOpacity(0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Main value
            Text(
              stat.value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: stat.primaryColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            // Change indicator
            if (stat.change != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    stat.change! > 0 ? Icons.trending_up : Icons.trending_down,
                    color: stat.change! > 0 ? Colors.green : Colors.red,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${stat.change! > 0 ? '+' : ''}${stat.change!.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: stat.change! > 0 ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'vs last period',
                    style: TextStyle(
                      fontSize: 12,
                      color: stat.primaryColor.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class StatCard {
  final String title;
  final String? subtitle;
  final String value;
  final IconData icon;
  final Color primaryColor;
  final double? change;

  const StatCard({
    required this.title,
    this.subtitle,
    required this.value,
    required this.icon,
    required this.primaryColor,
    this.change,
  });
}

// Predefined color schemes for different stat types
class StatColors {
  static const Color primary = AppColors.primaryColor;
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  static const Color purple = Color(0xFF8B5CF6);
  static const Color pink = Color(0xFFEC4899);
  static const Color indigo = Color(0xFF6366F1);
}
