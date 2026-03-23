import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Widget displaying order status with appropriate color coding
class OrderStatusWidget extends StatelessWidget {
  final String status;
  final bool showIcon;
  final double fontSize;

  const OrderStatusWidget({
    super.key,
    required this.status,
    this.showIcon = true,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getStatusColor().withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              _getStatusIcon(),
              size: fontSize + 2,
              color: _getStatusColor(),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            _getStatusLabel(),
            style: GoogleFonts.poppins(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: _getStatusColor(),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.access_time;
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'completed':
        return Icons.done_all;
      default:
        return Icons.info_outline;
    }
  }

  String _getStatusLabel() {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'completed':
        return 'Completed';
      default:
        return status.toUpperCase();
    }
  }
}
