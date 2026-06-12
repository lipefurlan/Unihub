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
      theme: UniHubTheme.light(),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
