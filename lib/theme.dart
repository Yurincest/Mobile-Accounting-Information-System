import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF0891B2); // cyan-600
  static const Color primaryDark = Color(0xFF0E7490); // cyan-700
  static const Color primaryLight = Color(0xFF22D3EE); // cyan-400

  static const Color background = Color(0xFFF8FAFC); // slate-50
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFE2E8F0); // slate-200

  static const Color textPrimary = Color(0xFF1E293B); // slate-800
  static const Color textSecondary = Color(0xFF64748B); // slate-500
  static const Color textMuted = Color(0xFF475569); // slate-600

  static const Color success = Color(0xFF10B981); // emerald-500
  static const Color warning = Color(0xFFF59E0B); // amber-500
  static const Color danger = Color(0xFFF43F5E); // rose-500
  static const Color info = Color(0xFF0EA5E9); // sky-500
}

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.warning,
      onSecondary: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      background: AppColors.background,
      onBackground: AppColors.textPrimary,
      error: AppColors.danger,
      onError: Colors.white,
    ),
    useMaterial3: true,
    fontFamily: 'Inter',
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.textPrimary,
      elevation: 0.5,
      shadowColor: Color(0x11000000),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      headlineMedium: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      bodyLarge: TextStyle(fontWeight: FontWeight.w500, color: AppColors.textPrimary),
      bodyMedium: TextStyle(color: AppColors.textSecondary),
      labelLarge: TextStyle(fontWeight: FontWeight.w600),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      hintStyle: const TextStyle(color: AppColors.textSecondary),
      labelStyle: const TextStyle(color: AppColors.textMuted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      margin: const EdgeInsets.all(8),
    ),
    // Dialog global styling: lebih lapang, rounded, warna lembut
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFFEFF4F9),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
    ),
    // ExpansionTile global: border halus & padding konsisten
    expansionTileTheme: ExpansionTileThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.textMuted.withOpacity(0.15), width: 0.5),
      ),
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.textMuted.withOpacity(0.15), width: 0.5),
      ),
      childrenPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      textColor: AppColors.textPrimary,
      collapsedTextColor: AppColors.textPrimary,
      iconColor: AppColors.textSecondary,
      collapsedIconColor: AppColors.textSecondary,
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.textPrimary,
      contentTextStyle: TextStyle(color: Colors.white),
    ),
    dataTableTheme: const DataTableThemeData(
      headingRowColor: WidgetStatePropertyAll(Color(0xFFF1F5F9)),
      dataRowMinHeight: 44,
      dataRowMaxHeight: 60,
      headingTextStyle: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textMuted),
      dataTextStyle: TextStyle(color: AppColors.textPrimary),
      dividerThickness: 1,
    ),
  );
}

class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const CustomCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
    return Container(
      margin: margin,
      child: onTap != null ? InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: content) : content,
    );
  }
}

enum ButtonVariant { filled, outline, light, danger, success }

class CustomButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final bool fullWidth;
  final IconData? icon;

  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = ButtonVariant.filled,
    this.fullWidth = false,
    this.icon,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool _hovering = false;
  bool _pressed = false;

  Color _baseBg() => switch (widget.variant) {
        ButtonVariant.filled => AppColors.primary,
        ButtonVariant.danger => AppColors.danger,
        ButtonVariant.success => AppColors.success,
        ButtonVariant.light => const Color(0xFFF1F5F9),
        ButtonVariant.outline => Colors.transparent,
      };

  Color _fg() => switch (widget.variant) {
        ButtonVariant.filled => Colors.white,
        ButtonVariant.danger => Colors.white,
        ButtonVariant.success => Colors.white,
        ButtonVariant.light => AppColors.textPrimary,
        ButtonVariant.outline => AppColors.primary,
      };

  BorderSide _border() => switch (widget.variant) {
        ButtonVariant.outline => const BorderSide(color: AppColors.primaryLight, width: 2),
        _ => const BorderSide(color: Colors.transparent, width: 0),
      };

  Color _interactiveBg() {
    final base = _baseBg();
    if (widget.variant == ButtonVariant.outline) {
      return _hovering ? const Color(0xFFEFF6FF) : Colors.transparent;
    }
    // Slight lighten on hover, darken on press
    HSLColor hsl = HSLColor.fromColor(base);
    if (_pressed) {
      hsl = hsl.withLightness((hsl.lightness - 0.06).clamp(0.0, 1.0));
    } else if (_hovering) {
      hsl = hsl.withLightness((hsl.lightness + 0.06).clamp(0.0, 1.0));
    }
    return hsl.toColor();
  }

  @override
  Widget build(BuildContext context) {
    final fg = _fg();
    return SizedBox(
      width: widget.fullWidth ? double.infinity : null,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() {
          _hovering = false;
          _pressed = false;
        }),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _interactiveBg(),
              borderRadius: BorderRadius.circular(12),
              border: Border.fromBorderSide(_border()),
              boxShadow: _hovering && widget.variant != ButtonVariant.outline
                  ? const [BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 4))]
                  : const [],
            ),
            child: Row(
              mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: fg),
                  const SizedBox(width: 8),
                ],
                Text(widget.label, style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? prefixIcon;
  final void Function(String)? onChanged;

  const CustomTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon,
      ),
    );
  }
}

class CustomTable extends StatelessWidget {
  final List<DataColumn> columns;
  final List<DataRow> rows;

  const CustomTable({super.key, required this.columns, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DataTable(columns: columns, rows: rows),
    );
  }
}