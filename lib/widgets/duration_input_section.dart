import 'package:flutter/material.dart';

class DurationInputSection extends StatelessWidget {
  final String title;
  final TextEditingController minutesController;
  final TextEditingController secondsController;

  const DurationInputSection({
    super.key,
    required this.title,
    required this.minutesController,
    required this.secondsController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: minutesController,
                decoration: const InputDecoration(
                  labelText: 'Minutes',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: secondsController,
                decoration: const InputDecoration(
                  labelText: 'Seconds',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
