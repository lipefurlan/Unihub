import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_models/shared_models.dart';

import '../../domain/access_rules.dart';

/// Logotipo tipográfico: "UniHub" com ponto laranja — hierarquia por
/// tipografia, sem ilustrações.
class UniHubWordmark extends StatelessWidget {
  const UniHubWordmark({super.key, this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: size,
          fontWeight: FontWeight.w800,
          color: UniHubColors.textPrimary,
          letterSpacing: -0.5,
          fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
        ),
        children: const [
          TextSpan(text: 'UniHub'),
          TextSpan(text: '.', style: TextStyle(color: UniHubColors.accent)),
        ],
      ),
    );
  }
}

/// Título de seção: tipografia forte no lugar de caixas.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.action});

  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: UniHubColors.textPrimary,
          ),
        ),
        ?action,
      ],
    );
  }
}

/// Badge de acesso da academia conforme o plano do estudante.
class AccessBadge extends StatelessWidget {
  const AccessBadge({super.key, required this.covered, required this.minTier});

  final bool covered;
  final int minTier;

  @override
  Widget build(BuildContext context) {
    return Text(
      covered ? 'Incluído no seu plano' : 'Plano $minTier ou superior',
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: covered ? UniHubColors.accent : UniHubColors.textSecondary,
      ),
    );
  }
}

/// Avatar com fallback de iniciais (sem depender da foto carregar).
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({super.key, required this.name, this.photoUrl, this.radius = 24});

  final String name;
  final String? photoUrl;
  final double radius;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: UniHubColors.surface,
      foregroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
      // Se a imagem falhar, o CircleAvatar cai no child silenciosamente
      onForegroundImageError: photoUrl != null ? (_, _) {} : null,
      child: Text(
        _initials,
        style: TextStyle(
          fontSize: radius * 0.66,
          fontWeight: FontWeight.w700,
          color: UniHubColors.textSecondary,
        ),
      ),
    );
  }
}

/// Bloco de estatística: número grande + rótulo (hierarquia tipográfica).
class StatBlock extends StatelessWidget {
  const StatBlock({super.key, required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: UniHubStyles.money(size: 28, weight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: UniHubColors.textSecondary),
        ),
      ],
    );
  }
}

/// Linha de academia usada nas listas (Explorar, Check-in, Home).
class GymTile extends StatelessWidget {
  const GymTile({
    super.key,
    required this.gym,
    required this.covered,
    this.onTap,
    this.trailing,
  });

  final Gym gym;
  final bool covered;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: UniHubSpacing.x3),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gym.name,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${gym.modalities.join(' · ')} · ${gymDistanceKm(gym).toStringAsFixed(1)} km',
                    style: const TextStyle(fontSize: 12.5, color: UniHubColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  AccessBadge(covered: covered, minTier: gym.minPlanTier),
                ],
              ),
            ),
            trailing ??
                const Icon(LucideIcons.chevronRight, size: 18, color: UniHubColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

/// Estado vazio padronizado.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(UniHubSpacing.x8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: UniHubColors.textSecondary),
            const SizedBox(height: UniHubSpacing.x3),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: UniHubColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mostra o erro de API em um SnackBar padronizado.
void showApiError(BuildContext context, Object error) {
  final message = error is ApiException ? error.message : 'Erro inesperado. Tente novamente.';
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
