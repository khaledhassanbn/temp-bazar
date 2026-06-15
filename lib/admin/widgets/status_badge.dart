import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({
    Key? key,
    required this.status,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getStatusColor(status)),
      ),
      child: Text(
        _getStatusText(status),
        style: TextStyle(
          color: _getStatusColor(status),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
      case 'approved':
      case 'resolved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'suspended':
        return Colors.blue;
      case 'banned':
      case 'rejected':
        return Colors.red;
      case 'deleted':
      case 'dismissed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'active':
        return 'نشط';
      case 'pending':
        return 'معلق';
      case 'approved':
        return 'مقبول';
      case 'rejected':
        return 'مرفوض';
      case 'suspended':
        return 'موقوف';
      case 'banned':
        return 'محظور';
      case 'deleted':
        return 'محذوف';
      case 'resolved':
        return 'تم الحل';
      case 'dismissed':
        return 'مرفوض';
      default:
        return status;
    }
  }
}
