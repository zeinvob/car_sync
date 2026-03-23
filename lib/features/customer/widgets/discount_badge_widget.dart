import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A discount badge widget styled similar to e-commerce apps
class DiscountBadgeWidget extends StatelessWidget {
  final int discountPercent;
  final BorderRadius? borderRadius;

  const DiscountBadgeWidget({
    super.key,
    required this.discountPercent,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    if (discountPercent <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFEE4D2D), // Shopee orange-red
        borderRadius: borderRadius ??
            const BorderRadius.only(
              topRight: Radius.circular(8),
              bottomLeft: Radius.circular(8),
            ),
      ),
      child: Text(
        '-$discountPercent%',
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
