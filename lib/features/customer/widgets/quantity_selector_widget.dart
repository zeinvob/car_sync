import 'package:car_sync/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Quantity selector widget with increment/decrement buttons
class QuantitySelectorWidget extends StatelessWidget {
  final int quantity;
  final int maxQuantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final double iconSize;

  const QuantitySelectorWidget({
    super.key,
    required this.quantity,
    required this.maxQuantity,
    required this.onIncrement,
    required this.onDecrement,
    this.iconSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    final canIncrement = quantity < maxQuantity;
    final canDecrement = quantity > 1;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildButton(
          icon: Icons.remove,
          onTap: canDecrement ? onDecrement : null,
          isLeft: true,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            '$quantity',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        _buildButton(
          icon: Icons.add,
          onTap: canIncrement ? onIncrement : null,
          isLeft: false,
        ),
      ],
    );
  }

  Widget _buildButton({
    required IconData icon,
    VoidCallback? onTap,
    required bool isLeft,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(iconSize * 0.375),
        decoration: BoxDecoration(
          color: onTap != null ? AppColors.primary : Colors.grey.shade300,
          borderRadius: isLeft
              ? BorderRadius.only(
                  topLeft: Radius.circular(iconSize * 0.375),
                  bottomLeft: Radius.circular(iconSize * 0.375),
                )
              : BorderRadius.only(
                  topRight: Radius.circular(iconSize * 0.375),
                  bottomRight: Radius.circular(iconSize * 0.375),
                ),
        ),
        child: Icon(
          icon,
          size: iconSize,
          color: onTap != null ? Colors.white : Colors.grey.shade500,
        ),
      ),
    );
  }
}
