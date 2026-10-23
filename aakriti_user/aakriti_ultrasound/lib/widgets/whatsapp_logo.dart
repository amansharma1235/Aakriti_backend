import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Pixel-perfect Authentic WhatsApp Brand Logo Widget
class WhatsAppLogo extends StatelessWidget {
  final double size;
  final Color? color;
  final bool showBackground;
  final Color backgroundColor;

  const WhatsAppLogo({
    super.key,
    this.size = 20,
    this.color,
    this.showBackground = false,
    this.backgroundColor = const Color(0xFF25D366),
  });

  @override
  Widget build(BuildContext context) {
    if (showBackground) {
      return Container(
        width: size * 1.5,
        height: size * 1.5,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: FaIcon(
            FontAwesomeIcons.whatsapp,
            color: color ?? Colors.white,
            size: size,
          ),
        ),
      );
    }

    return FaIcon(
      FontAwesomeIcons.whatsapp,
      color: color ?? const Color(0xFF25D366),
      size: size,
    );
  }
}
