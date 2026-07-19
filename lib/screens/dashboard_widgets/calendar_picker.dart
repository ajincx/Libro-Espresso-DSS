import 'package:flutter/material.dart';
import 'dart:ui';

class CalendarPicker extends StatelessWidget {
  final String selectedMonth;
  final String selectedDay;
  final Function(String) onDaySelected;
  final VoidCallback onClear;

  const CalendarPicker({
    super.key,
    required this.selectedMonth,
    required this.selectedDay,
    required this.onDaySelected,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    int year = DateTime.now().year;
    int mIndex = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'].indexOf(selectedMonth) + 1;
    if (mIndex == 0) mIndex = 7;
    
    int daysInMonth = DateTime(year, mIndex + 1, 0).day;
    DateTime firstDay = DateTime(year, mIndex, 1);
    int firstWeekday = firstDay.weekday; 
    int startingOffset = (firstWeekday == 7) ? 0 : firstWeekday;

    return Stack(
      children: [
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(color: Colors.black.withValues(alpha: 0.3)),
        ),
        Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 340,
              decoration: BoxDecoration(
                color: const Color(0xFFFDF8F5),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 8)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: const BoxDecoration(
                      color: Color(0xFF6A1028),
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(Icons.chevron_left, color: Colors.white70),
                        Text(
                          '$selectedMonth $year',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.white70),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) {
                        return SizedBox(
                          width: 32,
                          child: Center(
                            child: Text(
                              day,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                color: Color(0xFF6B7280),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                      ),
                      itemCount: startingOffset + daysInMonth,
                      itemBuilder: (context, index) {
                        if (index < startingOffset) {
                          return const SizedBox.shrink();
                        }
                        int dayNum = index - startingOffset + 1;
                        bool isSelected = selectedDay == dayNum.toString();
                        bool isToday = (mIndex == DateTime.now().month && year == DateTime.now().year && dayNum == DateTime.now().day);

                        return InkWell(
                          onTap: () {
                            onDaySelected(dayNum.toString());
                            Navigator.of(context).pop();
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected ? Colors.white : Colors.transparent,
                              border: isSelected 
                                ? Border.all(color: const Color(0xFF6A1028), width: 1.5) 
                                : (isToday ? Border.all(color: const Color(0xFF6A1028).withValues(alpha: 0.3), width: 1.5) : null),
                            ),
                            child: Center(
                              child: Text(
                                dayNum.toString(),
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: isSelected ? const Color(0xFF6A1028) : const Color(0xFF1F2937),
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      onClear();
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'Clear Selection',
                      style: TextStyle(fontFamily: 'Poppins', color: Color(0xFF6A1028), fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
