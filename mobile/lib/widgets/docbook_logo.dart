import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class DocBookLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final Color? textColor;

  const DocBookLogo({
    super.key,
    this.size = 40,
    this.showText = true,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(size * 0.28),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Open Book shape using icon
              Icon(
                Icons.menu_book_rounded,
                color: Colors.white.withValues(alpha: 0.4),
                size: size * 0.65,
              ),
              // Stethoscope / Medical cross inside
              Icon(
                Icons.add_moderator_rounded,
                color: Colors.white,
                size: size * 0.5,
              ),
            ],
          ),
        ),
        if (showText) ...[
          SizedBox(width: size * 0.25),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: size * 0.45,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
              children: [
                TextSpan(
                  text: 'Doc',
                  style: TextStyle(color: textColor ?? AppColors.textPrimary),
                ),
                TextSpan(
                  text: 'Book',
                  style: const TextStyle(color: AppColors.primary),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
