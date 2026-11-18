import 'package:flutter/material.dart';

export 'notice.dart';

import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

String rupiah(num value) => NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
).format(value);

class BrandBadge extends StatelessWidget {
  const BrandBadge({super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.matteCharcoal,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: AppColors.darkSecondary, width: 1.2),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppColors.electricLime,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        RichText(
          text: const TextSpan(
            text: 'Kurir',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
              fontFamily: 'Inter',
              letterSpacing: -0.3,
            ),
            children: [
              TextSpan(
                text: 'GO',
                style: TextStyle(
                  color: AppColors.electricLime,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class ActionPill extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  const ActionPill(
    this.label, {
    required this.onPressed,
    this.icon = Icons.arrow_forward_rounded,
    super.key,
  });
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(label, textAlign: TextAlign.center),
      ),
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
        textStyle: AppTypography.buttonCta,
        disabledBackgroundColor: AppColors.borderLight,
        disabledForegroundColor: const Color(0xFF475569),
        backgroundColor: AppColors.electricLime,
        foregroundColor: AppColors.matteCharcoal,
      ),
    ),
  );
}

class Panel extends StatelessWidget {
  final Widget child;
  const Panel({required this.child, super.key});
  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.darkSecondary,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: AppColors.darkBorder),
    ),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: SizedBox(width: double.infinity, child: child),
    ),
  );
}

class CourierPage extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final Widget? action;
  const CourierPage({
    required this.title,
    required this.children,
    this.action,
    super.key,
  });
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: BrandBadge(key: ValueKey(title)),
        ),
      ],
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              ...children.expand((w) => [w, const SizedBox(height: 18)]),
            ],
          ),
        ),
      ),
    ),
    bottomNavigationBar: action == null
        ? null
        : SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: action!,
          ),
  );
}

void showProblem(BuildContext context, Object error) =>
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error is ArgumentError ? '${error.message}' : '$error'),
      ),
    );

void replaceWith(BuildContext context, String route) =>
    Navigator.of(context).pushNamedAndRemoveUntil(route, (_) => false);
