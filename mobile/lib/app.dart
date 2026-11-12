import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';

import 'presentation/router.dart';

class UniHubApp extends ConsumerWidget {
  const UniHubApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'UniHub',
      debugShowCheckedModeBanner: false,
      // Transição estilo iPhone em todas as plataformas (inclusive no Safari):
      // a tela nova entra deslizando da direita e dá para voltar arrastando
      // a partir da borda esquerda.
      theme: UniHubTheme.light().copyWith(
        pageTransitionsTheme: PageTransitionsTheme(
          builders: {
            for (final platform in TargetPlatform.values)
              platform: const CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
