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
  String? _city;
  bool _onlyFavorites = false;

  @override
  Widget build(BuildContext context) {
    final student = ref.watch(authProvider).value;
    final gymsAsync = ref.watch(gymsProvider);
    final location = ref.watch(userLocationProvider).value ?? UserLocation.current;
    final favoriteIds = {...?ref.watch(favoritesProvider).value?.map((g) => g.id)};
    final homeCity = student?.homeCity;

    return Scaffold(
      appBar: AppBar(title: const Text('Explorar')),
      body: gymsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(icon: LucideIcons.wifiOff, message: '$e'),
        data: (gyms) {
          final modalities = gyms.expand((g) => g.modalities).toSet().toList()..sort();
          // Cidade natal primeiro: o aluno acha academia quando vai para casa
          final cities = gyms.map((g) => g.city).where((c) => c.isNotEmpty).toSet().toList()
            ..sort((a, b) => a == homeCity ? -1 : (b == homeCity ? 1 : a.compareTo(b)));

          var filtered = sortByDistance(gyms);
          if (_search.isNotEmpty) {
            filtered = filtered
                .where((g) => g.name.toLowerCase().contains(_search.toLowerCase()))
                .toList();
          }
          if (_modality != null) {
            filtered = filtered.where((g) => g.modalities.contains(_modality)).toList();
          }
          if (_city != null) {
            filtered = filtered.where((g) => g.city == _city).toList();
          }
          if (_onlyFavorites) {
            filtered = filtered.where((g) => favoriteIds.contains(g.id)).toList();
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
                height: 48,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                      UniHubSpacing.x6, UniHubSpacing.x3, UniHubSpacing.x6, 0),
                  scrollDirection: Axis.horizontal,
                  children: [
                    _FilterChip(
                      label: 'Favoritas',
                      icon: LucideIcons.heart,
                      selected: _onlyFavorites,
                      onTap: () => setState(() => _onlyFavorites = !_onlyFavorites),
                    ),
                    for (final city in cities) ...[
                      const SizedBox(width: UniHubSpacing.x2),
                      _FilterChip(
                        label: city,
                        icon: city == homeCity ? LucideIcons.house : LucideIcons.mapPin,
                        selected: _city == city,
                        onTap: () => setState(() => _city = _city == city ? null : city),
                      ),
                    ],
                  ],
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
              Padding(
                padding: const EdgeInsets.fromLTRB(UniHubSpacing.x6, 0, UniHubSpacing.x6, UniHubSpacing.x2),
                child: Row(
                  children: [
                    Icon(
                      location.isReal ? LucideIcons.locateFixed : LucideIcons.school,
                      size: 14,
                      color: UniHubColors.textSecondary,
                    ),
                    const SizedBox(width: UniHubSpacing.x2),
                    Expanded(
                      child: Text(
                        location.isReal
                            ? 'Distâncias a partir de onde você está'
                            : 'Distâncias a partir do campus (localização não liberada)',
                        style: const TextStyle(fontSize: 12, color: UniHubColors.textSecondary),
                      ),
                    ),
                  ],
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
  const _FilterChip({required this.label, required this.selected, required this.onTap, this.icon});

  final String label;
  final IconData? icon;
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: selected ? UniHubColors.accent : UniHubColors.textSecondary),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? UniHubColors.accent : UniHubColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
