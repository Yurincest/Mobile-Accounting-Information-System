import 'package:flutter/material.dart';
import 'package:sia_mobile_soosvaldo/theme.dart';

class MembershipBadge extends StatelessWidget {
  final String name;
  final int percent; // diskon membership, dibatasi maksimal 15%
  final bool compact; // ukuran kecil untuk ditempatkan di baris

  const MembershipBadge({
    super.key,
    required this.name,
    required this.percent,
    this.compact = true,
  });

  Color _colorFor(int p) {
    final capped = p.clamp(0, 15);
    if (capped >= 15) return const Color(0xFFE53935); // merah (limit)
    if (capped >= 10) return const Color(0xFFFFC107); // emas/amber
    if (capped >= 5) return AppColors.success; // hijau
    return AppColors.textSecondary; // default muted
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(percent);
    final bg = color.withOpacity(0.12);
    final border = color.withOpacity(0.40);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, size: compact ? 16 : 18, color: color),
          const SizedBox(width: 6),
          Text(
            name,
            style: TextStyle(
              fontSize: compact ? 12 : 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}