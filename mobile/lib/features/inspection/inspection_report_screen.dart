import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_background.dart';
import '../../core/widgets/status_badge.dart';
import 'inspection_model.dart';
import 'inspection_repository.dart';

class InspectionReportScreen extends StatefulWidget {
  const InspectionReportScreen({super.key, required this.inspectionId});

  final String inspectionId;

  @override
  State<InspectionReportScreen> createState() => _InspectionReportScreenState();
}

class _InspectionReportScreenState extends State<InspectionReportScreen> {
  late Future<InspectionReport> _reportFuture;

  @override
  void initState() {
    super.initState();
    _reportFuture = context.read<InspectionRepository>().fetchReport(widget.inspectionId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inspection Report')),
      body: GradientBackground(
        child: SafeArea(
          child: FutureBuilder<InspectionReport>(
            future: _reportFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData) {
                return const Center(child: Text('Report being generated — check back shortly.'));
              }
              final report = snapshot.data!;
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  GlassCard(
                    glow: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => AppColors.goldGradient.createShader(bounds),
                              child: Text('${report.overallScore}/10',
                                  style: Theme.of(context).textTheme.displayLarge?.copyWith(color: Colors.white)),
                            ),
                            const SizedBox(width: 12),
                            StatusBadge(status: report.overallStatus, label: report.overallStatus.toUpperCase()),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(Icons.smart_toy_outlined, color: AppColors.goldLight),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text('AI Recommendation: ${report.recommendationLabel}',
                                  style: Theme.of(context).textTheme.titleLarge),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(report.aiSummary, style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 12),
                        Text(report.disclaimer, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Category scores', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 14),
                        ...report.categoryScores.entries.map(
                          (e) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Expanded(child: Text(e.key[0].toUpperCase() + e.key.substring(1), style: Theme.of(context).textTheme.bodyMedium)),
                                Text('${e.value}/10', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: GlassCard(
                          child: Column(
                            children: [
                              Text('${report.criticalDefectCount}', style: Theme.of(context).textTheme.headlineMedium),
                              const SizedBox(height: 4),
                              Text('Critical defects', style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GlassCard(
                          child: Column(
                            children: [
                              Text('AED ${report.estimatedRepairCost.toStringAsFixed(0)}',
                                  style: Theme.of(context).textTheme.headlineMedium),
                              const SizedBox(height: 4),
                              Text('Estimated repair cost', style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
