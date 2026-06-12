import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_models/shared_models.dart';

/// Casca com a navegação inferior das 4 abas.
class ShellScreen extends StatelessWidget {
  const ShellScreen({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: UniHubColors.divider, width: 1)),
        ),
        child: NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: (index) =>
              shell.goBranch(index, initialLocation: index == shell.currentIndex),
          destinations: const [
            NavigationDestination(icon: Icon(LucideIcons.home), label: 'Início'),
            NavigationDestination(icon: Icon(LucideIcons.search), label: 'Explorar'),
            NavigationDestination(icon: Icon(LucideIcons.scanLine), label: 'Check-in'),
            NavigationDestination(icon: Icon(LucideIcons.user), label: 'Perfil'),
          ],
        ),
      ),
    );
  }
}
