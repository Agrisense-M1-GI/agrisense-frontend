import 'package:flutter/material.dart';
import '../../app_colors.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          NotificationItem(
            title: 'Humidité critique — Zone B (48%)',
            time: 'Il y a 12 min',
            isRead: false,
            color: AppColors.red600,
          ),
          NotificationItem(
            title: 'Capteur C3 — batterie faible (18%)',
            time: 'Il y a 1h',
            isRead: false,
            color: AppColors.amber600,
          ),
          NotificationItem(
            title: 'Irrigation Zone A terminée',
            time: 'Il y a 3h',
            isRead: true,
            color: AppColors.green600,
          ),
        ],
      ),
    );
  }
}
class NotificationItem extends StatelessWidget {
  final String title;
  final String time;
  final bool isRead;
  final Color color;

  const NotificationItem({
    super.key,
    required this.title,
    required this.time,
    required this.isRead,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isRead ? AppColors.white : AppColors.green50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isRead ? Colors.transparent : AppColors.green200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isRead ? FontWeight.normal : FontWeight.w500,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),

          if (!isRead)
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.green600,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}