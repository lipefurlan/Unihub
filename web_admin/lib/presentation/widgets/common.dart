import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

/// Logotipo tipográfico do painel.
class UniHubWordmark extends StatelessWidget {
  const UniHubWordmark({super.key, this.size = 20, this.suffix});

  final double size;
  final String? suffix;

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
        children: [
          const TextSpan(text: 'UniHub'),
          const TextSpan(
            text: '.',
            style: TextStyle(color: UniHubColors.accent),
          ),
          if (suffix != null)
            TextSpan(
              text: '  $suffix',
              style: TextStyle(
                fontSize: size * 0.65,
                fontWeight: FontWeight.w500,
                color: UniHubColors.textSecondary,
                letterSpacing: 0,
              ),
            ),
        ],
      ),
    );
  }
}

/// Título de página do painel.
class PageTitle extends StatelessWidget {
  const PageTitle(this.text, {super.key, this.subtitle, this.action});

  final String text;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: UniHubColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        ?action,
      ],
    );
  }
}

/// Métrica do dashboard: número grande, rótulo discreto e variação.
class MetricBlock extends StatelessWidget {
  const MetricBlock({
    super.key,
    required this.label,
    required this.value,
    this.detail,
    this.highlight = false,
  });

  final String label;
  final String value;
  final String? detail;

  /// Destaque em laranja: reservado ao que importa (ex.: valor a receber).
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: UniHubColors.textSecondary,
          ),
        ),
        const SizedBox(height: UniHubSpacing.x2),
        Text(
          value,
          style: UniHubStyles.money(
            size: 26,
            weight: FontWeight.w800,
            color: highlight ? UniHubColors.accent : UniHubColors.textPrimary,
          ),
        ),
        if (detail != null) ...[
          const SizedBox(height: 2),
          Text(
            detail!,
            style: const TextStyle(
              fontSize: 12.5,
              color: UniHubColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

/// Selo de status de repasse (pendente/pago).
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.paid});

  final bool paid;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: UniHubSpacing.x2,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        borderRadius: UniHubRadius.brSm,
        border: Border.all(
          color: paid ? UniHubColors.success : UniHubColors.border,
        ),
      ),
      child: Text(
        paid ? 'Pago' : 'Pendente',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: paid ? UniHubColors.success : UniHubColors.textSecondary,
        ),
      ),
    );
  }
}

/// Breakpoint único do painel: abaixo disso, layout de celular.
bool isMobile(BuildContext context) => MediaQuery.sizeOf(context).width < 760;

/// Padding de página: generoso no desktop, compacto no celular.
EdgeInsets pagePadding(BuildContext context) =>
    EdgeInsets.all(isMobile(context) ? UniHubSpacing.x4 : UniHubSpacing.x8);

/// Linha de métricas: lado a lado no desktop, grade 2 colunas no celular.
class MetricRow extends StatelessWidget {
  const MetricRow({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (!isMobile(context)) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [for (final c in children) Expanded(child: c)],
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - UniHubSpacing.x4) / 2;
        return Wrap(
          spacing: UniHubSpacing.x4,
          runSpacing: UniHubSpacing.x5,
          children: [
            for (final c in children) SizedBox(width: itemWidth, child: c),
          ],
        );
      },
    );
  }
}

/// Tabela larga com rolagem horizontal no celular (sem cortar colunas).
class ResponsiveTable extends StatelessWidget {
  const ResponsiveTable({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: child,
        ),
      ),
    );
  }
}

/// Dropdown de filtro minimalista usado nas tabelas (null = todos).
class FilterDropdown extends StatelessWidget {
  const FilterDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.allLabel = 'Todas',
  });

  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;
  final String allLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: UniHubSpacing.x3),
      decoration: BoxDecoration(
        borderRadius: UniHubRadius.brMd,
        border: Border.all(
          color: value != null ? UniHubColors.accent : UniHubColors.border,
          width: value != null ? 1.5 : 1,
        ),
      ),
      child: DropdownButton<String?>(
        value: value,
        hint: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: UniHubColors.textSecondary,
          ),
        ),
        underline: const SizedBox.shrink(),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: UniHubColors.textPrimary,
        ),
        items: [
          DropdownMenuItem<String?>(
            value: null,
            child: Text('$label: $allLabel'),
          ),
          for (final option in options)
            DropdownMenuItem<String?>(value: option, child: Text(option)),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

/// Mostra erro de API em SnackBar.
void showApiError(BuildContext context, Object error) {
  final message = error is ApiException
      ? error.message
      : 'Erro inesperado. Tente novamente.';
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
