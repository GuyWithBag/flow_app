import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../models/models.barrel.dart';

class PresetProvider extends ChangeNotifier {
  static final _defaultPresets = [
    PomodoroPreset(
      id: 'classic',
      name: 'Classic',
      focusDuration: 1500,
      breakDuration: 300,
      longFocusDuration: 3000,
      longBreakDuration: 900,
    ),
    PomodoroPreset(
      id: 'light_study',
      name: 'Light Study',
      focusDuration: 900,
      breakDuration: 180,
      longFocusDuration: 1800,
      longBreakDuration: 600,
    ),
    PomodoroPreset(
      id: 'heavy_study',
      name: 'Heavy Study',
      focusDuration: 2700,
      breakDuration: 600,
      longFocusDuration: 5400,
      longBreakDuration: 1200,
    ),
  ];

  final List<PomodoroPreset> _presets = [];
  PomodoroPreset? _selectedPreset;

  List<PomodoroPreset> get presets => List.unmodifiable(_presets);
  PomodoroPreset? get selectedPreset => _selectedPreset;

  Box<PomodoroPreset> get _box => Hive.box<PomodoroPreset>('presets');
  Box get _settingsBox => Hive.box('settings');

  void loadPresets() {
    _presets.clear();
    if (_box.isNotEmpty) {
      _presets.addAll(_box.values);
    } else {
      // First launch — seed defaults
      for (final preset in _defaultPresets) {
        _box.put(preset.id, preset);
      }
      _presets.addAll(_defaultPresets);
    }

    final selectedId =
        _settingsBox.get('selected_preset_id', defaultValue: '') as String;
    if (selectedId.isNotEmpty) {
      _selectedPreset = _presets.where((p) => p.id == selectedId).firstOrNull;
    }

    notifyListeners();
  }

  void selectPreset(PomodoroPreset preset) {
    _selectedPreset = preset;
    _settingsBox.put('selected_preset_id', preset.id);
    notifyListeners();
  }

  void clearPreset() {
    _selectedPreset = null;
    _settingsBox.put('selected_preset_id', '');
    notifyListeners();
  }

  Future<void> addPreset(PomodoroPreset preset) async {
    await _box.put(preset.id, preset);
    _presets.add(preset);
    notifyListeners();
  }

  Future<void> deletePreset(String id) async {
    await _box.delete(id);
    _presets.removeWhere((p) => p.id == id);
    if (_selectedPreset?.id == id) {
      _selectedPreset = null;
      _settingsBox.put('selected_preset_id', '');
    }
    notifyListeners();
  }
}
