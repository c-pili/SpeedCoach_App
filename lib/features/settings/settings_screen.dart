import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/providers.dart';
import '../../core/models/device_models.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/widgets/common_widgets.dart';
import '../../shared/widgets/modern_widgets.dart';
import '../../shared/theme/app_theme.dart';
import 'data_screens_editor.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ModernGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: ModernAppBar(title: 'Réglages'),
        body: Consumer(
          builder: (context, ref, _) {
            final configAsync = ref.watch(coachConfigProvider);
            final statusAsync = ref.watch(deviceStatusProvider);
            
            return AnimatedStaggeredList(
              padding: const EdgeInsets.all(16),
              spacing: 16,
              children: [
                _buildDeviceInfoCard(context, ref, statusAsync),
                _buildConfigSection(context, ref, configAsync),
                _buildWorkoutSection(context, ref, configAsync),
                _buildAdvancedSection(context, ref),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDeviceInfoCard(BuildContext context, WidgetRef ref, AsyncValue<DeviceStatus?> statusAsync) {
    return GradientCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white,
          AppColors.primary.withValues(alpha: 0.02),
        ],
      ),
      padding: const EdgeInsets.all(20),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'Informations appareil', animationIndex: 0),
          const SizedBox(height: 12),
          statusAsync.when(
            data: (status) {
              if (status == null) {
                return Text('Appareil non connecté', style: TextStyle(color: AppColors.textSecondary));
              }
              return Column(
                children: [
                  _InfoRow('Firmware', status.firmware),
                  _InfoRow('État', _formatState(status.state)),
                  _InfoRow('Batterie', '${status.battery}%${status.charging ? ' (charge)' : ''}'),
                  _InfoRow('GPS', status.gpsFix ? 'Fix OK' : 'Recherche...'),
                  _InfoRow('Fréquence cardiaque', status.hrConnected ? 'Connectée (${status.hrName ?? "inconnu"})' : 'Non connectée'),
                  _InfoRow('RowPod', status.podConnected ? 'Connecté (${status.podName ?? "inconnu"})' : 'Non connecté'),
                  _InfoRow('Stockage', '${(status.storageUsed / 1024).toStringAsFixed(1)} KB / ${(status.storageTotal / 1024).toStringAsFixed(1)} KB'),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Erreur: $e', style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  String _formatState(String state) {
    switch (state) {
      case DeviceState.idle: return 'Inactif';
      case DeviceState.recording: return 'Enregistrement';
      case DeviceState.paused: return 'En pause';
      default: return state;
    }
  }

  Widget _buildConfigSection(BuildContext context, WidgetRef ref, AsyncValue<CoachConfig?> configAsync) {
    return GradientCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white,
          AppColors.primary.withValues(alpha: 0.02),
        ],
      ),
      padding: const EdgeInsets.all(20),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Configuration',
            action: TextButton.icon(
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Recharger'),
              onPressed: () => ref.invalidate(coachConfigProvider),
            ),
            animationIndex: 1,
          ),
          const SizedBox(height: 12),
          configAsync.when(
            data: (config) {
              if (config == null) {
                return const Center(child: Text('Non connecté'));
              }
              return ConfigEditor(config: config);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Erreur: $e', style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutSection(BuildContext context, WidgetRef ref, AsyncValue<CoachConfig?> configAsync) {
    return GradientCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white,
          AppColors.primary.withValues(alpha: 0.02),
        ],
      ),
      padding: const EdgeInsets.all(20),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'Configuration séance', animationIndex: 2),
          const SizedBox(height: 12),
          configAsync.when(
            data: (config) => WorkoutSetup(config: config),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Erreur: $e', style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedSection(BuildContext context, WidgetRef ref) {
    return GradientCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white,
          AppColors.primary.withValues(alpha: 0.02),
        ],
      ),
      padding: const EdgeInsets.all(20),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'Avancé', animationIndex: 3),
          const SizedBox(height: 12),
          _AdvancedTile(
            icon: Icons.bluetooth,
            title: 'Appareils BLE appariés',
            subtitle: 'Gérer les ceintures FC et RowPod',
            onTap: () => _showPairedDevices(context, ref),
          ),
          _AdvancedTile(
            icon: Icons.storage,
            title: 'Stockage',
            subtitle: 'Voir l\'espace disponible et formater',
            onTap: () => _showStorageInfo(context, ref),
          ),
          _AdvancedTile(
            icon: Icons.info,
            title: 'À propos',
            subtitle: 'Version, licences, etc.',
            onTap: () => _showAbout(context),
          ),
        ],
      ),
    );
  }

  void _showPairedDevices(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Appareils BLE appariés'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _AdvancedTile(
              icon: Icons.favorite,
              title: 'Ceinture FC',
              subtitle: 'Suunto Watch HR 1029 (auto)',
              onTap: () {},
            ),
            _AdvancedTile(
              icon: Icons.sensors,
              title: 'RowPod',
              subtitle: 'Non appairé',
              onTap: () {},
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer')),
        ],
      ),
    );
  }

  void _showStorageInfo(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.read(deviceStatusProvider);
    statusAsync.whenData((status) {
      if (status == null) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Stockage'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _InfoRow('Utilisé', '${(status.storageUsed / 1024).toStringAsFixed(1)} KB'),
              _InfoRow('Total', '${(status.storageTotal / 1024).toStringAsFixed(1)} KB'),
              _InfoRow('Disponible', '${((status.storageTotal - status.storageUsed) / 1024).toStringAsFixed(1)} KB'),
              const SizedBox(height: 16),
              GradientCard(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                padding: const EdgeInsets.all(4),
                borderRadius: 6,
                child: LinearProgressIndicator(
                  value: status.storageUsed / status.storageTotal,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              GradientButton(
                gradient: AppColors.errorGradient,
                onPressed: () {
                  Navigator.pop(ctx);
                  _confirmFormat(context, ref);
                },
                child: const Text('Formater le stockage', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer')),
          ],
        ),
      );
    });
  }

  void _confirmFormat(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Formater le stockage'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: const Text('ATTENTION : Cela supprimera TOUTES les activités enregistrées. Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          GradientButton(
            gradient: AppColors.errorGradient,
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: Implement format storage command
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Formatage non implémenté')),
              );
            },
            child: const Text('Formater', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'SpeedCoach',
      applicationVersion: '1.0.0',
      applicationIcon: GradientCard(
        gradient: AppColors.primaryGradient,
        padding: const EdgeInsets.all(16),
        borderRadius: 16,
        child: const Icon(Icons.speed, size: 48, color: Colors.white),
      ),
      children: [
        const Text('Application de contrôle pour SpeedCoach ESP32C3'),
        const SizedBox(height: 16),
        const Text('Fonctionnalités:'),
        const Text('• Connexion Bluetooth Low Energy'),
        const Text('• Configuration appareil'),
        const Text('• Téléchargement activités (TCX/CSV)'),
        const Text('• Export vers Strava'),
        const Text('• Aperçu temps réel'),
        const SizedBox(height: 16),
        const Text('Basé sur le projet ESP32C3_SpeedCoach'),
      ],
    );
  }
}

class ConfigEditor extends ConsumerWidget {
  final CoachConfig config;

  const ConfigEditor({super.key, required this.config});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        _ConfigField(
          label: 'Distance splits (m)',
          value: config.splitDistance,
          min: 100,
          max: 10000,
          step: 100,
          onChanged: (v) => _save(ref, config.copyWith(splitDistance: v)),
        ),
        _ConfigField(
          label: 'Poids rameur (kg)',
          value: config.userWeight,
          min: 30,
          max: 150,
          step: 1,
          onChanged: (v) => _save(ref, config.copyWith(userWeight: v)),
        ),
        _ConfigField(
          label: 'Veille après (min)',
          value: config.sleepTimeoutMin,
          min: 5,
          max: 120,
          step: 5,
          onChanged: (v) => _save(ref, config.copyWith(sleepTimeoutMin: v)),
        ),
        _ConfigDropdown(
          label: 'Type bateau',
          value: config.boatType,
          items: const ['1x', '2x', '2-', '4x', '4-', '8+'],
          onChanged: (v) => _save(ref, config.copyWith(boatType: v!)),
        ),
        _ConfigDropdown(
          label: 'Mode affichage',
          value: _displayModeLabel(config.displayMode),
          items: const ['Allure', 'Vitesse', 'Graphique acc.'],
          onChanged: (v) => _save(ref, config.copyWith(displayMode: _displayModeValue(v!))),
        ),
        ListTile(
          title: const Text('Nom montre FC auto'),
          subtitle: Text(config.hrDeviceName),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showHrNameDialog(context, ref),
        ),
        SwitchListTile(
          title: const Text('Pause automatique'),
          subtitle: const Text('Met en pause automatiquement à l\'arrêt'),
          value: config.autoPause,
          onChanged: (v) => _save(ref, config.copyWith(autoPause: v)),
        ),
        SwitchListTile(
          title: const Text('Sons'),
          subtitle: const Text('Activer les notifications sonores'),
          value: config.soundEnabled,
          onChanged: (v) => _save(ref, config.copyWith(soundEnabled: v)),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.widgets),
          label: const Text('Configurer les écrans de données'),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DataScreensEditor()),
            );
          },
        ),
      ],
    );
  }

  void _showHrNameDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: config.hrDeviceName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nom de la montre FC'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nom exact de la montre (ex: Suunto Watch HR 1029)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _save(ref, config.copyWith(hrDeviceName: controller.text.trim()));
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _save(WidgetRef ref, CoachConfig newConfig) {
    ref.read(coachConfigProvider.notifier).save(newConfig);
  }

  String _displayModeLabel(int mode) {
    switch (mode) {
      case DisplayMode.pace: return 'Allure';
      case DisplayMode.speed: return 'Vitesse';
      case DisplayMode.accelGraph: return 'Graphique acc.';
      default: return 'Allure';
    }
  }

  int _displayModeValue(String label) {
    switch (label) {
      case 'Allure': return DisplayMode.pace;
      case 'Vitesse': return DisplayMode.speed;
      case 'Graphique acc.': return DisplayMode.accelGraph;
      default: return DisplayMode.pace;
    }
  }
}

class _ConfigField extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;

  const _ConfigField({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      subtitle: Slider(
        value: value.toDouble(),
        min: min.toDouble(),
        max: max.toDouble(),
        divisions: ((max - min) / step).round(),
        label: value.toString(),
        onChanged: (v) => onChanged(v.round()),
      ),
      trailing: Text('$value', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
    );
  }
}

class _ConfigDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _ConfigDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: DropdownButton<String>(
        value: value,
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
        underline: const SizedBox(),
      ),
    );
  }
}

class WorkoutSetup extends ConsumerWidget {
  final CoachConfig? config;

  const WorkoutSetup({super.key, this.config});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        _WorkoutTile(
          icon: Icons.play_circle,
          title: 'Séance libre',
          subtitle: 'Sans objectif, arrêt manuel',
          color: AppColors.primary,
          onTap: () => _startWorkout(ref, WorkoutType.free),
        ),
        _WorkoutTile(
          icon: Icons.timer,
          title: 'Séance chronométrée',
          subtitle: 'Durée cible configurable',
          color: AppColors.secondary,
          onTap: () => _showTimeDialog(context, ref),
        ),
        _WorkoutTile(
          icon: Icons.straighten,
          title: 'Séance distance',
          subtitle: 'Distance cible configurable',
          color: AppColors.warning,
          onTap: () => _showDistanceDialog(context, ref),
        ),
        _WorkoutTile(
          icon: Icons.repeat,
          title: 'Intervalles',
          subtitle: 'Séries travail/repos',
          color: Colors.purple,
          onTap: () => _showIntervalDialog(context, ref),
        ),
      ],
    );
  }

  void _startWorkout(WidgetRef ref, int type, {int? targetSec, int? targetM}) {
    ref.read(activityControlProvider.notifier).startFree();
  }

  void _showTimeDialog(BuildContext context, WidgetRef ref) {
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
                ref.read(activityControlProvider.notifier).startTime(minutes * 60);
              },
              child: const Text('Démarrer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDistanceDialog(BuildContext context, WidgetRef ref) {
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
                ref.read(activityControlProvider.notifier).startDistance((km * 1000).round());
              },
              child: const Text('Démarrer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showIntervalDialog(BuildContext context, WidgetRef ref) {
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
                ref.read(activityControlProvider.notifier).startInterval(reps, workMin * 60, restMin * 60);
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

class _WorkoutTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _WorkoutTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(color: AppColors.textSecondary)),
      trailing: Icon(Icons.chevron_right, color: color),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      tileColor: color.withValues(alpha: 0.03),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 130, child: Text(label, style: TextStyle(color: AppColors.textSecondary))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

class _AdvancedTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AdvancedTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.15),
              AppColors.primary.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      trailing: Icon(Icons.chevron_right, color: AppColors.primary),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}