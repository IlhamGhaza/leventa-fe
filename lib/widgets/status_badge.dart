import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    String label = status;
    Color bg = Colors.grey.shade100;
    Color text = Colors.grey.shade600;
    Color border = Colors.grey.shade200;

    switch (status) {
      case 'available':
      case 'won':
        label = status == 'available' ? 'Tersedia' : 'Deal Won';
        bg = Colors.green.shade50;
        text = Colors.green.shade700;
        border = Colors.green.shade200;
        break;
      case 'sold':
        label = 'Terjual';
        bg = Colors.grey.shade100;
        text = Colors.grey.shade600;
        border = Colors.grey.shade200;
        break;
      case 'rented':
      case 'new':
        label = status == 'new' ? 'Baru' : 'Disewa';
        bg = Colors.blue.shade50;
        text = Colors.blue.shade700;
        border = Colors.blue.shade200;
        break;
      case 'maintenance':
      case 'survey':
        label = status == 'survey' ? 'Survey' : 'Maintenance';
        bg = Colors.amber.shade50;
        text = Colors.amber.shade700;
        border = Colors.amber.shade200;
        break;
      case 'contacted':
        label = 'Dihubungi';
        bg = Colors.purple.shade50;
        text = Colors.purple.shade700;
        border = Colors.purple.shade200;
        break;
      case 'qualified':
        label = 'Qualified';
        bg = Colors.cyan.shade50;
        text = Colors.cyan.shade700;
        border = Colors.cyan.shade200;
        break;
      case 'negotiation':
        label = 'Negosiasi';
        bg = Colors.orange.shade50;
        text = Colors.orange.shade700;
        border = Colors.orange.shade200;
        break;
      case 'lost':
        label = 'Gagal';
        bg = Colors.red.shade50;
        text = Colors.red.shade700;
        border = Colors.red.shade200;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
