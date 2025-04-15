import 'package:flutter/material.dart';

class CalendarRow extends StatelessWidget {
  final DateTime selectedDate;

  const CalendarRow({
    Key? key,
    required this.selectedDate,
  }) : super(key: key);

  List<DateTime> _getDaysInWeek() {
    // Find the start of the week (Sunday)
    DateTime startOfWeek = selectedDate.subtract(
      Duration(days: selectedDate.weekday % 7),
    );

    // Generate 7 days starting from Sunday
    return List.generate(7, (index) {
      return startOfWeek.add(Duration(days: index));
    });
  }

  @override
  Widget build(BuildContext context) {
    List<DateTime> weekDays = _getDaysInWeek();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: weekDays.map((date) {
          bool isToday = date.day == DateTime.now().day &&
              date.month == DateTime.now().month &&
              date.year == DateTime.now().year;

          return Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Day name (Sun, Mon, etc.)
                Text(
                  _getDayName(date.weekday),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                // Date number
                Container(
                  width: 36,
                  height: 36,
                  decoration: isToday
                      ? BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).primaryColor,
                        )
                      : null,
                  child: Center(
                    child: Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                        color: isToday ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case DateTime.sunday:
        return 'Sun';
      case DateTime.monday:
        return 'Mon';
      case DateTime.tuesday:
        return 'Tue';
      case DateTime.wednesday:
        return 'Wed';
      case DateTime.thursday:
        return 'Thu';
      case DateTime.friday:
        return 'Fri';
      case DateTime.saturday:
        return 'Sat';
      default:
        return '';
    }
  }
}
