import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Mostra as abas da navegação inferior lado a lado, para o aluno trocar de
/// aba arrastando o dedo para o lado. Cada aba guarda o próprio estado
/// (rolagem, filtros) enquanto o aluno passeia pelas outras.
class SwipeableTabs extends StatefulWidget {
  const SwipeableTabs({super.key, required this.shell, required this.children});

  final StatefulNavigationShell shell;
  final List<Widget> children;

  @override
  State<SwipeableTabs> createState() => _SwipeableTabsState();
}

class _SwipeableTabsState extends State<SwipeableTabs> {
  late final PageController _controller =
      PageController(initialPage: widget.shell.currentIndex);

  /// true enquanto a página anda sozinha (toque na barra de baixo), para não
  /// trocar de aba nas páginas intermediárias do caminho.
  bool _animating = false;

  @override
  void didUpdateWidget(covariant SwipeableTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    final target = widget.shell.currentIndex;
    if (!_controller.hasClients) return;
    final current = _controller.page?.round() ?? target;
    if (current == target) return;
    _animating = true;
    _controller
        .animateToPage(
          target,
          duration: Duration(milliseconds: 220 + 60 * (current - target).abs()),
          curve: Curves.easeOutCubic,
        )
        .whenComplete(() => _animating = false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _controller,
      onPageChanged: (index) {
        if (_animating || index == widget.shell.currentIndex) return;
        widget.shell.goBranch(index);
      },
      children: [for (final child in widget.children) _KeepAlive(child: child)],
    );
  }
}

class _KeepAlive extends StatefulWidget {
  const _KeepAlive({required this.child});

  final Widget child;

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
