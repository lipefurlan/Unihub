import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_models/shared_models.dart';

import '../../domain/access_rules.dart';
import '../providers.dart';
import '../widgets/common.dart';

class ExploreTab extends ConsumerStatefulWidget {
  const ExploreTab({super.key});

  @override
  ConsumerState<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends ConsumerState<ExploreTab> {
  String _search = '';
  String? _modality;

  @override
  Widget build(BuildContext context) {
    final student = ref.watch(authProvider).value;
    final gymsAsync = ref.watch(gymsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Explorar')),
      body: gymsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(icon: LucideIcons.wifiOff, message: '$e'),
        data: (gyms) {
          final modalities = gyms.expand((g) => g.modalities).toSet().toList()..sort();

          var filtered = sortByDistance(gyms);
          if (_search.isNotEmpty) {
            filtered = filtered
                .where((g) => g.name.toLowerCase().contains(_search.toLowerCase()))
                .toList();
          }
          if (_modality != null) {
            filtered = filtered.where((g) => g.modalities.contains(_modality)).toList();
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    UniHubSpacing.x6, UniHubSpacing.x2, UniHubSpacing.x6, 0),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Buscar academia',
                    prefixIcon: Icon(LucideIcons.search, size: 18),
                  ),
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
              SizedBox(
                height: 56,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: UniHubSpacing.x6, vertical: UniHubSpacing.x3),
                  scrollDirection: Axis.horizontal,
                  itemCount: modalities.length,
                  separatorBuilder: (_, _) => const SizedBox(width: UniHubSpacing.x2),
                  itemBuilder: (context, i) {
                    final m = modalities[i];
                    final selected = m == _modality;
                    return _FilterChip(
                      label: m,
                      selected: selected,
                      onTap: () => setState(() => _modality = selected ? null : m),
                    );
                  },
                ),
              ),
              const Divider(),
              Expanded(
                child: filtered.isEmpty
                    ? const EmptyState(
                        icon: LucideIcons.searchX,
                        message: 'Nenhuma academia encontrada com esses filtros.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: UniHubSpacing.x6, vertical: UniHubSpacing.x2),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const Divider(),
                        itemBuilder: (context, i) {
                          final gym = filtered[i];
                          return GymTile(
                            gym: gym,
                            covered: planCoversGym(student, gym),
                            onTap: () => context.push('/gyms/${gym.id}'),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Chip de filtro minimalista: contorno fino, laranja apenas quando ativo.
class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: UniHubRadius.brMd,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: UniHubSpacing.x4, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: UniHubRadius.brMd,
          border: Border.all(
            color: selected ? UniHubColors.accent : UniHubColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? UniHubColors.accent : UniHubColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
