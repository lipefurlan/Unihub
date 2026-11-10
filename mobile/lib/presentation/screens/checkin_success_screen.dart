import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_models/shared_models.dart';

class CheckinSuccessScreen extends StatelessWidget {
  const CheckinSuccessScreen({super.key, required this.checkin});

  final CheckIn checkin;

  @override
  Widget build(BuildContext context) {
    final code = checkin.entryCode;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(UniHubSpacing.x6),
          child: Column(
            children: [
              const Spacer(),
              const Icon(LucideIcons.circleCheck, size: 36, color: UniHubColors.accent),
              const SizedBox(height: UniHubSpacing.x3),
              const Text(
                'Check-in confirmado',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: UniHubSpacing.x2),
              Text(
                '${checkin.gym.name} · ${formatTime(checkin.timestamp)}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: UniHubSpacing.x6),
              if (code != null) ...[
                QrImageView(
                  data: code,
                  size: 180,
                  eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: UniHubColors.textPrimary),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: UniHubColors.textPrimary,
                  ),
                ),
                const SizedBox(height: UniHubSpacing.x3),
                Text(
                  // "K7M 2QX": mais fácil de ditar na recepção
                  '${code.substring(0, 3)} ${code.substring(3)}',
                  style: UniHubStyles.money(size: 30, weight: FontWeight.w800),
                ),
                const SizedBox(height: UniHubSpacing.x2),
                const Text(
                  'Mostre o QR ou diga o código na recepção. Vale por 3 horas.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: UniHubColors.textSecondary),
                ),
              ] else
                const Text(
                  'Apresente esta tela na recepção. Bom treino!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: UniHubColors.textSecondary),
                ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('Voltar ao início'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
