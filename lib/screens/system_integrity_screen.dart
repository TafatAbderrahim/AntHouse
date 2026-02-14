import 'package:flutter/material.dart';
import '../models/admin_data.dart';

class SystemIntegrityScreen extends StatelessWidget {
  const SystemIntegrityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('System Integrity',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark)),
        const SizedBox(height: 16),
        _statusCard('Database', 'Healthy', Icons.storage_rounded,
            AppColors.success),
        const SizedBox(height: 10),
        _statusCard('API Gateway', 'Online', Icons.cloud_done_rounded,
            AppColors.success),
        const SizedBox(height: 10),
        _statusCard('AI Engine', 'Running', Icons.psychology_rounded,
            AppColors.aiBlue),
        const SizedBox(height: 10),
        _statusCard('Backup', 'Last: 2h ago', Icons.backup_rounded,
            AppColors.primary),
        const SizedBox(height: 10),
        _statusCard('SSL Certificate', 'Valid (342 days)',
            Icons.verified_user_rounded, AppColors.success),
        const SizedBox(height: 10),
        _statusCard('Disk Usage', '67% used', Icons.disc_full_rounded,
            const Color(0xFFFF9800)),
      ],
    );
  }

  Widget _statusCard(
      String label, String status, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14)),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(status,
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
