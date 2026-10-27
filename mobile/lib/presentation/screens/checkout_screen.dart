import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_models/shared_models.dart';

import '../providers.dart';
import '../widgets/common.dart';

/// Checkout simulado da assinatura: PIX ou cartão, sem cobrança real.
/// Na versão de produção, esta tela chama o gateway (ex.: Asaas) e a
/// assinatura só é criada quando o pagamento é confirmado.
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key, required this.plan});

  final Plan plan;

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

enum _Method { pix, card }

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  _Method _method = _Method.pix;
  bool _processing = false;
  final _formKey = GlobalKey<FormState>();
  // Payload de mentira, só para o QR ter cara de PIX
  final _pixCode =
      '00020126UNIHUB-DEMO-${Random().nextInt(899999) + 100000}5204000053039865802BR6009CAMPINAS';

  Future<void> _pay() async {
    if (_method == _Method.card && !_formKey.currentState!.validate()) return;
    setState(() => _processing = true);
    // Simula o tempo de confirmação do gateway
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    try {
      await ref.read(apiClientProvider).createSubscription(widget.plan.id);
      await ref.read(authProvider.notifier).refreshProfile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pagamento aprovado. Bem-vindo ao ${widget.plan.name}!')),
      );
      context.go('/home');
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final student = ref.watch(authProvider).value;
    final plan = widget.plan;
    final price = student?.priceFor(plan) ?? plan.monthlyPrice;
    final subsidy = student?.universitySubsidy ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Pagamento')),
      body: ListView(
        padding: const EdgeInsets.all(UniHubSpacing.x6),
        children: [
          Text(plan.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: UniHubSpacing.x4),
          _Line('Mensalidade', formatBRL(plan.monthlyPrice)),
          if (subsidy > 0) _Line('Subsídio da ${student!.university}', '− ${formatBRL(subsidy)}'),
          const Divider(),
          _Line('Total por mês', formatBRL(price), bold: true),
          const SizedBox(height: UniHubSpacing.x2),
          const Text(
            'Renovação automática a cada 30 dias. Você pode pausar nas férias ou cancelar quando quiser.',
            style: TextStyle(fontSize: 12.5, color: UniHubColors.textSecondary),
          ),
          const SizedBox(height: UniHubSpacing.x8),
          SegmentedButton<_Method>(
            segments: const [
              ButtonSegment(value: _Method.pix, label: Text('PIX'), icon: Icon(LucideIcons.qrCode, size: 16)),
              ButtonSegment(value: _Method.card, label: Text('Cartão'), icon: Icon(LucideIcons.creditCard, size: 16)),
            ],
            selected: {_method},
            onSelectionChanged: _processing ? null : (s) => setState(() => _method = s.first),
          ),
          const SizedBox(height: UniHubSpacing.x6),
          if (_method == _Method.pix) _pixSection() else _cardSection(),
          const SizedBox(height: UniHubSpacing.x8),
          FilledButton(
            onPressed: _processing ? null : _pay,
            child: _processing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(_method == _Method.pix ? 'Já paguei o PIX' : 'Pagar ${formatBRL(price)}'),
          ),
          const SizedBox(height: UniHubSpacing.x3),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.flaskConical, size: 13, color: UniHubColors.textSecondary),
              SizedBox(width: 6),
              Text(
                'Demonstração: nenhuma cobrança real é feita',
                style: TextStyle(fontSize: 12, color: UniHubColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pixSection() {
    return Column(
      children: [
        QrImageView(data: _pixCode, size: 170),
        const SizedBox(height: UniHubSpacing.x3),
        OutlinedButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: _pixCode));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Código PIX copiado.')),
            );
          },
          icon: const Icon(LucideIcons.copy, size: 16),
          label: const Text('Copiar PIX copia e cola'),
        ),
      ],
    );
  }

  Widget _cardSection() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            decoration: const InputDecoration(labelText: 'Número do cartão', hintText: '4111 1111 1111 1111'),
            keyboardType: TextInputType.number,
            validator: (v) => (v ?? '').replaceAll(' ', '').length < 13 ? 'Número inválido' : null,
          ),
          const SizedBox(height: UniHubSpacing.x3),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Nome impresso no cartão'),
            validator: (v) => (v ?? '').trim().isEmpty ? 'Informe o nome' : null,
          ),
          const SizedBox(height: UniHubSpacing.x3),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(labelText: 'Validade', hintText: 'MM/AA'),
                  validator: (v) =>
                      RegExp(r'^\d{2}/\d{2}$').hasMatch(v ?? '') ? null : 'Use MM/AA',
                ),
              ),
              const SizedBox(width: UniHubSpacing.x3),
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(labelText: 'CVV'),
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  validator: (v) => (v ?? '').length < 3 ? 'CVV inválido' : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value, {this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final weight = bold ? FontWeight.w800 : FontWeight.w500;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: UniHubSpacing.x2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: 14, fontWeight: weight))),
          Text(value, style: UniHubStyles.money(size: bold ? 16 : 14, weight: weight)),
        ],
      ),
    );
  }
}
