/// Calendar: month grid with per-status task dots, selected day's tasks
/// rendered below as shared task rows. Body-only -- the shell owns the app bar.
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'package:task_management/models/task.dart';
import 'package:task_management/data/task_store.dart';
import 'package:task_management/screens/task_details_screen.dart';
import 'package:task_management/screens/today_screen.dart';
import 'package:task_management/theme/app_colors.dart';
import 'package:task_management/theme/app_theme.dart';
import 'package:task_management/navigation/app_shell.dart';

class TaskCalendar extends StatefulWidget implements ShellPage {
  const TaskCalendar({super.key});

  @override
  String get title => 'Calendar';

  @override
  String? get subtitle => null;

  @override
  _TaskCalendarState createState() => _TaskCalendarState();
}

class _TaskCalendarState extends State<TaskCalendar> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  late final TaskStore _taskStore;
  List<Task> _allTasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _taskStore = context.read<TaskStore>();
    _loadTasks();
  }

  /// Loads every task once so the whole visible month can show dots --
  /// fetching per-day (the old approach) never populated days you hadn't
  /// already tapped.
  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    final tasks = await _taskStore.fetch();
    if (!mounted) return;
    setState(() {
      _allTasks = tasks;
      _isLoading = false;
    });
  }

  List<Task> _tasksOn(DateTime day) =>
      _allTasks.where((t) => t.dueDate != null && isSameDay(t.dueDate, day)).toList();

  Future<void> _toggleDone(Task task) async {
    await _taskStore.update(task.isCompleted ? task.withStatus(TaskStatus.todo) : task.markAsCompleted());
    _loadTasks();
  }

  void _openTask(Task task) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => TaskDetailsScreen(task: task)))
        .then((_) => _loadTasks());
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.terra));
    }

    final selectedTasks = _tasksOn(_selectedDay);

    return RefreshIndicator(
      onRefresh: _loadTasks,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          TableCalendar<Task>(
            firstDay: DateTime.now().subtract(const Duration(days: 365)),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (focusedDay) => _focusedDay = focusedDay,
            eventLoader: _tasksOn,
            daysOfWeekHeight: 28,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700, fontSize: 17),
              leftChevronIcon: Icon(Icons.chevron_left, color: AppColors.ink2),
              rightChevronIcon: Icon(Icons.chevron_right, color: AppColors.ink2),
            ),
            calendarBuilders: CalendarBuilders(
              // Dots are drawn inside our own day cell builders below --
              // suppress table_calendar's built-in marker overlay so they
              // don't double up.
              markerBuilder: (context, day, events) => null,
              dowBuilder: (context, day) => Center(
                child: Text(
                  _weekdayLabel(day.weekday),
                  style: const TextStyle(
                      fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.ink3),
                ),
              ),
              defaultBuilder: (context, day, focusedDay) => _DayCell(day: day, tasks: _tasksOn(day)),
              outsideBuilder: (context, day, focusedDay) =>
                  _DayCell(day: day, tasks: const [], outside: true),
              todayBuilder: (context, day, focusedDay) =>
                  _DayCell(day: day, tasks: _tasksOn(day), isToday: true),
              selectedBuilder: (context, day, focusedDay) =>
                  _DayCell(day: day, tasks: _tasksOn(day), isSelected: true),
            ),
          ),
          const SizedBox(height: 14),
          Text(_selectedDayLabel(), style: AppTheme.display(size: 19)),
          const SizedBox(height: 10),
          if (selectedTasks.isEmpty)
            Container(
              padding: const EdgeInsets.all(30),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.sand, borderRadius: BorderRadius.circular(26)),
              child: const Text('No tasks due this day.', style: TextStyle(color: AppColors.ink2)),
            )
          else
            for (final t in selectedTasks)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TodayTaskRow(
                  task: t,
                  overdue: t.isOverdue,
                  onOpen: () => _openTask(t),
                  onToggle: () => _toggleDone(t),
                ),
              ),
        ],
      ),
    );
  }

  String _selectedDayLabel() {
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${weekdays[_selectedDay.weekday - 1]}, ${months[_selectedDay.month - 1]} ${_selectedDay.day}';
  }

  static String _weekdayLabel(int weekday) =>
      const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][weekday - 1];
}

/// 40px day cell, radius 12. Today = terra ring, selected = terra fill +
/// shell text, up to 3 status-colored dots for days with tasks.
class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.tasks,
    this.isToday = false,
    this.isSelected = false,
    this.outside = false,
  });

  final DateTime day;
  final List<Task> tasks;
  final bool isToday;
  final bool isSelected;
  final bool outside;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.terra : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isToday && !isSelected ? Border.all(color: AppColors.terra, width: 1.5) : null,
            ),
            child: Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: isToday || isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AppColors.shell
                    : outside
                        ? AppColors.ink3
                        : AppColors.ink,
              ),
            ),
          ),
          const SizedBox(height: 3),
          SizedBox(
            height: 6,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final status in tasks.map((t) => t.status).toSet().take(3))
                  Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(color: AppColors.statusColor(status), shape: BoxShape.circle),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
