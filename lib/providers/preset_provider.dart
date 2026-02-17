import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_local_storage/hive_local_storage.dart';

import '../models/models.dart';

class PresetProvider extends ChangeNotifier {
  static const _defaultPresets = <Map<String, dynamic>>[
    {
      'id': 'classic',
      'name': 'Classic',
      'focus_duration': 1500,
      'break_duration': 300,
      'long_focus_duration': 3000,
      'long_break_duration': 900,
      'cycles_before_long_break': 4,
    },
    {
      'id': 'light_study',
      'name': 'Light Study',
      'focus_duration': 900,
      'break_duration': 180,
      'long_focus_duration': 1800,
      'long_break_duration': 600,
      'cycles_before_long_break': 4,
    },
    {
      'id': 'heavy_study',
      'name': 'Heavy Study',
      'focus_duration': 2700,
      'break_duration': 600,
      'long_focus_duration': 5400,
      'long_break_duration': 1200,
      'cycles_before_long_break': 4,
    },
  ];

  final List<PomodoroPreset> _presets = [];
  PomodoroPreset? _selectedPreset;

  List<PomodoroPreset> get presets => List.unmodifiable(_presets);
  PomodoroPreset? get selectedPreset => _selectedPreset;

  Future<void> _savePresets() async {
    final encoded = _presets.map((p) => jsonEncode(p.toJson())).toList();
    await LocalStorage.i.put<String>(
      key: 'presets',
      value: jsonEncode(encoded),
    );
    await LocalStorage.i.put<String>(
      key: 'selected_preset_id',
      value: _selectedPreset?.id ?? '',
    );
  }

  Future<void> loadPresets() async {
    _presets.clear();
    final raw = LocalStorage.i.get<String>(key: 'presets');
    if (raw != null && raw.isNotEmpty) {
      final List<dynamic> decoded = jsonDecode(raw);
      for (final item in decoded) {
        final json = item is String ? jsonDecode(item) : item;
        _presets.add(PomodoroPreset.fromJson(json as Map<String, dynamic>));
      }
    } else {
      // First launch — use defaults
      _presets.addAll(_defaultPresets.map((j) => PomodoroPreset.fromJson(j)));
    }

    final selectedId =
        LocalStorage.i.get<String>(key: 'selected_preset_id') ?? '';
    if (selectedId.isNotEmpty) {
      _selectedPreset = _presets.where((p) => p.id == selectedId).firstOrNull;
    }

    notifyListeners();
  }

  void selectPreset(PomodoroPreset preset) {
    _selectedPreset = preset;
    notifyListeners();
    _savePresets();
  }

  void clearPreset() {
    _selectedPreset = null;
    notifyListeners();
    _savePresets();
  }

  Future<void> addPreset(PomodoroPreset preset) async {
    _presets.add(preset);
    notifyListeners();
    await _savePresets();
  }

  Future<void> deletePreset(String id) async {
    _presets.removeWhere((p) => p.id == id);
    if (_selectedPreset?.id == id) {
      _selectedPreset = null;
    }
    notifyListeners();
    await _savePresets();
  }
}
