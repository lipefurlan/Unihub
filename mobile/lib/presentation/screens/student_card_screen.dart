import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';

import '../providers.dart';
import '../widgets/common.dart';

/// Carteirinha digital do estudante UniHub.
class StudentCardScreen extends ConsumerWidget {
  const StudentCardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final student = ref.watch(authProvider).value;
    if (student == null) return const SizedBox.shrink();

    final plan = student.subscription?.plan;
    final memberId = 'UH-${student.id.toString().padLeft(6, '0')}';

    return Scaffold(
      appBar: AppBar(title: const Text('Carteirinha digital')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(UniHubSpacing.x6),
          child: AspectRatio(
            aspectRatio: 1.586, // proporção de cartão
            child: Container(
              decoration: BoxDecoration(
                color: UniHubColors.background,
                borderRadius: UniHubRadius.brMd,
                border: Border.all(color: UniHubColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filete laranja no topo: o acento usado com intenção
                  Container(
                    height: 4,
                    decoration: const BoxDecoration(
                      color: UniHubColors.accent,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(UniHubRadius.md)),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(UniHubSpacing.x5),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const UniHubWordmark(size: 18),
                              Text(
                                plan?.name.toUpperCase() ?? 'SEM PLANO',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                  color: UniHubColors.accent,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            student.name,
                            style:
                                const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                          Text(
                            student.university,
                            style: const TextStyle(
                                fontSize: 13, color: UniHubColors.textSecondary),
                          ),
                          const SizedBox(height: UniHubSpacing.x4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'MATRÍCULA UNIHUB',
                                    style: TextStyle(
                                      fontSize: 9,
                                      letterSpacing: 1.2,
                                      fontWeight: FontWeight.w600,
                                      color: UniHubColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    memberId,
                                    style: UniHubStyles.money(size: 15),
                                  ),
                                ],
                              ),
                              const _FauxBarcode(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Código de barras decorativo (o POC não integra catraca real).
class _FauxBarcode extends StatelessWidget {
  const _FauxBarcode();

  @override
  Widget build(BuildContext context) {
    const widths = [2.0, 1.0, 3.0, 1.0, 2.0, 1.0, 1.0, 3.0, 2.0, 1.0, 2.0, 3.0, 1.0, 2.0, 1.0, 3.0];
    return Row(
      children: [
        for (final w in widths)
          Container(
            width: w,
            height: 32,
            margin: const EdgeInsets.only(right: 1.5),
            color: UniHubColors.textPrimary,
          ),
      ],
    );
  }
}
