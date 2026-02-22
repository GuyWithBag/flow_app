import 'package:flow_app/models/models.barrel.dart';
import 'package:flow_app/providers/providers.barrel.dart';
import 'package:flow_app/shared/format_duration.dart';
import 'package:flow_app/widgets/widgets.barrel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class HistoryScreen extends HookWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sessionProvider = context.watch<SessionProvider>();

    useEffect(() {
      sessionProvider.loadSessions();
      return null;
    }, const []);

    final completedSessions = sessionProvider.sessions
        .where((s) => s.completed)
        .toList();

    return FlowMenuBar(
      title: 'History',
      body: sessionProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : completedSessions.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              itemCount: completedSessions.length,
              itemBuilder: (context, index) {
                final session = completedSessions[index];
                return _buildSessionCard(context, session, sessionProvider);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          Text(
            'No sessions yet',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete a timer to see your history',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(
    BuildContext context,
    Session session,
    SessionProvider provider,
  ) {
    final themeProvider = context.watch<ThemeProvider>();
    final isBreak = session.type == TimerType.breakTime;
    final color = isBreak
        ? themeProvider.getAccentColorFor(TimerType.breakTime)
        : themeProvider.getAccentColorFor(TimerType.focus);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showEditDialog(context, session, provider),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isBreak ? 'Break' : 'Focus',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (session.presetName != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      session.presetName!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    DateFormat('MMM d, h:mm a').format(session.startTime),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.timer, size: 18, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Text(
                    formatDuration(session.duration),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (session.label != null) ...[
                const SizedBox(height: 8),
                Text(
                  session.label!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (session.progressNote != null) ...[
                const SizedBox(height: 4),
                Text(
                  session.progressNote!,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    Session session,
    SessionProvider provider,
  ) {
    final labelController = TextEditingController(text: session.label);
    final progressController = TextEditingController(
      text: session.progressNote,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Session'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelController,
              decoration: const InputDecoration(
                labelText: 'What did you do?',
                hintText: 'e.g., Studied Math',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: progressController,
              decoration: const InputDecoration(
                labelText: 'How much did you complete?',
                hintText: 'e.g., Completed 15 pages',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final updatedSession = session.copyWith(
                label: labelController.text.isEmpty
                    ? null
                    : labelController.text,
                progressNote: progressController.text.isEmpty
                    ? null
                    : progressController.text,
              );
              provider.updateSession(updatedSession);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
