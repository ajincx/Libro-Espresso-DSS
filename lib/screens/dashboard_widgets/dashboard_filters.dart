import 'package:flutter/material.dart';

class DashboardFilters extends StatelessWidget {
  final String selectedBranch;
  final String selectedMonth;
  final Function(String) onBranchChanged;
  final Function(String) onMonthChanged;

  const DashboardFilters({
    super.key,
    required this.selectedBranch,
    required this.selectedMonth,
    required this.onBranchChanged,
    required this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: [
          _buildDropdown(
            value: selectedBranch,
            items: ['All Branches', 'Main Branch', 'Lipa Branch', 'Tagaytay Branch', 'Vermosa Branch', 'Evo Branch'],
            onChanged: (v) => onBranchChanged(v!),
          ),
          const SizedBox(width: 12),
          _buildDropdown(
            value: selectedMonth,
            items: ['All Months', 'January', 'February', 'March', 'April', 'May', 'June', 'July'],
            onChanged: (v) => onMonthChanged(v!),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({required String value, required List<String> items, required Function(String?) onChanged}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: items.contains(value) ? value : items.first,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF6A1028)),
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Color(0xFF1F2937))),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}
