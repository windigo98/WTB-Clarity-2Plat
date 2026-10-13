import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/gateways.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

class CrewPage extends StatelessWidget {
  const CrewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return ClarityPage(
      title: 'Crew',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Crews set sail in phase ${CrewGateway.phase}', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text(
            'You will invite friends, set a shared goal, and see each other\'s check-ins. For now there is no account and no server. Notes below stay on this device, ready for that later sync.',
          ),
          const SizedBox(height: 12),
          const SoftCard(
            child: Text('Planned tools: leave a crew, remove a member, and join only by invite.'),
          ),
          if (state.data.crewNotes.isEmpty)
            const SoftCard(child: Text('Check in, finish a focus bout, or win a game. A local note will wait here.'))
          else
            for (final note in state.data.crewNotes.take(12))
              SoftCard(
                child: Text('${note.summary}\nWaiting to share · ${note.type}'),
              ),
        ],
      ),
    );
  }
}
