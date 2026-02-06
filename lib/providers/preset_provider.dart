import 'package:flutter/foundation.dart';

import '../models/models.dart';

class PresetProvider extends ChangeNotifier {
  final List<PomodoroPreset> _presets = [
    PomodoroPreset(
      id: 'classic',
      name: 'Classic',
      focusDuration: 1500,
      breakDuration: 300,
      longBreakDuration: 900,
    ),
    PomodoroPreset(
      id: 'light_study',
      name: 'Light Study',
      focusDuration: 900,
      breakDuration: 180,
      longBreakDuration: 600,
    ),
    PomodoroPreset(
      id: 'heavy_study',
      name: 'Heavy Study',
      focusDuration: 2700,
      breakDuration: 600,
      longBreakDuration: 1200,
    ),
  ];

  PomodoroPreset? _selectedPreset;

  List<PomodoroPreset> get presets => List.unmodifiable(_presets);
  PomodoroPreset? get selectedPreset => _selectedPreset;

  void selectPreset(PomodoroPreset preset) {
    _selectedPreset = preset;
    notifyListeners();
  }

  Future<void> addPreset(PomodoroPreset preset) async {
    _presets.add(preset);
    notifyListeners();
  }

  Future<void> deletePreset(String id) async {
    _presets.removeWhere((p) => p.id == id);
    notifyListeners();
  }
}
