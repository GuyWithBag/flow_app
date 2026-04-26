import 'package:fl_chart/fl_chart.dart';
import 'package:flow_app/models/models.barrel.dart';
import 'package:flow_app/pages/pages.barrel.dart';
import 'package:flow_app/providers/providers.barrel.dart';
import 'package:flow_app/services/ad_service.dart';
import 'package:flow_app/shared/format_duration.dart';
import 'package:flow_app/widgets/widgets.barrel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class DashboardPage extends HookWidget {
  const DashboardPage({super.key});

  static const _presetColors = [
    Color(0xFF66BB6A),
    Color(0xFF42A5F5),
    Color(0xFFFFB74D),
    Color(0xFFEF5350),
    Color(0xFFAB47BC),
    Color(0xFF26C6DA),
    Color(0xFF8D6E63),
  ];

  @override
  Widget build(BuildContext context) {
    final sessionProvider = context.watch<SessionProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final showMonthly = useState(false);

    final focusColor = themeProvider.getAccentColorFor(TimerType.focus);
    final breakColor = themeProvider.getAccentColorFor(TimerType.breakTime);
    final adService = context.watch<AdService>();

    return MenuScaffold(
      title: 'Dashboard',
      actions: [
        IconButton(
          icon: const Icon(Icons.history),
          onPressed: () {
            if (!context.read<PurchaseProvider>().isNoAds) {
              adService.maybeShowInterstitial(id: 'history', frequency: 5);
            }
            // todo: Gotta change navigation
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistoryPage()),
            );
          },
        ),
      ],
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDailyProgress(sessionProvider, themeProvider, focusColor),
            const SizedBox(height: 16),
            _buildStreakCard(sessionProvider, themeProvider),
            const SizedBox(height: 16),
            _buildStatsRow(sessionProvider, focusColor),
            const SizedBox(height: 24),
            _buildBarChartSection(sessionProvider, showMonthly, focusColor),
            const SizedBox(height: 24),
            _buildPresetBreakdown(sessionProvider),
            const SizedBox(height: 24),
            _buildFocusBreakRatio(sessionProvider, focusColor, breakColor),
            const SizedBox(height: 24),
            _buildRecentActivity(sessionProvider, focusColor, breakColor),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyProgress(
    SessionProvider sessionProvider,
    ThemeProvider themeProvider,
    Color focusColor,
  ) {
    final goalSeconds = themeProvider.dailyGoalMinutes * 60;
    final currentSeconds = sessionProvider.todayFocusSeconds;
    final progress = goalSeconds > 0
        ? (currentSeconds / goalSeconds).clamp(0.0, 1.0)
        : 0.0;
    final percent = (progress * 100).round();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(focusColor),
                  ),
                  Center(
                    child: Text(
                      '$percent%',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Today's Focus",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${formatDuration(currentSeconds)} / ${formatDuration(goalSeconds)}',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCard(
    SessionProvider sessionProvider,
    ThemeProvider themeProvider,
  ) {
    final streak = sessionProvider.currentStreak(
      themeProvider.dailyGoalMinutes,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFFFFB74D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.local_fire_department,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            '$streak Day Streak',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            streak > 0
                ? "Keep going! You're on fire!"
                : 'Complete your daily goal to start a streak!',
            style: const TextStyle(fontSize: 14, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(SessionProvider provider, Color focusColor) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Focus',
            formatDuration(provider.totalFocusSeconds),
            Icons.timer,
            const Color(0xFF42A5F5),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            'Sessions',
            '${provider.completedSessionCount}',
            Icons.check_circle_outline,
            focusColor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            'Avg Length',
            formatDuration(provider.averageSessionSeconds.round()),
            Icons.trending_up,
            const Color(0xFFAB47BC),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBarChartSection(
    SessionProvider provider,
    ValueNotifier<bool> showMonthly,
    Color focusColor,
  ) {
    final data = showMonthly.value
        ? provider.monthlyFocusSeconds
        : provider.weeklyFocusSeconds;
    final entries = data.entries.toList();
    final maxY = entries.fold<int>(
      0,
      (max, e) => e.value > max ? e.value : max,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Focus History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ToggleButtons(
              isSelected: [!showMonthly.value, showMonthly.value],
              onPressed: (index) {
                showMonthly.value = index == 1;
              },
              borderRadius: BorderRadius.circular(8),
              constraints: const BoxConstraints(minHeight: 32, minWidth: 60),
              textStyle: const TextStyle(fontSize: 12),
              children: const [Text('Week'), Text('Month')],
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: entries.isEmpty
              ? const Center(child: Text('No data yet'))
              : BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: (maxY * 1.2).clamp(60.0, double.infinity),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            formatDuration(rod.toY.round()),
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 36,
                          getTitlesWidget: (value, meta) {
                            final secs = value.round();
                            final label = secs == 0
                                ? '0'
                                : secs < 60
                                ? '${secs}s'
                                : '${secs ~/ 60}m';
                            return Text(
                              label,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= entries.length) {
                              return const SizedBox.shrink();
                            }
                            final date = entries[index].key;
                            final label = showMonthly.value
                                ? (index % 5 == 0
                                      ? DateFormat('d').format(date)
                                      : '')
                                : DateFormat('E').format(date).substring(0, 2);
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: entries.asMap().entries.map((entry) {
                      return BarChartGroupData(
                        x: entry.key,
                        barRods: [
                          BarChartRodData(
                            toY: entry.value.value.toDouble(),
                            color: focusColor,
                            width: showMonthly.value ? 6 : 20,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildPresetBreakdown(SessionProvider provider) {
    final breakdown = provider.presetBreakdown;
    if (breakdown.isEmpty) {
      return const SizedBox.shrink();
    }

    final total = breakdown.values.fold<int>(0, (sum, v) => sum + v);
    final entries = breakdown.entries.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Preset Breakdown',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: Row(
            children: [
              Expanded(
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 30,
                    sections: entries.asMap().entries.map((entry) {
                      final color =
                          _presetColors[entry.key % _presetColors.length];
                      final percent = total > 0
                          ? (entry.value.value / total * 100).round()
                          : 0;
                      return PieChartSectionData(
                        value: entry.value.value.toDouble(),
                        color: color,
                        radius: 50,
                        title: '$percent%',
                        titleStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: entries.asMap().entries.map((entry) {
                  final color = _presetColors[entry.key % _presetColors.length];
                  final seconds = entry.value.value;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${entry.value.key} (${formatDuration(seconds)})',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFocusBreakRatio(
    SessionProvider provider,
    Color focusColor,
    Color breakColor,
  ) {
    final focusSec = provider.totalFocusSeconds;
    final breakSec = provider.totalBreakSeconds;
    final total = focusSec + breakSec;

    if (total == 0) {
      return const SizedBox.shrink();
    }

    final focusPercent = (focusSec / total * 100).round();
    final breakPercent = 100 - focusPercent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Focus vs Break',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: Row(
            children: [
              Expanded(
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 30,
                    sections: [
                      PieChartSectionData(
                        value: focusSec.toDouble(),
                        color: focusColor,
                        radius: 50,
                        title: '$focusPercent%',
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      PieChartSectionData(
                        value: breakSec.toDouble(),
                        color: breakColor,
                        radius: 50,
                        title: '$breakPercent%',
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLegendItem(
                    'Focus',
                    focusColor,
                    formatDuration(focusSec),
                  ),
                  const SizedBox(height: 8),
                  _buildLegendItem(
                    'Break',
                    breakColor,
                    formatDuration(breakSec),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text('$label ($value)', style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildRecentActivity(
    SessionProvider provider,
    Color focusColor,
    Color breakColor,
  ) {
    final recentSessions = provider.sessions
        .where((s) => s.completed)
        .take(3)
        .toList();
    if (recentSessions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...recentSessions.map((session) {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: focusColor,
              child: const Icon(Icons.layers, color: Colors.white, size: 20),
            ),
            title: Text(session.name),
            subtitle: Text(
              DateFormat('MMM d, h:mm a').format(session.startTime),
            ),
            trailing: Text(formatDuration(session.totalDuration)),
          );
        }),
      ],
    );
  }
}
