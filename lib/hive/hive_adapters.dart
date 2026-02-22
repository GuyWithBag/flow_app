import 'package:hive_ce/hive_ce.dart';

import '../models/models.barrel.dart';
import '../shared/enums/sound_type.dart';

@GenerateAdapters([
  AdapterSpec<PomodoroPreset>(),
  AdapterSpec<Session>(),
  AdapterSpec<UserProfile>(),
  AdapterSpec<TimerType>(),
  AdapterSpec<SoundType>(),
  AdapterSpec<Loop>(),
])

part 'hive_adapters.g.dart';
