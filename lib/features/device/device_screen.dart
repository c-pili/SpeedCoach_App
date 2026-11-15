import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/services/providers.dart';
import '../../core/models/device_models.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/widgets/common_widgets.dart';
import '../../shared/theme/app_theme.dart';
import 'widgets/device_widgets.dart';

class DeviceScreen extends ConsumerWidget {
  const DeviceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context, ref),
      body: Consumer(
        builder: (context, ref, _) {
          final ble = ref.read(bleServiceProvider);
          
          return StreamBuilder<BluetoothDevice>(
            stream: ble.scanStream,
            builder: (context, snapshot) {
              if (snapshot.hasData && !ble.isConnected) {
                return _buildDeviceFoundCard(context, ref, snapshot.data!);
              }
              
              return _buildMainContent(context, ref);
            },
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, WidgetRef ref) {
    final ble = ref.read(bleServiceProvider);
    return AppBar(
      title: const Text('SpeedCoach'),
      actions: [
        Consumer(
          builder: (context, ref, _) {
            return StreamBuilder<bool>(
              stream: ble.connectionStream,
              initialData: false,
              builder: (context, snapshot) {
                final connected = snapshot.data ?? false;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Center(
                    child: ConnectionStatusIndicator(
                      connected: connected,
                      deviceName: connected ? ble.connectedDevice?.name : null,
                      onTap: connected ? () => _showDisconnectDialog(context, ref) : null,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildDeviceFoundCard(BuildContext context, WidgetRef ref, BluetoothDevice device) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withValues(alpha: 0.05),
            Colors.white,
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Card(
            elevation: 8,
            shadowColor: AppColors.primary.withValues(alpha: 0.2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 360),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    AppColors.primary.withValues(alpha: 0.02),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.bluetooth_searching, size: 56, color: Colors.white),
                  ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                  const SizedBox(height: 24),
                  const Text(
                    'SpeedCoach détecté',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.5),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.2),
                  const SizedBox(height: 8),
                  Text(
                    device.name,
                    style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                  ).animate().fadeIn(duration: 400.ms, delay: 300.ms).slideY(begin: 0.2),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    icon: const Icon(Icons.bluetooth_connected),
                    label: const Text('Se connecter'),
                    onPressed: () => _connectDevice(context, ref, device),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ).animate().fadeIn(duration: 400.ms, delay: 400.ms).slideY(begin: 0.3),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, WidgetRef ref) {
    final ble = ref.read(bleServiceProvider);
    
    return StreamBuilder<bool>(
      stream: ble.connectionStream,
      initialData: false,
      builder: (context, snapshot) {
        final connected = snapshot.data ?? false;
        
        if (!connected) {
          return _buildDisconnectedView(context);
        }
        
        return _buildConnectedView(context, ref);
      },
    );
  }

  Widget _buildDisconnectedView(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withValues(alpha: 0.03),
            Colors.white,
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Icon(Icons.bluetooth_disabled, size: 72, color: Colors.grey[400]),
              ).animate().shake(duration: 800.ms, curve: Curves.elasticIn),
              const SizedBox(height: 24),
              const Text(
                'Non connecté',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5),
              ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2),
              const SizedBox(height: 12),
              Text(
                'Le SpeedCoach n\'est pas connecté.\nAssurez-vous qu\'il est allumé et à portée.',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary, height: 1.5),
                textAlign: TextAlign.center,
              ).animate().fadeIn(duration: 500.ms, delay: 100.ms).slideY(begin: 0.2),
              const SizedBox(height: 32),
              OutlinedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Rechercher'),
                onPressed: () => _startScan(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideY(begin: 0.3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectedView(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(deviceStatusProvider);
        ref.invalidate(coachConfigProvider);
        ref.invalidate(activityFilesProvider);
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _AnimatedCard(child: const LivePreviewCard()),
                const SizedBox(height: 16),
                _AnimatedCard(child: const DisplayModeSelector()),
                const SizedBox(height: 16),
                _AnimatedCard(child: const DeviceControlButtons()),
                const SizedBox(height: 16),
                _AnimatedCard(child: _buildQuickActions(context, ref)),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Actions rapides', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3))
            .animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _ModernQuickAction(
              icon: Icons.settings_outlined,
              label: 'Réglages',
              gradient: AppColors.primaryGradient,
              onTap: () => _navigateToSettings(context),
            ),
            _ModernQuickAction(
              icon: Icons.list_alt_outlined,
              label: 'Activités',
              gradient: AppColors.secondaryGradient,
              onTap: () => _navigateToActivities(context),
            ),
            _ModernQuickAction(
              icon: Icons.battery_charging_full_outlined,
              label: 'Batterie',
              gradient: AppColors.warningGradient,
              onTap: () => _showBatteryDetail(context, ref),
            ),
            _ModernQuickAction(
              icon: Icons.info_outline,
              label: 'Infos appareil',
              gradient: LinearGradient(
                colors: [AppColors.primary.withValues(alpha: 0.8), AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              onTap: () => _showDeviceInfo(context, ref),
            ),
          ],
        ).animate().fadeIn(duration: 500.ms, delay: 300.ms).slideY(begin: 0.1),
      ],
    );
  }

  void _connectDevice(BuildContext context, WidgetRef ref, BluetoothDevice device) async {
    final ble = ref.read(bleServiceProvider);
    try {
      await ble.connectToDevice(device);
      ref.invalidate(deviceStatusProvider);
      ref.invalidate(coachConfigProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Connecté au SpeedCoach'),
              ],
            ),
            backgroundColor: AppColors.secondary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Erreur connexion: $e')),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  void _startScan(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            SizedBox(width: 12),
            Text('Recherche en cours...'),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showDisconnectDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vous déconnecter du SpeedCoach ?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(bleServiceProvider).disconnect();
            },
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );
  }

  void _navigateToSettings(BuildContext context) {
    DefaultTabController.of(context)?.animateTo(2);
  }

  void _navigateToActivities(BuildContext context) {
    DefaultTabController.of(context)?.animateTo(1);
  }

  void _showBatteryDetail(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batterie'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Consumer(
          builder: (context, ref, _) {
            final batteryAsync = ref.watch(batteryStreamProvider);
            return batteryAsync.when(
              data: (level) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: AppColors.batteryGradient(level),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.batteryColor(level).withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: BatteryIndicator(level: level, size: 80, showPercentage: true),
                  ),
                  const SizedBox(height: 24),
                  Text('Niveau: $level%', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: level / 100,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation(AppColors.batteryColor(level)),
                  ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Erreur: $e'),
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer')),
        ],
      ),
    );
  }

  void _showDeviceInfo(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Informations appareil'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Consumer(
          builder: (context, ref, _) {
            final statusAsync = ref.watch(deviceStatusProvider);
            return statusAsync.when(
              data: (status) {
                if (status == null) return const Center(child: CircularProgressIndicator());
                return ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoRow(icon: Icons.memory, label: 'Firmware', value: status.firmware),
                      _InfoRow(icon: Icons.radio_button_checked, label: 'État', value: _formatState(status.state)),
                      _InfoRow(icon: Icons.battery_full, label: 'Batterie', value: '${status.battery}%'),
                      _InfoRow(icon: Icons.gps_fixed, label: 'GPS', value: status.gpsFix ? 'Fix OK' : 'Recherche...', valueColor: status.gpsFix ? AppColors.secondary : AppColors.warning),
                      _InfoRow(icon: Icons.favorite, label: 'Fréquence cardiaque', value: status.hrConnected ? 'Connectée' : 'Non connectée', valueColor: status.hrConnected ? AppColors.secondary : AppColors.textSecondary),
                      if (status.hrName != null) _InfoRow(icon: Icons.watch, label: 'FC Appareil', value: status.hrName!),
                      _InfoRow(icon: Icons.sensors, label: 'RowPod', value: status.podConnected ? 'Connecté' : 'Non connecté', valueColor: status.podConnected ? AppColors.secondary : AppColors.textSecondary),
                      _InfoRow(icon: Icons.storage, label: 'Stockage', value: '${(status.storageUsed / 1024).toStringAsFixed(1)} KB / ${(status.storageTotal / 1024).toStringAsFixed(1)} KB'),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Erreur: $e'),
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer')),
        ],
      ),
    );
  }

  String _formatState(String state) {
    if (state == DeviceState.idle) return 'Inactif';
    if (state == DeviceState.recording) return 'Enregistrement';
    if (state == DeviceState.paused) return 'En pause';
    return state;
  }
}

class _AnimatedCard extends StatelessWidget {
  final Widget child;
  final int index;

  const _AnimatedCard({required this.child, this.index = 0});

  @override
  Widget build(BuildContext context) {
    return child.animate()
      .fadeIn(duration: 500.ms, delay: (index * 100).ms)
      .slideY(begin: 0.2, duration: 500.ms, delay: (index * 100).ms, curve: Curves.easeOutCubic);
  }
}

class _ModernQuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _ModernQuickAction({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: Colors.white),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 14)),
          ],
        ),
      ),
    ).animate().scale(duration: 200.ms, curve: Curves.easeOutBack);
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: valueColor ?? AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.1);
  }
}