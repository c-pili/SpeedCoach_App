import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:io';
import 'dart:typed_data';

import '../../core/services/providers.dart';
import '../../core/models/device_models.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/date_time.dart';
import '../../shared/widgets/common_widgets.dart';
import '../../shared/widgets/modern_widgets.dart';
import '../../shared/theme/app_theme.dart';

class ActivitiesScreen extends ConsumerWidget {
  const ActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ModernGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: ModernAppBar(
          title: 'Activités',
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
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: GradientCard(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white,
                            AppColors.primary.withValues(alpha: 0.02),
                          ],
                        ),
                        padding: const EdgeInsets.all(32),
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        borderRadius: 24,
                        animate: true,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(28),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(28),
                              ),
                              child: Icon(Icons.folder_open, size: 72, color: Colors.grey[400]),
                            ).animate().shake(duration: 800.ms, curve: Curves.elasticIn),
                            const SizedBox(height: 24),
                            const Text(
                              'Aucune activité',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.5),
                            ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2),
                            const SizedBox(height: 12),
                            Text(
                              'Connectez votre SpeedCoach et lancez une séance pour voir vos activités ici.',
                              style: TextStyle(fontSize: 16, color: AppColors.textSecondary, height: 1.5),
                              textAlign: TextAlign.center,
                            ).animate().fadeIn(duration: 500.ms, delay: 100.ms).slideY(begin: 0.2),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                
                return RefreshIndicator(
                  onRefresh: () => ref.read(activityFilesProvider.notifier).refresh(),
                  child: AnimatedStaggeredList(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    spacing: 12,
                    children: files.asMap().entries.map((entry) {
                      return ActivityListTile(file: entry.value, animationIndex: entry.key);
                    }).toList(),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: GradientCard(
                  gradient: AppColors.errorGradient,
                  padding: const EdgeInsets.all(24),
                  margin: const EdgeInsets.all(32),
                  borderRadius: 16,
                  animate: true,
                  child: ErrorBanner(
                    message: 'Erreur chargement: $e',
                    onRetry: () => ref.invalidate(activityFilesProvider),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class ActivityListTile extends ConsumerWidget {
  final ActivityFile file;
  final int animationIndex;

  const ActivityListTile({super.key, required this.file, this.animationIndex = 0});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typeIcon = _getTypeIcon(file.type);
    final typeColor = _getTypeColor(file.type);
    
    return GradientCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white,
          typeColor.withValues(alpha: 0.02),
        ],
      ),
      padding: const EdgeInsets.all(16),
      margin: EdgeInsets.zero,
      borderRadius: 16,
      onTap: () => _viewActivity(context, ref),
      animate: true,
      animationIndex: animationIndex,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  typeColor.withValues(alpha: 0.15),
                  typeColor.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(typeIcon, color: typeColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name.replaceAll('.tcx', '').replaceAll('.csv', ''),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  DateTimeUtils.formatForDisplay(file.date),
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatFileSize(file.size)} • ${file.type.toUpperCase()}' + 
                  (file.sportType != null ? ' • ${file.sportType!}' : ''),
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleAction(context, ref, value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'view', child: Row(children: [Icon(Icons.visibility), SizedBox(width: 8), Text('Voir')])),
              const PopupMenuItem(value: 'export', child: Row(children: [Icon(Icons.share), SizedBox(width: 8), Text('Exporter')])),
              const PopupMenuItem(value: 'strava', child: Row(children: [Icon(Icons.directions_run), SizedBox(width: 8), Text('Strava')])),
              const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: AppColors.error), SizedBox(width: 8), Text('Supprimer', style: TextStyle(color: AppColors.error))])),
            ],
            icon: Icon(Icons.more_vert, color: AppColors.textSecondary.withValues(alpha: 0.6)),
          ),
        ],
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Text('Supprimer ${file.name} ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          GradientButton(
            gradient: AppColors.errorGradient,
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(activityFilesProvider.notifier).deleteFile(file.name);
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
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
    
    return ModernGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: ModernAppBar(
          title: file.name.replaceAll('.tcx', '').replaceAll('.csv', ''),
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
          error: (e, _) => Center(child: GradientCard(
            gradient: AppColors.errorGradient,
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.all(32),
            borderRadius: 16,
            child: ErrorBanner(message: 'Erreur: $e'),
          )),
        ),
      ),
    );
  }

  Widget _buildDetailView(BuildContext context, ActivitySession session) {
    return AnimatedStaggeredList(
      padding: const EdgeInsets.all(16),
      spacing: 16,
      children: [
        _buildSummaryCard(session),
        if (session.strokes.isNotEmpty) _buildStrokeChart(session),
        if (session.splits.isNotEmpty) _buildSplitsTable(session),
        _buildMetadataCard(session),
      ],
    );
  }

  Widget _buildSummaryCard(ActivitySession session) {
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
    );
  }

  Widget _buildSplitsTable(ActivitySession session) {
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
    );
  }

  Widget _buildMetadataCard(ActivitySession session) {
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${session.formattedDuration} • ${session.distanceKm.toStringAsFixed(2)} km'),
          const SizedBox(height: 16),
          GradientCard(
            gradient: AppColors.primaryGradient,
            padding: const EdgeInsets.all(16),
            borderRadius: 12,
            onTap: () => _export(context, ref, SportType.run),
            child: Row(
              children: [
                const Icon(Icons.directions_run, color: Colors.white),
                const SizedBox(width: 12),
                Text('Course à pied', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          GradientCard(
            gradient: AppColors.secondaryGradient,
            padding: const EdgeInsets.all(16),
            borderRadius: 12,
            onTap: () => _export(context, ref, SportType.ride),
            child: Row(
              children: [
                const Icon(Icons.directions_bike, color: Colors.white),
                const SizedBox(width: 12),
                Text('Vélo', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          GradientCard(
            gradient: AppColors.warningGradient,
            padding: const EdgeInsets.all(16),
            borderRadius: 12,
            onTap: () => _export(context, ref, SportType.row),
            child: Row(
              children: [
                const Icon(Icons.pool, color: Colors.white),
                const SizedBox(width: 12),
                Text('Aviron', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          GradientCard(
            gradient: LinearGradient(
              colors: [Colors.teal, Colors.teal[700]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            padding: const EdgeInsets.all(16),
            borderRadius: 12,
            onTap: () => _export(context, ref, SportType.swim),
            child: Row(
              children: [
                const Icon(Icons.pool, color: Colors.white),
                const SizedBox(width: 12),
                Text('Natation', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
              ],
            ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
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