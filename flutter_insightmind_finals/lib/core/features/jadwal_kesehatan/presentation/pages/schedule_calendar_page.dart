import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/schedule_providers.dart';

class ScheduleCalendarPage extends ConsumerStatefulWidget {
  const ScheduleCalendarPage({super.key});

  @override
  ConsumerState<ScheduleCalendarPage> createState() =>
      _ScheduleCalendarPageState();
}

class _ScheduleCalendarPageState extends ConsumerState<ScheduleCalendarPage> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedDay = DateTime(now.year, now.month, now.day);
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedDateProvider);
    final schedules = ref.watch(scheduleListProvider);
    final datesWithSchedules = ref.watch(datesWithSchedulesProvider);

    // Update _selectedDay jika selectedDateProvider berubah
    if (selected.year != _selectedDay.year ||
        selected.month != _selectedDay.month ||
        selected.day != _selectedDay.day) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _selectedDay = DateTime(selected.year, selected.month, selected.day);
          _focusedDay = _selectedDay;
        });
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal Kesehatan'),
      ),
      body: Column(
        children: [
          // Kalender dengan tanda merah
          datesWithSchedules.when(
            data: (dates) => Card(
              margin: const EdgeInsets.all(16),
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                calendarFormat: CalendarFormat.month,
                startingDayOfWeek: StartingDayOfWeek.monday,
                locale: 'id_ID',
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.indigo.shade100,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: Colors.indigo,
                    shape: BoxShape.circle,
                  ),
                  outsideDaysVisible: false,
                ),
                eventLoader: (day) {
                  final dateOnly = DateTime(day.year, day.month, day.day);
                  return dates.contains(dateOnly) ? [1] : [];
                },
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    if (events.isEmpty) return null;
                    final dateOnly = DateTime(date.year, date.month, date.day);
                    if (dates.contains(dateOnly)) {
                      return Positioned(
                        bottom: 1,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    }
                    return null;
                  },
                ),
                onDaySelected: (selectedDay, focusedDay) {
                  if (!isSameDay(_selectedDay, selectedDay)) {
                    setState(() {
                      _selectedDay = DateTime(
                          selectedDay.year, selectedDay.month, selectedDay.day);
                      _focusedDay = focusedDay;
                    });
                    ref.read(selectedDateProvider.notifier).state =
                        _selectedDay;
                    // ignore: unused_result
                    ref.refresh(scheduleListProvider);
                  }
                },
                onPageChanged: (focusedDay) {
                  setState(() {
                    _focusedDay = focusedDay;
                  });
                },
              ),
            ),
            loading: () => const Card(
              margin: EdgeInsets.all(16),
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (error, stack) => Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error loading calendar: $error'),
              ),
            ),
          ),
          // List schedule untuk tanggal yang dipilih
          Expanded(
            child: schedules.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (items) {
                if (items.isEmpty) {
                  return const Center(
                    child: Text('Belum ada jadwal untuk hari ini'),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final item = items[i];
                    return Card(
                      child: ListTile(
                        leading: Checkbox(
                          value: item.isDone,
                          onChanged: (v) async {
                            await ref
                                .read(scheduleRepositoryProvider)
                                .toggle(item.id);
                            // ignore: unused_result
                            ref.refresh(scheduleListProvider);
                            // ignore: unused_result
                            ref.refresh(datesWithSchedulesProvider);
                          },
                        ),
                        title: Text(item.title),
                        subtitle: item.note == null || item.note!.isEmpty
                            ? null
                            : Text(item.note!),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await ref
                                .read(scheduleRepositoryProvider)
                                .delete(item.id);
                            // ignore: unused_result
                            ref.refresh(scheduleListProvider);
                            // ignore: unused_result
                            ref.refresh(datesWithSchedulesProvider);
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final titleController = TextEditingController();
    final noteController = TextEditingController();
    final selected = ref.read(selectedDateProvider);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Jadwal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Judul kegiatan'),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteController,
              decoration:
                  const InputDecoration(labelText: 'Catatan (opsional)'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              final title = titleController.text.trim();
              final note = noteController.text.trim();
              if (title.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Judul tidak boleh kosong')),
                );
                return;
              }
              await ref.read(scheduleRepositoryProvider).add(
                    date: selected,
                    title: title,
                    note: note.isEmpty ? null : note,
                  );
              // ignore: unused_result
              ref.refresh(scheduleListProvider);
              // ignore: unused_result
              ref.refresh(datesWithSchedulesProvider);
              if (context.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Jadwal berhasil ditambahkan')),
                );
              }
            },
            child: const Text('Simpan'),
          )
        ],
      ),
    );
  }
}
