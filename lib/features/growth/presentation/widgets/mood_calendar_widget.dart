import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../../injection_container.dart';
import '../../domain/entities/mood_entities.dart';
import '../../domain/usecases/mood_tracking_usecases.dart';

class MoodCalendarWidget extends StatefulWidget {
  const MoodCalendarWidget({super.key});

  @override
  State<MoodCalendarWidget> createState() => _MoodCalendarWidgetState();
}

class _MoodCalendarWidgetState extends State<MoodCalendarWidget> {
  late MoodTrackingUseCases _moodTracking;
  Map<DateTime, List<MoodEntry>> _moodEvents = {};
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _moodTracking = getIt<MoodTrackingUseCases>();
    _selectedDay = DateTime.now();
    _loadMoodHistory();
  }

  Future<void> _loadMoodHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 90)); // Last 3 months
      final history = await _moodTracking.getMoodEntriesInRange(startDate, endDate);
      
      final events = <DateTime, List<MoodEntry>>{};
      for (final entry in history) {
        final date = DateTime(entry.timestamp.year, entry.timestamp.month, entry.timestamp.day);
        events[date] = events[date] ?? [];
        events[date]!.add(entry);
      }
      
      setState(() {
        _moodEvents = events;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<MoodEntry> _getEventsForDay(DateTime day) {
    return _moodEvents[DateTime(day.year, day.month, day.day)] ?? [];
  }

  Color _getMoodColor(int moodLevel) {
    if (moodLevel <= 2) return Colors.red.shade600;
    if (moodLevel <= 4) return Colors.orange;
    if (moodLevel <= 6) return Colors.amber;
    if (moodLevel <= 8) return Colors.lightGreen;
    return Colors.green.shade600;
  }

  String _getMoodEmoji(int moodLevel) {
    if (moodLevel <= 2) return '�';
    if (moodLevel <= 4) return '�';
    if (moodLevel <= 6) return '😐';
    if (moodLevel <= 8) return '�';
    return '�';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(AppConstants.defaultPadding),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Symbols.calendar_month,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: AppConstants.smallPadding),
                Text(
                  'Kalender Mood',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            
            TableCalendar<MoodEntry>(
              firstDay: DateTime.utc(2023, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              eventLoader: _getEventsForDay,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, events) {
                  if (events.isEmpty) return const SizedBox.shrink();
                  
                  final moodEntry = events.first;
                  return Container(
                    margin: const EdgeInsets.only(top: 5),
                    alignment: Alignment.center,
                    child: Text(
                      _getMoodEmoji(moodEntry.moodLevel),
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                },
              ),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                weekendTextStyle: TextStyle(color: Colors.red.shade600),
                holidayTextStyle: TextStyle(color: Colors.red.shade600),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
            ),
            
            const SizedBox(height: AppConstants.defaultPadding),
            
            if (_selectedDay != null) ...[
              Text(
                'Mood untuk ${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppConstants.smallPadding),
              
              ..._getEventsForDay(_selectedDay!).map((entry) => Container(
                margin: const EdgeInsets.only(bottom: AppConstants.smallPadding),
                padding: const EdgeInsets.all(AppConstants.smallPadding),
                decoration: BoxDecoration(
                  color: _getMoodColor(entry.moodLevel).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
                  border: Border.all(
                    color: _getMoodColor(entry.moodLevel).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      _getMoodEmoji(entry.moodLevel),
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: AppConstants.smallPadding),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.moodDescription,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (entry.note?.isNotEmpty ?? false)
                            Text(
                              entry.note!,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          Text(
                            '${entry.timestamp.hour.toString().padLeft(2, '0')}:${entry.timestamp.minute.toString().padLeft(2, '0')}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
              
              if (_getEventsForDay(_selectedDay!).isEmpty)
                Text(
                  'Tidak ada mood yang dicatat untuk hari ini.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
