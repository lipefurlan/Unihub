import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_models/shared_models.dart';

import '../../data/panel_auth_repository.dart';
import '../providers.dart';
import '../widgets/common.dart';

/// Casca do painel: navegação lateral fixa no desktop, drawer no celular.
/// O menu muda conforme o role: academia ou operação UniHub.
class ShellScreen extends ConsumerWidget {
  const ShellScreen({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  static const _gymItems = [
    (path: '/dashboard', icon: LucideIcons.layoutDashboard, label: 'Dashboard'),
    (path: '/entrada', icon: LucideIcons.qrCode, label: 'Validar entrada'),
    (path: '/students', icon: LucideIcons.users, label: 'Alunos'),
    (path: '/finance', icon: LucideIcons.receipt, label: 'Financeiro'),
    (path: '/settings', icon: LucideIcons.settings, label: 'Configurações'),
  ];

  static const _adminItems = [
    (
      path: '/admin/overview',
      icon: LucideIcons.layoutDashboard,
      label: 'Visão geral',
    ),
    (path: '/admin/gyms', icon: LucideIcons.dumbbell, label: 'Academias'),
    (path: '/admin/planos', icon: LucideIcons.tags, label: 'Planos'),
    (path: '/admin/payouts', icon: LucideIcons.receipt, label: 'Repasses'),
    (path: '/admin/students', icon: LucideIcons.users, label: 'Estudantes'),
    (path: '/admin/desafios', icon: LucideIcons.trophy, label: 'Desafios'),
  ];

  static const _universityItems = [
    (path: '/ies/overview', icon: LucideIcons.layoutDashboard, label: 'Visão geral'),
    (path: '/ies/students', icon: LucideIcons.graduationCap, label: 'Alunos'),
  ];

  static _SidebarPalette _palette(PanelSession? session) => session?.isAdmin == true
      ? _SidebarPalette.operation
      : (session?.isUniversity == true ? _SidebarPalette.university : _SidebarPalette.gym);

  static String? _suffix(PanelSession? session) =>
      session?.isAdmin == true ? 'operação' : (session?.isUniversity == true ? 'faculdade' : null);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider).value;
    final items = session?.isAdmin == true
        ? _adminItems
        : (session?.isUniversity == true ? _universityItems : _gymItems);

    final palette = _palette(session);
    final sidebar = _SidebarContent(
      palette: palette,
      session: session,
      items: items,
      location: location,
      onNavigate: (path) {
        // No drawer (celular), fecha antes de navegar
        if (isMobile(context)) Navigator.of(context).pop();
        context.go(path);
      },
      onLogout: () {
        if (isMobile(context)) Navigator.of(context).pop();
        ref.read(sessionProvider.notifier).logout();
      },
    );

    if (isMobile(context)) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: palette.background,
          foregroundColor: palette.text,
          title: UniHubWordmark(
            size: 18,
            suffix: ShellScreen._suffix(session),
            onDark: palette.dark,
          ),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(),
          ),
        ),
        drawer: Drawer(
          backgroundColor: palette.background,
          child: sidebar,
        ),
        body: child,
      );
    }

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 240,
            decoration: BoxDecoration(
              color: palette.background,
              border: Border(
                right: BorderSide(color: palette.border, width: 1),
              ),
            ),
            child: sidebar,
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Conteúdo da navegação, reusado pela coluna fixa (desktop) e pelo drawer (celular).
class _SidebarContent extends StatelessWidget {
  const _SidebarContent({
    required this.palette,
    required this.session,
    required this.items,
    required this.location,
    required this.onNavigate,
    required this.onLogout,
  });

  final _SidebarPalette palette;
  final PanelSession? session;
  final List<({String path, IconData icon, String label})> items;
  final String location;
  final void Function(String path) onNavigate;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              UniHubSpacing.x6,
              UniHubSpacing.x6,
              UniHubSpacing.x6,
              UniHubSpacing.x2,
            ),
            child: UniHubWordmark(
              size: 20,
              suffix: ShellScreen._suffix(session),
              onDark: palette.dark,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: UniHubSpacing.x6),
            child: Text(
              session?.displayName ?? '',
              style: TextStyle(fontSize: 13, color: palette.muted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: UniHubSpacing.x6),
          for (final item in items)
            _NavItem(
              palette: palette,
              icon: item.icon,
              label: item.label,
              // Subpáginas (ex.: detalhe do desafio) mantêm o item aceso
              selected: location == item.path || location.startsWith('${item.path}/'),
              onTap: () => onNavigate(item.path),
            ),
          const Spacer(),
          Divider(color: palette.border),
          _NavItem(
            palette: palette,
            icon: LucideIcons.logOut,
            label: 'Sair',
            selected: false,
            onTap: onLogout,
          ),
          const SizedBox(height: UniHubSpacing.x4),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.palette,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final _SidebarPalette palette;
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Semantics: expõe o item como botão para leitores de tela/automação
    return Semantics(
      button: true,
      label: label,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: UniHubSpacing.x6,
            vertical: UniHubSpacing.x3,
          ),
          child: Row(
            children: [
              // Marcador fino laranja para o item ativo — acento com intenção
              Container(
                width: 3,
                height: 18,
                margin: const EdgeInsets.only(right: UniHubSpacing.x3),
                color: selected ? UniHubColors.accent : Colors.transparent,
              ),
              Icon(
                icon,
                size: 18,
                color: selected ? UniHubColors.accent : palette.muted,
              ),
              const SizedBox(width: UniHubSpacing.x3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? palette.text : palette.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cores do menu lateral por área, para cada painel ter cara própria:
/// academia em branco, faculdade em papel e operação UniHub em preto café.
class _SidebarPalette {
  const _SidebarPalette({
    required this.background,
    required this.border,
    required this.text,
    required this.muted,
    this.dark = false,
  });

  final Color background;
  final Color border;
  final Color text;
  final Color muted;
  final bool dark;

  static const gym = _SidebarPalette(
    background: UniHubColors.background,
    border: UniHubColors.divider,
    text: UniHubColors.textPrimary,
    muted: UniHubColors.textSecondary,
  );

  static const university = _SidebarPalette(
    background: UniHubColors.surface,
    border: UniHubColors.divider,
    text: UniHubColors.textPrimary,
    muted: UniHubColors.textSecondary,
  );

  static const operation = _SidebarPalette(
    background: UniHubColors.textPrimary,
    border: Color(0x1FFFFFFF),
    text: Colors.white,
    muted: Color(0xB3FFFFFF),
    dark: true,
  );
}
