import 'package:flow_app/providers/providers.barrel.dart';
import 'package:flow_app/widgets/widgets.barrel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';

class PresetsPage extends HookWidget {
  const PresetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final presetProvider = Provider.of<PresetProvider>(context);
    final timerProvider = Provider.of<TimerProvider>(context, listen: false);
    void showAddPresetDialog(BuildContext context) {
      showDialog(
        context: context,
        builder: (context) => AddPresetDialog(
          presetProvider: presetProvider,
          timerProvider: timerProvider,
        ),
      );
    }

    return MenuScaffold(
      title: 'Presets',
      actions: [
        IconButton(
          onPressed: () => showAddPresetDialog(context),
          icon: const Icon(Icons.add),
        ),
      ],
      body: PresetSelectorMenu(
        presetProvider: presetProvider,
        timerProvider: timerProvider,
        onPresetSelected: () => Navigator.pop(context),
      ),
    );
  }
}
