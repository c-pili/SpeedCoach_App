import 'package:flutter/material.dart';
import '../../shared/theme/app_theme.dart';

class BatteryIndicator extends StatelessWidget {
  final int level;
  final bool charging;
  final double size;
  final bool showPercentage;

  const BatteryIndicator({
    super.key,
    required this.level,
    this.charging = false,
    this.size = 24,
    this.showPercentage = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.batteryColor(level);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.centerRight,
          children: [
            Container(
              width: size,
              height: size * 0.55,
              decoration: BoxDecoration(
                border: Border.all(color: color, width: 1.5),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (level / 100).clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ),
            ),
            if (charging)
              Positioned(
                right: -size * 0.25,
                child: Icon(
                  Icons.bolt,
                  size: size * 0.5,
                  color: color,
                ),
              ),
          ],
        ),
        if (showPercentage) ...[
          const SizedBox(width: 4),
          Text(
            '$level%',
            style: TextStyle(
              fontSize: size * 0.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ],
    );
  }
}

class ConnectionStatusIndicator extends StatelessWidget {
  final bool connected;
  final String? deviceName;
  final VoidCallback? onTap;

  const ConnectionStatusIndicator({
    super.key,
    required this.connected,
    this.deviceName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.connectionColor(connected).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.connectionColor(connected)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.connectionColor(connected),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              connected ? 'Connecté' : 'Déconnecté',
              style: TextStyle(
                color: AppColors.connectionColor(connected),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            if (deviceName != null && connected) ...[
              const SizedBox(width: 6),
              Text(
                deviceName!,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final String? message;
  final Widget child;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    this.message,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.3),
            child: Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      if (message != null) ...[
                        const SizedBox(height: 16),
                        Text(message!, style: const TextStyle(fontSize: 16)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;
  final VoidCallback? onRetry;

  const ErrorBanner({
    super.key,
    required this.message,
    this.onDismiss,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: AppColors.error.withValues(alpha: 0.1),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.error, fontSize: 14),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: const Text('Réessayer', style: TextStyle(color: AppColors.error)),
            ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close, color: AppColors.error),
            ),
        ],
      ),
    );
  }
}

class FileTransferProgress extends StatelessWidget {
  final String fileName;
  final double progress;
  final bool isComplete;
  final VoidCallback? onCancel;

  const FileTransferProgress({
    super.key,
    required this.fileName,
    required this.progress,
    this.isComplete = false,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    fileName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onCancel != null && !isComplete)
                  IconButton(
                    onPressed: onCancel,
                    icon: const Icon(Icons.cancel, size: 20),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                isComplete ? AppColors.secondary : AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isComplete ? 'Terminé' : '${(progress * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 12,
                color: isComplete ? AppColors.secondary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? valueColor;
  final String? unit;

  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.valueColor,
    this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (icon != null)
          Icon(icon, size: 24, color: AppColors.textSecondary),
        if (icon != null) const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
            if (unit != null) ...[
              const SizedBox(width: 2),
              Text(
                unit!,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}