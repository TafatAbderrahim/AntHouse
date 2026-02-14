import 'package:flutter/material.dart';
import '../models/admin_data.dart';

class AiValidationScreen extends StatelessWidget {
  const AiValidationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final decisions = MockDataGenerator.generateAiDecisions();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: decisions.length + 1,
      itemBuilder: (ctx, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text('AI Validation',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark)),
          );
        }
        final d = decisions[i - 1];
        final statusColor = d.status == 'approved'
            ? AppColors.success
            : d.status == 'overridden'
                ? AppColors.accent
                : AppColors.aiBlue;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.psychology_rounded,
                    color: statusColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.description,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text('${d.action} • ${(d.confidence * 100).toStringAsFixed(0)}% confidence',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textMid)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(d.status,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );
      },
    );
  }
}
