import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_models/shared_models.dart';

import '../providers.dart';

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
      body: ListView(
        padding: const EdgeInsets.all(UniHubSpacing.x6),
        children: [
          const SizedBox(height: UniHubSpacing.x6),
          AspectRatio(
            aspectRatio: 1.586, // proporção de cartão
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: UniHubRadius.brLg,
                boxShadow: [
                  BoxShadow(
                    color: UniHubColors.accent.withValues(alpha: 0.30),
                    blurRadius: 32,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: UniHubRadius.brLg,
                child: ColoredBox(
                  color: UniHubColors.accent,
                  child: Stack(
                    children: [
                      const Positioned.fill(child: PaperGrain(opacity: 0.07)),
                      // Cortina encostada na lateral direita, longe do logo
                      const Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: HalfMoonCurtain(radius: 11, onOrange: true, vertical: true),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                            UniHubSpacing.x5, UniHubSpacing.x5, UniHubSpacing.x10, UniHubSpacing.x5),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const UniHubLogo(height: 20, onOrange: true),
                                BrandLabel(plan?.name ?? 'Sem plano',
                                    color: Colors.white, size: 10),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              student.name,
                              style: UniHubFonts.display(
                                  fontSize: 21, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                            Text(
                              student.university,
                              style: UniHubFonts.text(
                                  fontSize: 13, color: Colors.white.withValues(alpha: 0.86)),
                            ),
                            const SizedBox(height: UniHubSpacing.x4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    BrandLabel('Matrícula UniHub',
                                        color: Colors.white.withValues(alpha: 0.86), size: 9),
                                    Text(
                                      memberId,
                                      style: UniHubStyles.money(
                                          size: 16, weight: FontWeight.w800, color: Colors.white),
                                    ),
                                  ],
                                ),
                                _CardQr(data: memberId),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: UniHubSpacing.x8),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: student.subscription?.status == 'active'
                      ? UniHubColors.success
                      : UniHubColors.textTertiary,
                ),
              ),
              const SizedBox(width: UniHubSpacing.x2),
              Text(
                student.subscription?.status == 'active'
                    ? 'Plano ativo'
                    : student.subscription?.status == 'paused'
                        ? 'Plano pausado'
                        : 'Sem plano ativo',
                style: UniHubFonts.text(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: UniHubSpacing.x1),
          Text(
            'A recepção escaneia o QR para conferir sua matrícula na hora.',
            style: UniHubFonts.text(fontSize: 13, color: UniHubColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// QR da matrícula num quadrado branco, para a recepção escanear na hora
/// (módulos escuros sobre branco: leitores não leem QR invertido).
class _CardQr extends StatelessWidget {
  const _CardQr({required this.data});

  final String data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: UniHubRadius.brMd,
      ),
      child: QrImageView(
        data: data,
        size: 62,
        padding: EdgeInsets.zero,
        backgroundColor: Colors.white,
        eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: UniHubColors.textPrimary),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: UniHubColors.textPrimary,
        ),
      ),
    );
  }
}
