import 'package:fintracker/services/coach_service.dart';
import 'package:fintracker/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class CoachScreen extends StatefulWidget {
  const CoachScreen({super.key});

  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> {
  Future<List<CoachMessage>>? _messages;

  @override
  void initState() {
    super.initState();
    _messages = CoachService.generateInsights();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Financial Coach', style: TextStyle(fontWeight: FontWeight.w600))),
      body: FutureBuilder<List<CoachMessage>>(
        future: _messages,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final messages = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: messages.length,
            itemBuilder: (context, index) => _MessageBubble(message: messages[index]),
          );
        },
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final CoachMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _bubbleColor(message.type, theme);
    final icon = _icon(message.type);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(message.text, style: theme.textTheme.bodyMedium?.copyWith(height: 1.4)),
            ),
          ),
        ],
      ),
    );
  }

  Color _bubbleColor(CoachMessageType type, ThemeData theme) {
    switch (type) {
      case CoachMessageType.positive:
        return AppTheme.incomeColor;
      case CoachMessageType.warning:
        return AppTheme.expenseColor;
      case CoachMessageType.tip:
        return Colors.blue;
      case CoachMessageType.greeting:
        return theme.colorScheme.primary;
      case CoachMessageType.insight:
        return theme.colorScheme.tertiary;
    }
  }

  IconData _icon(CoachMessageType type) {
    switch (type) {
      case CoachMessageType.positive:
        return Symbols.thumb_up;
      case CoachMessageType.warning:
        return Symbols.warning;
      case CoachMessageType.tip:
        return Symbols.lightbulb;
      case CoachMessageType.greeting:
        return Symbols.waving_hand;
      case CoachMessageType.insight:
        return Symbols.auto_awesome;
    }
  }
}
