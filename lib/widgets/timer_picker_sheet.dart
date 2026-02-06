import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class TimePickerSheet extends HookWidget {
  final int initialSeconds;
  final Function(int) onTimeSelected;

  const TimePickerSheet({
    Key? key,
    required this.initialSeconds,
    required this.onTimeSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hours = useState(initialSeconds ~/ 3600);
    final minutes = useState((initialSeconds % 3600) ~/ 60);
    final seconds = useState(initialSeconds % 60);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Set Custom Time',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTimePicker(
                'Hours',
                hours.value,
                (v) => hours.value = v,
                24,
              ),
              const SizedBox(width: 10),
              const Text(
                ':',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 10),
              _buildTimePicker(
                'Minutes',
                minutes.value,
                (v) => minutes.value = v,
                60,
              ),
              const SizedBox(width: 10),
              const Text(
                ':',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 10),
              _buildTimePicker(
                'Seconds',
                seconds.value,
                (v) => seconds.value = v,
                60,
              ),
            ],
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              final totalSeconds =
                  hours.value * 3600 + minutes.value * 60 + seconds.value;
              if (totalSeconds > 0) {
                onTimeSelected(totalSeconds);
              }
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Set Time', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildTimePicker(
    String label,
    int value,
    Function(int) onChanged,
    int maxValue,
  ) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 5),
        Container(
          width: 70,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<int>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            items: List.generate(maxValue, (i) => i).map((i) {
              return DropdownMenuItem(
                value: i,
                child: Text(
                  i.toString().padLeft(2, '0'),
                  textAlign: TextAlign.center,
                ),
              );
            }).toList(),
            onChanged: (v) => onChanged(v ?? 0),
          ),
        ),
      ],
    );
  }
}
