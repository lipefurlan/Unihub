import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';

import '../providers.dart';
import 'common.dart';

/// "Como foi o treino?": o aluno dá de 1 a 5 estrelas para a visita.
Future<void> showRatingSheet(BuildContext context, WidgetRef ref, CheckIn checkin) async {
  final stars = await showModalBottomSheet<int>(
    context: context,
    backgroundColor: UniHubColors.background,
    builder: (sheetContext) => _RatingSheet(checkin: checkin),
  );
  if (stars == null) return;
  try {
    await ref.read(apiClientProvider).rateCheckin(checkin.id, stars);
    ref.invalidate(myCheckinsProvider);
    ref.invalidate(achievementsProvider);
    ref.invalidate(gymsProvider);
    ref.invalidate(gymDetailProvider(checkin.gym.id));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Valeu! Sua nota ajuda outros alunos a escolher.')),
      );
    }
  } catch (e) {
    if (context.mounted) showApiError(context, e);
  }
}

class _RatingSheet extends StatefulWidget {
  const _RatingSheet({required this.checkin});

  final CheckIn checkin;

  @override
  State<_RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends State<_RatingSheet> {
  late int _stars = widget.checkin.rating ?? 0;

  static const _labels = ['', 'Ruim', 'Fraco', 'Ok', 'Bom', 'Excelente'];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(UniHubSpacing.x6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Como foi o treino?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: UniHubSpacing.x2),
            Text(
              '${widget.checkin.gym.name} · ${formatDate(widget.checkin.timestamp)}',
              style: const TextStyle(fontSize: 14, color: UniHubColors.textSecondary),
            ),
            const SizedBox(height: UniHubSpacing.x6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 1; i <= 5; i++)
                  IconButton(
                    iconSize: 40,
                    onPressed: () => setState(() => _stars = i),
                    icon: Icon(
                      i <= _stars ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: i <= _stars ? UniHubColors.accent : UniHubColors.border,
                    ),
                  ),
              ],
            ),
            SizedBox(
              height: 22,
              child: Text(
                _labels[_stars],
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: UniHubSpacing.x6),
            FilledButton(
              onPressed: _stars == 0 ? null : () => Navigator.of(context).pop(_stars),
              child: const Text('Enviar avaliação'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Estrelas pequenas (somente leitura) para o histórico.
class StarsRow extends StatelessWidget {
  const StarsRow({super.key, required this.stars});

  final int stars;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            i <= stars ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 15,
            color: i <= stars ? UniHubColors.accent : UniHubColors.border,
          ),
      ],
    );
  }
}
