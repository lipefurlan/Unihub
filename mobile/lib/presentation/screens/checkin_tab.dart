import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_models/shared_models.dart';

import '../../domain/access_rules.dart';
import '../providers.dart';
import '../widgets/common.dart';
import 'checkin_flow.dart';

class CheckinTab extends ConsumerWidget {
  const CheckinTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final student = ref.watch(authProvider).value;
    final gymsAsync = ref.watch(gymsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Check-in')),
      body: gymsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(icon: LucideIcons.wifiOff, message: '$e'),
        data: (gyms) {
          final sorted = sortByDistance(gyms);
          final accessible = sorted.where((g) => planCoversGym(student, g)).toList();

          return ListView(
            padding: const EdgeInsets.all(UniHubSpacing.x6),
            children: [
              const Text(
                'Onde você vai treinar hoje?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: UniHubSpacing.x2),
              const Text(
                'Escolha uma academia da lista ou simule a leitura do QR code na recepção.',
                style: TextStyle(fontSize: 14, color: UniHubColors.textSecondary),
              ),
              const SizedBox(height: UniHubSpacing.x6),
              OutlinedButton.icon(
                onPressed: accessible.isEmpty
                    ? null
                    : () {
                        // Simula o QR: sorteia uma academia acessível próxima
                        final gym = accessible[Random().nextInt(accessible.length)];
                        startCheckinFlow(context, ref, gym);
                      },
                icon: const Icon(LucideIcons.qrCode, size: 18),
                label: const Text('Simular leitura de QR code'),
              ),
              const SizedBox(height: UniHubSpacing.x8),
              const SectionTitle('Academias parceiras'),
              const SizedBox(height: UniHubSpacing.x2),
              for (final (i, gym) in sorted.indexed) ...[
                if (i > 0) const Divider(),
                GymTile(
                  gym: gym,
                  covered: planCoversGym(student, gym),
                  // O backend é quem valida de fato; tier insuficiente
                  // resulta no diálogo de bloqueio com a mensagem da API
                  onTap: () => startCheckinFlow(context, ref, gym),
                  trailing: const Icon(LucideIcons.scanLine,
                      size: 18, color: UniHubColors.textSecondary),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
