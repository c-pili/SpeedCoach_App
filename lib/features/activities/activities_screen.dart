import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import 'dart:typed_data';
import '../../core/services/providers.dart';
import '../../core/models/device_models.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/date_time.dart';
import '../../shared/widgets/common_widgets.dart';
import '../../shared/theme/app_theme.dart';

class ActivitiesScreen extends ConsumerWidget {
  const ActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activités'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(activityFilesProvider),
          ),
        ],
      ),
      body: Consumer(
        builder: (context, ref, _) {
          final filesAsync = ref.watch(activityFilesProvider);
          
          return filesAsync.when(
            data: (files) {
              if (files.isEmpty) {
                return const EmptyState(
                  icon: Icons.folder_open,
                  title: 'Aucune activité',
                  subtitle: 'Connectez votre SpeedCoach et lancez une séance pour voir vos activités ici.',
                );
              }
              
              return RefreshIndicator(
                onRefresh: () => ref.read(activityFilesProvider.notifier).refresh(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    final file = files[index];
                    return ActivityListTile(file: file);
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: ErrorBanner(
                message: 'Erreur chargement: $e',
                onRetry: () => ref.invalidate(activityFilesProvider),
              ),
            ),
          );
        },
      ),
    );
  }
}

class ActivityListTile extends ConsumerWidget {
  final ActivityFile file;

  const ActivityListTile({super.key, required this.file});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typeIcon = _getTypeIcon(file.type);
    final typeColor = _getTypeColor(file.type);
    
    return Card(
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: typeColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(typeIcon, color: typeColor, size: 24),
        ),
        title: Text(
          file.name.replaceAll('.tcx', '').replaceAll('.csv', ''),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(DateTimeUtils.formatForDisplay(file.date)),
            Text(
              '${_formatFileSize(file.size)} • ${file.type.toUpperCase()}' + 
              (file.sportType != null ? ' • ${file.sportType!}' : ''),
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleAction(context, ref, value),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'view', child: Row(children: [Icon(Icons.visibility), SizedBox(width: 8), Text('Voir')])),
            const PopupMenuItem(value: 'export', child: Row(children: [Icon(Icons.share), SizedBox(width: 8), Text('Exporter')])),
            const PopupMenuItem(value: 'strava', child: Row(children: [Icon(Icons.directions_run), SizedBox(width: 8), Text('Strava')])),
            const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: AppColors.error), SizedBox(width: 8), Text('Supprimer', style: TextStyle(color: AppColors.error))])),
          ],
        ),
        onTap: () => _viewActivity(context, ref),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'tcx': return Icons.map;
      case 'strokes': return Icons.analytics;
      case 'splits': return Icons.timer;
      default: return Icons.insert_drive_file;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'tcx': return AppColors.primary;
      case 'strokes': return AppColors.secondary;
      case 'splits': return AppColors.warning;
      default: return AppColors.textSecondary;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _viewActivity(BuildContext context, WidgetRef ref) {
    ref.read(activitySessionProvider.notifier).loadFromFile(file);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ActivityDetailScreen(file: file)),
    );
  }

  void _handleAction(BuildContext context, WidgetRef ref, String action) async {
    switch (action) {
      case 'view':
        _viewActivity(context, ref);
        break;
      case 'export':
        _exportFile(context, ref);
        break;
      case 'strava':
        _exportToStrava(context, ref);
        break;
      case 'delete':
        _confirmDelete(context, ref);
        break;
    }
  }

  Future<void> _exportFile(BuildContext context, WidgetRef ref) async {
    final ble = ref.read(bleServiceProvider);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Téléchargement'),
        content: Consumer(
          builder: (context, ref, _) {
            return FutureBuilder<Uint8List>(
              future: ble.downloadFile(file.name),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Téléchargement en cours...'),
                    ],
                  );
                }
                if (snapshot.hasError) {
                  return Text('Erreur: ${snapshot.error}');
                }
                return const Text('Prêt à partager');
              },
            );
          },
        ),
      ),
    );

    try {
      final bytes = await ble.downloadFile(file.name);
      final dir = await getTemporaryDirectory();
      final localFile = File('${dir.path}/${file.name}');
      await localFile.writeAsBytes(bytes);
      
      if (context.mounted) {
        Navigator.pop(context);
        await Share.shareXFiles([XFile(localFile.path)], text: 'SpeedCoach Activity');
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur export: $e')),
        );
      }
    }
  }

  Future<void> _exportToStrava(BuildContext context, WidgetRef ref) async {
    final sessionAsync = ref.read(activitySessionProvider.notifier);
    await sessionAsync.loadFromFile(file);
    
    final session = await ref.read(activitySessionProvider.future);
    if (session == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de charger la session')),
        );
      }
      return;
    }

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (ctx) => StravaExportDialog(session: session),
      );
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer'),
        content: Text('Supprimer ${file.name} ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(activityFilesProvider.notifier).deleteFile(file.name);
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

class ActivityDetailScreen extends ConsumerWidget {
  final ActivityFile file;

  const ActivityDetailScreen({super.key, required this.file});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(activitySessionProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(file.name.replaceAll('.tcx', '').replaceAll('.csv', '')),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => _handleAction(context, ref, value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'export', child: Row(children: [Icon(Icons.share), SizedBox(width: 8), Text('Partager')])),
              const PopupMenuItem(value: 'strava', child: Row(children: [Icon(Icons.directions_run), SizedBox(width: 8), Text('Strava')])),
            ],
          ),
        ],
      ),
      body: sessionAsync.when(
        data: (session) {
          if (session == null) {
            return const Center(child: Text('Aucune donnée'));
          }
          return _buildDetailView(context, session);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: ErrorBanner(message: 'Erreur: $e')),
      ),
    );
  }

  Widget _buildDetailView(BuildContext context, ActivitySession session) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(session),
          const SizedBox(height: 16),
          if (session.strokes.isNotEmpty) ...[
            _buildStrokeChart(session),
            const SizedBox(height: 16),
          ],
          if (session.splits.isNotEmpty) ...[
            _buildSplitsTable(session),
            const SizedBox(height: 16),
          ],
          _buildMetadataCard(session),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(ActivitySession session) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _SummaryMetric('Durée', session.formattedDuration, Icons.access_time)),
                Expanded(child: _SummaryMetric('Distance', session.distanceKm.toStringAsFixed(2) + ' km', Icons.straighten)),
                Expanded(child: _SummaryMetric('Allure moy.', session.formattedAvgPace, Icons.timer)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _SummaryMetric('SPM moy.', session.avgSpm.toString(), Icons.repeat)),
                Expanded(child: _SummaryMetric('SPM max', session.maxSpm.toString(), Icons.trending_up)),
                if (session.avgHr != null)
                  Expanded(child: _SummaryMetric('FC moy.', '${session.avgHr} bpm', Icons.favorite, Colors.red)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _SummaryMetric(String label, String value, IconData icon, [Color? color]) {
    return Column(
      children: [
        Icon(icon, color: color ?? AppColors.primary, size: 24),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildStrokeChart(ActivitySession session) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Analyse des coups', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: CustomPaint(
                painter: _StrokeChartPainter(strokes: session.strokes),
                size: Size.infinite,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _LegendItem('SPM', AppColors.warning),
                _LegendItem('FC', Colors.red),
                _LegendItem('Allure', AppColors.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSplitsTable(ActivitySession session) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Splits', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('#')),
                  DataColumn(label: Text('Distance')),
                  DataColumn(label: Text('Temps')),
                  DataColumn(label: Text('Allure')),
                  DataColumn(label: Text('SPM')),
                  DataColumn(label: Text('FC')),
                ],
                rows: session.splits.map((split) => DataRow(cells: [
                  DataCell(Text('${split.index + 1}')),
                  DataCell(Text(DateTimeUtils.formatDistance(split.distanceM))),
                  DataCell(Text(DateTimeUtils.formatDuration(split.durationSec))),
                  DataCell(Text(DateTimeUtils.formatPace(split.avgPaceSecPerKm))),
                  DataCell(Text('${split.avgSpm}')),
                  DataCell(Text(split.avgHr != null ? '${split.avgHr}' : '--')),
                ])).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataCard(ActivitySession session) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Métadonnées', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _InfoRow('ID', session.id),
            _InfoRow('Début', DateTimeUtils.formatForDisplay(session.startTime)),
            _InfoRow('Fin', DateTimeUtils.formatForDisplay(session.endTime)),
            _InfoRow('Type sport', session.sportType.toUpperCase()),
            if (session.deviceName != null) _InfoRow('Appareil', session.deviceName!),
            if (session.firmwareVersion != null) _InfoRow('Firmware', session.firmwareVersion!),
            _InfoRow('Coups', session.strokes.length.toString()),
            _InfoRow('Splits', session.splits.length.toString()),
          ],
        ),
      ),
    );
  }

  void _handleAction(BuildContext context, WidgetRef ref, String action) {
    if (action == 'export') {
      _exportFile(context, ref);
    } else if (action == 'strava') {
      final session = ref.read(activitySessionProvider).value;
      if (session != null) {
        showDialog(context: context, builder: (_) => StravaExportDialog(session: session));
      }
    }
  }

  Future<void> _exportFile(BuildContext context, WidgetRef ref) async {
    final ble = ref.read(bleServiceProvider);
    try {
      final bytes = await ble.downloadFile(file.name);
      final dir = await getTemporaryDirectory();
      final localFile = File('${dir.path}/${file.name}');
      await localFile.writeAsBytes(bytes);
      
      if (context.mounted) {
        await Share.shareXFiles([XFile(localFile.path)], text: 'SpeedCoach Activity');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }
}

class _StrokeChartPainter extends CustomPainter {
  final List<StrokeData> strokes;

  _StrokeChartPainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    if (strokes.length < 2) return;

    final paint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final maxSpm = strokes.map((s) => s.spm).reduce((a, b) => a > b ? a : b).toDouble();
    final minSpm = strokes.map((s) => s.spm).reduce((a, b) => a < b ? a : b).toDouble();
    final spmRange = (maxSpm - minSpm).clamp(1.0, double.infinity);

    final maxHr = strokes.where((s) => s.hr != null && s.hr! > 0).map((s) => s.hr!).reduce((a, b) => a > b ? a : b).toDouble();
    final minHr = strokes.where((s) => s.hr != null && s.hr! > 0).map((s) => s.hr!).reduce((a, b) => a < b ? a : b).toDouble();
    final hrRange = (maxHr - minHr).clamp(1.0, double.infinity);

    final maxPace = strokes.where((s) => s.paceSecPerKm > 0).map((s) => s.paceSecPerKm).reduce((a, b) => a > b ? a : b);
    final minPace = strokes.where((s) => s.paceSecPerKm > 0).map((s) => s.paceSecPerKm).reduce((a, b) => a < b ? a : b);
    final paceRange = (maxPace - minPace).clamp(1.0, double.infinity);

    final pathSpm = Path();
    final pathHr = Path();
    final pathPace = Path();
    bool hasHr = false;
    bool hasPace = false;

    for (int i = 0; i < strokes.length; i++) {
      final x = (i / (strokes.length - 1)) * size.width;
      
      final spmY = size.height - ((strokes[i].spm - minSpm) / spmRange) * size.height * 0.8 - size.height * 0.1;
      if (i == 0) pathSpm.moveTo(x, spmY); else pathSpm.lineTo(x, spmY);

      if (strokes[i].hr != null && strokes[i].hr! > 0) {
        final hrY = size.height - ((strokes[i].hr! - minHr) / hrRange) * size.height * 0.8 - size.height * 0.1;
        if (!hasHr) { pathHr.moveTo(x, hrY); hasHr = true; } else { pathHr.lineTo(x, hrY); }
      }

      if (strokes[i].paceSecPerKm > 0) {
        final paceY = size.height - ((strokes[i].paceSecPerKm - minPace) / paceRange) * size.height * 0.8 - size.height * 0.1;
        if (!hasPace) { pathPace.moveTo(x, paceY); hasPace = true; } else { pathPace.lineTo(x, paceY); }
      }
    }

    paint.color = AppColors.warning;
    canvas.drawPath(pathSpm, paint);
    
    paint.color = Colors.red;
    canvas.drawPath(pathHr, paint);
    
    paint.color = AppColors.primary;
    canvas.drawPath(pathPace, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendItem(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 16, height: 3, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ],
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
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: TextStyle(color: AppColors.textSecondary))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

class StravaExportDialog extends ConsumerWidget {
  final ActivitySession session;

  const StravaExportDialog({super.key, required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: const Text('Exporter vers Strava'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${session.formattedDuration} • ${session.distanceKm.toStringAsFixed(2)} km'),
          const SizedBox(height: 16),
          _SportTile(
            icon: Icons.directions_run,
            label: 'Course à pied',
            onTap: () => _export(context, ref, SportType.run),
          ),
          _SportTile(
            icon: Icons.directions_bike,
            label: 'Vélo',
            onTap: () => _export(context, ref, SportType.ride),
          ),
          _SportTile(
            icon: Icons.pool,
            label: 'Aviron',
            onTap: () => _export(context, ref, SportType.row),
          ),
          _SportTile(
            icon: Icons.pool,
            label: 'Natation',
            onTap: () => _export(context, ref, SportType.swim),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
      ],
    );
  }

  Future<void> _export(BuildContext context, WidgetRef ref, String sportType) async {
    Navigator.pop(context);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Envoi vers Strava...'),
          ],
        ),
      ),
    );

    try {
      final strava = ref.read(stravaServiceProvider);
      final message = await strava.uploadActivity(session, sportType: sportType);
      
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppColors.secondary),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur Strava: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }
}

class _SportTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SportTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      tileColor: AppColors.primary.withValues(alpha: 0.05),
    );
  }
}