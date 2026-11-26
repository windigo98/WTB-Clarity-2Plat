import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/download.dart';
import '../services/pick_file.dart';
import '../state/app_state.dart';
import '../widgets/brand.dart';
import '../widgets/chrome.dart';
import '../widgets/common.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _name;
  late final TextEditingController _time;

  @override
  void initState() {
    super.initState();
    final profile = context.read<AppState>().data.profile;
    _name = TextEditingController(text: profile.name);
    _time = TextEditingController(text: profile.reminderTime);
  }

  @override
  void dispose() {
    _name.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return ClarityPage(
      title: 'Settings',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Center(child: WingsCrewLogo(height: 92)),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Traveler name'),
            onSubmitted: state.setName,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(onPressed: () => state.setName(_name.text), child: const Text('Save name')),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Habit reminder'),
            subtitle: const Text('Saved on this device. Phone alerts arrive when the mobile apps ship.'),
            value: state.data.profile.remindHabits,
            onChanged: (value) => state.setReminder(enabled: value, time: _time.text),
          ),
          TextField(
            controller: _time,
            decoration: const InputDecoration(labelText: 'Reminder time'),
            onSubmitted: (value) => state.setReminder(enabled: state.data.profile.remindHabits, time: value),
          ),
          const SizedBox(height: 20),
          Text('Streaks', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          const Text('A day off does not break your streak. Hours before the new day still count as the day before.'),
          const SizedBox(height: 8),
          DropdownButtonFormField<int?>(
            key: const Key('rest-day'),
            initialValue: state.data.profile.restWeekday,
            decoration: const InputDecoration(labelText: 'Weekly day off'),
            items: const [
              DropdownMenuItem(value: null, child: Text('No day off')),
              DropdownMenuItem(value: DateTime.monday, child: Text('Monday')),
              DropdownMenuItem(value: DateTime.tuesday, child: Text('Tuesday')),
              DropdownMenuItem(value: DateTime.wednesday, child: Text('Wednesday')),
              DropdownMenuItem(value: DateTime.thursday, child: Text('Thursday')),
              DropdownMenuItem(value: DateTime.friday, child: Text('Friday')),
              DropdownMenuItem(value: DateTime.saturday, child: Text('Saturday')),
              DropdownMenuItem(value: DateTime.sunday, child: Text('Sunday')),
            ],
            onChanged: state.setRestWeekday,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            key: const Key('day-start'),
            initialValue: state.data.profile.dayStartHour.clamp(0, 8),
            decoration: const InputDecoration(labelText: 'New day starts'),
            items: [
              for (var hour = 0; hour <= 8; hour++)
                DropdownMenuItem(value: hour, child: Text(_dayStartLabel(hour))),
            ],
            onChanged: (hour) {
              if (hour != null) state.setDayStartHour(hour);
            },
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () async {
              final backup = await state.exportBackup();
              if (!context.mounted) return;
              final bytes = utf8.encode(const JsonEncoder.withIndent('  ').convert(backup));
              await downloadBytes(bytes, 'wtb-clarity-export.json', 'application/json');
            },
            icon: const Icon(Icons.download),
            label: const Text('Export data'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _import(context, state),
            icon: const Icon(Icons.upload_file),
            label: const Text('Import / restore'),
          ),
          const SizedBox(height: 6),
          const Text('Large photo backups can be several MB. Older files still load, but they may not include photos.'),
          const SizedBox(height: 24),
          Text('About', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const WingsCrewText(
            'WTB Clarity 2plat is a habit and routine game from WingsCrew. The name is a nod to old MMO trade chat ("want to buy Clarity for 2 platinum"). The gamer flavor is our own.',
          ),
          const SizedBox(height: 8),
          const WingsCrewText(
            'WTB Clarity 2plat is an independent WingsCrew app and is not affiliated with or endorsed by EverQuest or Daybreak Game Company.',
          ),
          const SizedBox(height: 8),
          const Text(
            'This project is proprietary and All Rights Reserved. The source is viewable but may not be copied, modified, or reused without written permission. Contact dovewingsbusiness@gmail.com.',
          ),
          const SizedBox(height: 8),
          const Text('Sign-in arrives with crews in a later phase. Progress stays on this device for now.'),
          const SizedBox(height: 16),
          const MoreFromWingsCrewButton(),
          const SizedBox(height: 16),
          const CopyrightFooter(),
        ],
      ),
    );
  }

  Future<void> _import(BuildContext context, AppState state) async {
    final text = await pickTextFile();
    if (!context.mounted || text == null || text.trim().isEmpty) return;
    Map<String, dynamic>? json;
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map) json = Map<String, dynamic>.from(decoded);
    } catch (_) {}
    if (json == null) {
      _say(context, 'That file is not a WTB Clarity 2plat backup.');
      return;
    }
    final parsed = parseBackup(json, nowMs: state.now.millisecondsSinceEpoch);
    if (parsed.error != null) {
      _say(context, parsed.error!);
      return;
    }
    if (!context.mounted) return;
    final replace = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Replace progress?'),
        content: const Text('This replaces everything on this device with the file. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Replace')),
        ],
      ),
    );
    if (replace != true || !context.mounted) return;
    final error = await state.importBackup(json);
    if (!context.mounted) return;
    if (error != null) {
      _say(context, error);
      return;
    }
    _name.text = state.data.profile.name;
    _time.text = state.data.profile.reminderTime;
    _say(
      context,
      parsed.photosMissing ? 'Restored. This older file did not include photos.' : 'Restored.',
    );
  }

  void _say(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

String _dayStartLabel(int hour) {
  if (hour <= 0) return 'Midnight';
  if (hour < 12) return '$hour AM';
  if (hour == 12) return 'Noon';
  return '${hour - 12} PM';
}
