import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/device_models.dart';
import '../../../core/utils/date_time.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/providers.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';

class LivePreviewCard extends ConsumerWidget {
  const LivePreviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final previewAsync = ref.watch(livePreviewProvider);
    
    return previewAsync.when(
      data: (preview) => _buildPreview(context, preview),
      loading: () => _buildSkeleton(context),
      error: (e, _) => _buildError(context, e.toString()),
    );
  }

  Widget _buildPreview(BuildContext context, LivePreview preview) {
    final paceStr = preview.paceSecPerKm > 0 
        ? DateTimeUtils.formatPace(preview.paceSecPerKm.toDouble())
        : '--:--';
    final speedStr = preview.speedKmh > 0 
        ? preview.speedKmh.toStringAsFixed(1)
        : '--.-';
    final distStr = DateTimeUtils.formatDistance(preview.distanceM.toDouble());
    final timeStr = DateTimeUtils.formatDuration(preview.elapsedSec);
    final hrStr = preview.hr > 0 ? '${preview.hr} bpm' : '--';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.speed, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Aperçu en direct',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: preview.gpsFix ? AppColors.secondary : AppColors.warning,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  preview.gpsFix ? 'GPS OK' : 'GPS...',
                  style: TextStyle(
                    fontSize: 11,
                    color: preview.gpsFix ? AppColors.secondary : AppColors.warning,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: MetricCard(
                    label: 'Allure',
                    value: paceStr,
                    icon: Icons.timer,
                    unit: '/km',
                    valueColor: AppColors.primary,
                  ),
                ),
                Expanded(
                  child: MetricCard(
                    label: 'Vitesse',
                    value: speedStr,
                    icon: Icons.speed,
                    unit: 'km/h',
                    valueColor: AppColors.secondary,
                  ),
                ),
                Expanded(
                  child: MetricCard(
                    label: 'SPM',
                    value: preview.spm.toString(),
                    icon: Icons.repeat,
                    valueColor: AppColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: MetricCard(
                    label: 'FC',
                    value: hrStr,
                    icon: Icons.favorite,
                    valueColor: preview.hr > 0 ? Colors.red : AppColors.textSecondary,
                  ),
                ),
                Expanded(
                  child: MetricCard(
                    label: 'Distance',
                    value: distStr,
                    icon: Icons.straighten,
                    valueColor: AppColors.primary,
                  ),
                ),
                Expanded(
                  child: MetricCard(
                    label: 'Temps',
                    value: timeStr,
                    icon: Icons.access_time,
                    valueColor: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            if (preview.driveTimeMs > 0 || preview.recoveryTimeMs > 0) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: MetricCard(
                      label: 'Propulsion',
                      value: '${preview.driveTimeMs} ms',
                      icon: Icons.arrow_upward,
                    ),
                  ),
                  Expanded(
                    child: MetricCard(
                      label: 'Récupération',
                      value: '${preview.recoveryTimeMs} ms',
                      icon: Icons.arrow_downward,
                    ),
                  ),
                  if (preview.arcDeg > 0)
                    Expanded(
                      child: MetricCard(
                        label: 'Amplitude',
                        value: '${preview.arcDeg}°',
                        icon: Icons.architecture,
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                BatteryIndicator(
                  level: preview.battery,
                  size: 20,
                  showPercentage: true,
                ),
                const Spacer(),
                if (preview.hrConnected)
                  Row(
                    children: [
                      Icon(Icons.favorite, size: 16, color: Colors.red),
                      const SizedBox(width: 4),
                      Text('FC connectée', style: TextStyle(fontSize: 12, color: AppColors.secondary)),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _shimmerBox(20, 20),
                const SizedBox(width: 8),
                _shimmerBox(120, 16),
                const Spacer(),
                _shimmerBox(8, 8, circular: true),
                const SizedBox(width: 4),
                _shimmerBox(60, 11),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: List.generate(3, (i) => Expanded(child: _metricSkeleton())).toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: List.generate(3, (i) => Expanded(child: _metricSkeleton())).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, String error) {
    return Card(
      color: AppColors.error.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Erreur aperçu: $error',
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shimmerBox(double width, double height, {bool circular = false}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: circular ? BorderRadius.circular(width / 2) : BorderRadius.circular(4),
      ),
    );
  }

  Widget _metricSkeleton() {
    return Column(
      children: [
        _shimmerBox(24, 24),
        const SizedBox(height: 4),
        _shimmerBox(60, 12),
        const SizedBox(height: 4),
        _shimmerBox(100, 24),
      ],
    );
  }
}

class DeviceControlButtons extends ConsumerWidget {
  const DeviceControlButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(deviceStatusProvider);
    final control = ref.read(activityControlProvider.notifier);
    
    return statusAsync.when(
      data: (status) {
        final isRecording = status?.state == DeviceState.recording;
        final isPaused = status?.state == DeviceState.paused;
        final isIdle = status?.state == DeviceState.idle || status == null;
        
        return Column(
          children: [
            if (isIdle) ...[
              _buildIdleButtons(context, control),
            ] else if (isRecording) ...[
              _buildRecordingButtons(context, control),
            ] else if (isPaused) ...[
              _buildPausedButtons(context, control),
            ],
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Erreur: $e', style: const TextStyle(color: AppColors.error)),
    );
  }

  Widget _buildIdleButtons(BuildContext context, ActivityControlNotifier control) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        _ActionButton(
          icon: Icons.play_arrow,
          label: 'Séance libre',
          color: AppColors.primary,
          onPressed: () => _showWorkoutDialog(context, control, WorkoutType.free),
        ),
        _ActionButton(
          icon: Icons.timer,
          label: 'Temps',
          color: AppColors.secondary,
          onPressed: () => _showWorkoutDialog(context, control, WorkoutType.time),
        ),
        _ActionButton(
          icon: Icons.straighten,
          label: 'Distance',
          color: AppColors.warning,
          onPressed: () => _showWorkoutDialog(context, control, WorkoutType.distance),
        ),
        _ActionButton(
          icon: Icons.repeat,
          label: 'Intervalles',
          color: Colors.purple,
          onPressed: () => _showWorkoutDialog(context, control, WorkoutType.interval),
        ),
      ],
    );
  }

  Widget _buildRecordingButtons(BuildContext context, ActivityControlNotifier control) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ActionButton(
          icon: Icons.pause,
          label: 'Pause',
          color: AppColors.warning,
          onPressed: () => control.pause(),
          isLarge: true,
        ),
        const SizedBox(width: 16),
        _ActionButton(
          icon: Icons.stop,
          label: 'Arrêter',
          color: AppColors.error,
          onPressed: () => control.stop(),
          isLarge: true,
        ),
      ],
    );
  }

  Widget _buildPausedButtons(BuildContext context, ActivityControlNotifier control) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ActionButton(
          icon: Icons.play_arrow,
          label: 'Reprendre',
          color: AppColors.secondary,
          onPressed: () => control.startFree(),
          isLarge: true,
        ),
        const SizedBox(width: 16),
        _ActionButton(
          icon: Icons.save,
          label: 'Sauvegarder',
          color: AppColors.primary,
          onPressed: () => control.stop(),
          isLarge: true,
        ),
      ],
    );
  }

  void _showWorkoutDialog(BuildContext context, ActivityControlNotifier control, int type) {
    switch (type) {
      case WorkoutType.free:
        control.startFree();
        break;
      case WorkoutType.time:
        _showTimePicker(context, control);
        break;
      case WorkoutType.distance:
        _showDistancePicker(context, control);
        break;
      case WorkoutType.interval:
        _showIntervalPicker(context, control);
        break;
    }
  }

  void _showTimePicker(BuildContext context, ActivityControlNotifier control) {
    int minutes = 30;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Séance chronométrée'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Durée (minutes):'),
              Slider(
                value: minutes.toDouble(),
                min: 5,
                max: 180,
                divisions: 35,
                label: '$minutes min',
                onChanged: (v) => setState(() => minutes = v.round()),
              ),
              Text('$minutes minutes', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                control.startTime(minutes * 60);
              },
              child: const Text('Démarrer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDistancePicker(BuildContext context, ActivityControlNotifier control) {
    double km = 5.0;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Séance distance'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Distance (km):'),
              Slider(
                value: km,
                min: 1,
                max: 50,
                divisions: 49,
                label: '${km.toStringAsFixed(1)} km',
                onChanged: (v) => setState(() => km = v),
              ),
              Text('${km.toStringAsFixed(1)} km', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                control.startDistance((km * 1000).round());
              },
              child: const Text('Démarrer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showIntervalPicker(BuildContext context, ActivityControlNotifier control) {
    int reps = 5;
    int workMin = 3;
    int restMin = 2;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Intervalles'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _IntervalRow(label: 'Répétitions', value: reps, min: 1, max: 20, onChanged: (v) => setState(() => reps = v)),
              _IntervalRow(label: 'Travail (min)', value: workMin, min: 1, max: 30, onChanged: (v) => setState(() => workMin = v)),
              _IntervalRow(label: 'Repos (min)', value: restMin, min: 1, max: 30, onChanged: (v) => setState(() => restMin = v)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                control.startInterval(reps, workMin * 60, restMin * 60);
              },
              child: const Text('Démarrer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntervalRow extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _IntervalRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text('$value', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 12),
          IconButton(
            onPressed: value > min ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          IconButton(
            onPressed: value < max ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;
  final bool isLarge;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isLarge ? 140 : 120,
      height: isLarge ? 56 : 48,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: isLarge ? 24 : 20),
        label: Text(label, style: TextStyle(fontSize: isLarge ? 16 : 14)),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class DisplayModeSelector extends ConsumerWidget {
  const DisplayModeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configAsync = ref.watch(coachConfigProvider);
    
    return configAsync.when(
      data: (config) => _buildSelector(context, ref, config),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Erreur: $e'),
    );
  }

  Widget _buildSelector(BuildContext context, WidgetRef ref, CoachConfig? config) {
    final currentMode = config?.displayMode ?? DisplayMode.pace;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mode d\'affichage', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                _ModeChip(
                  label: 'Allure',
                  icon: Icons.timer,
                  selected: currentMode == DisplayMode.pace,
                  onTap: () => _setMode(ref, config, DisplayMode.pace),
                ),
                _ModeChip(
                  label: 'Vitesse',
                  icon: Icons.speed,
                  selected: currentMode == DisplayMode.speed,
                  onTap: () => _setMode(ref, config, DisplayMode.speed),
                ),
                _ModeChip(
                  label: 'Graphique acc.',
                  icon: Icons.show_chart,
                  selected: currentMode == DisplayMode.accelGraph,
                  onTap: () => _setMode(ref, config, DisplayMode.accelGraph),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _setMode(WidgetRef ref, CoachConfig? config, int mode) {
    if (config == null) return;
    ref.read(coachConfigProvider.notifier).save(config.copyWith(displayMode: mode));
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: selected ? AppColors.primary : AppColors.textPrimary,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
      avatar: selected ? Icon(Icons.check, size: 16, color: AppColors.primary) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: selected ? AppColors.primary : Colors.grey[300]!),
      ),
    );
  }
}