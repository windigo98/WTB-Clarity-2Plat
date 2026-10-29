import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/download.dart';
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
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              final bytes = utf8.encode(const JsonEncoder.withIndent('  ').convert(state.exportJson()));
              downloadBytes(bytes, 'wtb-clarity-export.json', 'application/json');
            },
            icon: const Icon(Icons.download),
            label: const Text('Export data'),
          ),
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
}
