import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// − value + control. [onChanged] null disables it. Limits are checked here
/// and again by the backend.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 1000,
    this.compact = false,
  });

  final int value;
  final int min;
  final int max;
  final bool compact;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    final iconSize = compact ? 18.0 : 20.0;
    final constraints = compact ? const BoxConstraints.tightFor(width: 36, height: 36) : null;
    return Container(
      height: compact ? 36 : 52,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(compact ? AppSizes.radius8 : AppSizes.radius12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Kurangi',
            constraints: constraints,
            padding: compact ? EdgeInsets.zero : null,
            icon: Icon(Icons.remove, size: iconSize),
            onPressed: enabled && value > min ? () => onChanged!(value - 1) : null,
          ),
          SizedBox(
            width: compact ? 28 : 24,
            child: Text('$value', style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
          ),
          IconButton(
            tooltip: 'Tambah',
            constraints: constraints,
            padding: compact ? EdgeInsets.zero : null,
            icon: Icon(Icons.add, size: iconSize),
            onPressed: enabled && value < max ? () => onChanged!(value + 1) : null,
          ),
        ],
      ),
    );
  }
}
