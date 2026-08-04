import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateTimePicker extends StatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final TimeOfDay? initialStartTime;
  final TimeOfDay? initialEndTime;
  final Function(
    DateTime? startDate,
    TimeOfDay? startTime,
    DateTime? endDate,
    TimeOfDay? endTime,
  )
  onDateTimeRangeSelected;

  const DateTimePicker({
    super.key,
    this.initialStartDate,
    this.initialEndDate,
    this.initialStartTime,
    this.initialEndTime,
    required this.onDateTimeRangeSelected,
  });

  @override
  State<DateTimePicker> createState() => _DateTimePickerState();
}

class _DateTimePickerState extends State<DateTimePicker> {
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  DateTime _currentMonth = DateTime.now();
  bool _isSelectingStart = true;
  int _activeTab = 0; // 0 = Date, 1 = Time

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
    _startTime = widget.initialStartTime ?? const TimeOfDay(hour: 9, minute: 0);
    _endTime = widget.initialEndTime ?? const TimeOfDay(hour: 18, minute: 0);
    if (_startDate != null) {
      _currentMonth = DateTime(_startDate!.year, _startDate!.month);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.92,
        constraints: const BoxConstraints(maxWidth: 450, maxHeight: 650),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(context),
            const SizedBox(height: 12),

            // Selected Range Display
            _buildSelectedRangeDisplay(),
            const SizedBox(height: 12),

            // Tab Selector
            _buildTabSelector(),
            const SizedBox(height: 12),

            // Content based on selected tab
            Expanded(
              child: _activeTab == 0
                  ? _buildDatePickerContent()
                  : _buildTimePickerContent(),
            ),

            const SizedBox(height: 12),

            // Action Buttons
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Select Date & Time Range',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close, color: Colors.grey),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildSelectedRangeDisplay() {
    final DateFormat dateFormatter = DateFormat('dd MMM yyyy');
    final DateFormat timeFormatter = DateFormat('hh:mm a');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'From',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _startDate != null
                      ? dateFormatter.format(_startDate!)
                      : 'Select Date',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _startDate != null ? Colors.black87 : Colors.grey,
                  ),
                ),
                if (_startTime != null)
                  Text(
                    timeFormatter.format(_getDateTimeFromTime(_startTime!)),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward, color: Colors.grey, size: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'To',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _endDate != null
                      ? dateFormatter.format(_endDate!)
                      : 'Select Date',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _endDate != null ? Colors.black87 : Colors.grey,
                  ),
                ),
                if (_endTime != null)
                  Text(
                    timeFormatter.format(_getDateTimeFromTime(_endTime!)),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _activeTab = 0;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _activeTab == 0
                      ? const Color(0xFF4A25A9)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '📅 Date',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _activeTab == 0
                        ? Colors.white
                        : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _activeTab = 1;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _activeTab == 1
                      ? const Color(0xFF4A25A9)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '🕐 Time',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _activeTab == 1
                        ? Colors.white
                        : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickerContent() {
    return Column(
      children: [
        // Month Navigation
        _buildMonthNavigation(),
        const SizedBox(height: 8),

        // Calendar Grid
        Expanded(child: _buildCalendarGrid()),
      ],
    );
  }

  Widget _buildMonthNavigation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () {
            setState(() {
              _currentMonth = DateTime(
                _currentMonth.year,
                _currentMonth.month - 1,
              );
            });
          },
          icon: const Icon(Icons.chevron_left),
          style: IconButton.styleFrom(
            backgroundColor: Colors.grey.shade100,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        Text(
          DateFormat('MMMM yyyy').format(_currentMonth),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        IconButton(
          onPressed: () {
            setState(() {
              _currentMonth = DateTime(
                _currentMonth.year,
                _currentMonth.month + 1,
              );
            });
          },
          icon: const Icon(Icons.chevron_right),
          style: IconButton.styleFrom(
            backgroundColor: Colors.grey.shade100,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid() {
    final int daysInMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      0,
    ).day;
    final int firstDayOfMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month,
      1,
    ).weekday;

    final int startOffset = firstDayOfMonth - 1;

    final List<DateTime> daysInMonthList = List.generate(
      daysInMonth,
      (index) => DateTime(_currentMonth.year, _currentMonth.month, index + 1),
    );

    final List<Widget> dayWidgets = [];

    // Weekday headers
    const List<String> weekdays = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
    for (String day in weekdays) {
      dayWidgets.add(
        Container(
          alignment: Alignment.center,
          child: Text(
            day,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    // Empty slots for days before first day
    for (int i = 0; i < startOffset; i++) {
      dayWidgets.add(const SizedBox.shrink());
    }

    // Calendar days
    for (DateTime day in daysInMonthList) {
      final bool isStartDate =
          _startDate != null && _isSameDay(day, _startDate!);
      final bool isEndDate = _endDate != null && _isSameDay(day, _endDate!);
      final bool isInRange =
          _startDate != null &&
          _endDate != null &&
          day.isAfter(_startDate!) &&
          day.isBefore(_endDate!);
      final bool isToday = _isSameDay(day, DateTime.now());
      final bool isSelectable =
          _startDate == null ||
          _endDate == null ||
          (_startDate != null && _endDate != null);

      dayWidgets.add(
        GestureDetector(
          onTap: isSelectable ? () => _onDateSelected(day) : null,
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isStartDate || isEndDate
                  ? const Color(0xFF4A25A9)
                  : isInRange
                  ? const Color(0xFFE8E0F3)
                  : isToday
                  ? const Color(0xFFF5F0FF)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isToday && !isStartDate && !isEndDate
                  ? Border.all(color: const Color(0xFF4A25A9).withOpacity(0.3))
                  : null,
            ),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isStartDate || isEndDate
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: isStartDate || isEndDate
                      ? Colors.white
                      : isInRange
                      ? const Color(0xFF4A25A9)
                      : Colors.black87,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 7,
      crossAxisSpacing: 2,
      mainAxisSpacing: 2,
      childAspectRatio: 1.1,
      children: dayWidgets,
    );
  }

  Widget _buildTimePickerContent() {
    return Column(
      children: [
        const Text(
          'Select Time Range',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _buildTimePickerColumn(
                  label: 'Start Time',
                  time: _startTime,
                  onTimeChanged: (time) {
                    setState(() {
                      _startTime = time;
                    });
                  },
                  isStart: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTimePickerColumn(
                  label: 'End Time',
                  time: _endTime,
                  onTimeChanged: (time) {
                    setState(() {
                      _endTime = time;
                    });
                  },
                  isStart: false,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimePickerColumn({
    required String label,
    required TimeOfDay? time,
    required Function(TimeOfDay) onTimeChanged,
    required bool isStart,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          // Hour Picker
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    IconButton(
                      onPressed: () {
                        int newHour = (time?.hour ?? 0) + 1;
                        if (newHour > 23) newHour = 0;
                        onTimeChanged(
                          TimeOfDay(hour: newHour, minute: time?.minute ?? 0),
                        );
                      },
                      icon: const Icon(Icons.arrow_drop_up, size: 32),
                      color: const Color(0xFF4A25A9),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        '${time?.hour.toString().padLeft(2, '0') ?? '00'}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4A25A9),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        int newHour = (time?.hour ?? 0) - 1;
                        if (newHour < 0) newHour = 23;
                        onTimeChanged(
                          TimeOfDay(hour: newHour, minute: time?.minute ?? 0),
                        );
                      },
                      icon: const Icon(Icons.arrow_drop_down, size: 32),
                      color: const Color(0xFF4A25A9),
                    ),
                  ],
                ),
              ),
              const Text(
                ':',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    IconButton(
                      onPressed: () {
                        int newMinute = (time?.minute ?? 0) + 5;
                        if (newMinute >= 60) newMinute = 0;
                        onTimeChanged(
                          TimeOfDay(hour: time?.hour ?? 0, minute: newMinute),
                        );
                      },
                      icon: const Icon(Icons.arrow_drop_up, size: 32),
                      color: const Color(0xFF4A25A9),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        '${time?.minute.toString().padLeft(2, '0') ?? '00'}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4A25A9),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        int newMinute = (time?.minute ?? 0) - 5;
                        if (newMinute < 0) newMinute = 55;
                        onTimeChanged(
                          TimeOfDay(hour: time?.hour ?? 0, minute: newMinute),
                        );
                      },
                      icon: const Icon(Icons.arrow_drop_down, size: 32),
                      color: const Color(0xFF4A25A9),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // AM/PM Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildAmPmButton('AM', time, onTimeChanged),
              const SizedBox(width: 8),
              _buildAmPmButton('PM', time, onTimeChanged),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmPmButton(
    String ampm,
    TimeOfDay? time,
    Function(TimeOfDay) onTimeChanged,
  ) {
    final bool isSelected =
        time != null &&
        ((ampm == 'AM' && time.period == DayPeriod.am) ||
            (ampm == 'PM' && time.period == DayPeriod.pm));

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (time != null) {
            int newHour = time.hour;
            if (ampm == 'AM' && time.hour >= 12) {
              newHour = time.hour - 12;
            } else if (ampm == 'PM' && time.hour < 12) {
              newHour = time.hour + 12;
            }
            onTimeChanged(TimeOfDay(hour: newHour, minute: time.minute));
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF4A25A9) : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            ampm,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.black87,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final bool isValid =
        _startDate != null &&
        _endDate != null &&
        _startTime != null &&
        _endTime != null;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              setState(() {
                _startDate = null;
                _endDate = null;
                _startTime = const TimeOfDay(hour: 9, minute: 0);
                _endTime = const TimeOfDay(hour: 18, minute: 0);
                _isSelectingStart = true;
              });
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            child: const Text(
              'Clear',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed: isValid
                ? () {
                    widget.onDateTimeRangeSelected(
                      _startDate,
                      _startTime,
                      _endDate,
                      _endTime,
                    );
                    Navigator.pop(context);
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A25A9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
              disabledBackgroundColor: Colors.grey.shade300,
            ),
            child: Text(
              isValid ? 'Apply (${_getDaysBetween()}d)' : 'Select Range',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  DateTime _getDateTimeFromTime(TimeOfDay time) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, time.hour, time.minute);
  }

  void _onDateSelected(DateTime selectedDate) {
    setState(() {
      if (_startDate == null || (_startDate != null && _endDate != null)) {
        // Start new selection
        _startDate = selectedDate;
        _endDate = null;
        _isSelectingStart = false;
      } else if (_isSelectingStart || selectedDate.isBefore(_startDate!)) {
        // Set as start date
        _startDate = selectedDate;
        _endDate = null;
      } else {
        // Set as end date (must be after start date)
        _endDate = selectedDate;
        if (_isSameDay(selectedDate, _startDate!)) {
          _endDate = null;
        }
      }
    });
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  int _getDaysBetween() {
    if (_startDate == null || _endDate == null) return 0;
    return _endDate!.difference(_startDate!).inDays + 1;
  }
}

// Helper function to show the date-time range picker
Future<DateTimeRangeResult?> showDateTimeRangePicker({
  required BuildContext context,
  DateTime? initialStartDate,
  DateTime? initialEndDate,
  TimeOfDay? initialStartTime,
  TimeOfDay? initialEndTime,
}) async {
  DateTimeRangeResult? result;

  await showDialog(
    context: context,
    builder: (context) => DateTimePicker(
      initialStartDate: initialStartDate,
      initialEndDate: initialEndDate,
      initialStartTime: initialStartTime,
      initialEndTime: initialEndTime,
      onDateTimeRangeSelected: (startDate, startTime, endDate, endTime) {
        result = DateTimeRangeResult(
          startDate: startDate,
          startTime: startTime,
          endDate: endDate,
          endTime: endTime,
        );
      },
    ),
  );

  return result;
}

class DateTimeRangeResult {
  final DateTime? startDate;
  final TimeOfDay? startTime;
  final DateTime? endDate;
  final TimeOfDay? endTime;

  DateTimeRangeResult({
    this.startDate,
    this.startTime,
    this.endDate,
    this.endTime,
  });

  DateTime? get startDateTime {
    if (startDate == null || startTime == null) return null;
    return DateTime(
      startDate!.year,
      startDate!.month,
      startDate!.day,
      startTime!.hour,
      startTime!.minute,
    );
  }

  DateTime? get endDateTime {
    if (endDate == null || endTime == null) return null;
    return DateTime(
      endDate!.year,
      endDate!.month,
      endDate!.day,
      endTime!.hour,
      endTime!.minute,
    );
  }
}
