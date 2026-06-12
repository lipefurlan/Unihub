import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_models/shared_models.dart';

class CheckinSuccessScreen extends StatelessWidget {
  const CheckinSuccessScreen({super.key, required this.checkin});

  final CheckIn checkin;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(UniHubSpacing.x6),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: UniHubColors.accent, width: 2),
                ),
                child: const Icon(LucideIcons.check, size: 40, color: UniHubColors.accent),
              ),
              const SizedBox(height: UniHubSpacing.x8),
              const Text(
                'Check-in confirmado',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: UniHubSpacing.x3),
              Text(
                checkin.gym.name,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Text(
                formatDateTime(checkin.timestamp),
                style: const TextStyle(fontSize: 14, color: UniHubColors.textSecondary),
              ),
              const SizedBox(height: UniHubSpacing.x2),
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
