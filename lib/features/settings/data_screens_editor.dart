import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/device_models.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/providers.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';

class DataScreensEditor extends ConsumerStatefulWidget {
  const DataScreensEditor({super.key});

  @override
  ConsumerState<DataScreensEditor> createState() => _DataScreensEditorState();
}

class _DataScreensEditorState extends ConsumerState<DataScreensEditor> {
  late List<DataScreenConfig> _screens;
  String? _editingScreenId;
  DataScreenConfig? _editingScreen;

  @override
  void initState() {
    super.initState();
    _loadScreens();
  }

  void _loadScreens() {
    final config = ref.read(coachConfigProvider).value;
    if (config != null && config.dataScreens.isNotEmpty) {
      _screens = List.from(config.dataScreens);
    } else {
      _screens = _defaultScreens();
    }
  }

  List<DataScreenConfig> _defaultScreens() {
    return [
      DataScreenConfig(
        id: const Uuid().v4(),
        name: 'Allure / SPM / FC',
        enabled: true,
        windows: [
          DataWindowConfig(metricKey: 'pace', slotIndex: 0, enabled: true, customLabel: 'Allure'),
          DataWindowConfig(metricKey: 'spm', slotIndex: 1, enabled: true, customLabel: 'SPM'),
          DataWindowConfig(metricKey: 'hr', slotIndex: 2, enabled: true, customLabel: 'FC'),
        ],
      ),
      DataScreenConfig(
        id: const Uuid().v4(),
        name: 'Vitesse / Distance / Temps',
        enabled: true,
        windows: [
          DataWindowConfig(metricKey: 'speed', slotIndex: 0, enabled: true, customLabel: 'Vitesse'),
          DataWindowConfig(metricKey: 'distance', slotIndex: 1, enabled: true, customLabel: 'Distance'),
          DataWindowConfig(metricKey: 'time', slotIndex: 2, enabled: true, customLabel: 'Temps'),
        ],
      ),
      DataScreenConfig(
        id: const Uuid().v4(),
        name: 'Graphique Accélération',
        enabled: true,
        windows: [
          DataWindowConfig(metricKey: 'accel_graph', slotIndex: 0, enabled: true, customLabel: 'Accélération'),
          DataWindowConfig(metricKey: 'spm', slotIndex: 1, enabled: true, customLabel: 'SPM'),
          DataWindowConfig(metricKey: 'hr', slotIndex: 2, enabled: true, customLabel: 'FC'),
        ],
      ),
    ];
  }

  void _saveScreens() {
    final config = ref.read(coachConfigProvider).value;
    if (config != null) {
      ref.read(coachConfigProvider.notifier).save(config.copyWith(dataScreens: _screens));
    }
  }

  void _addScreen() {
    final newScreen = DataScreenConfig(
      id: const Uuid().v4(),
      name: 'Nouvel écran ${_screens.length + 1}',
      enabled: true,
      windows: [],
    );
    setState(() => _screens.add(newScreen));
    _saveScreens();
  }

  void _deleteScreen(String id) {
    setState(() => _screens.removeWhere((s) => s.id == id));
    _saveScreens();
  }

  void _toggleScreenEnabled(String id) {
    setState(() {
      final idx = _screens.indexWhere((s) => s.id == id);
      if (idx >= 0) {
        _screens[idx] = _screens[idx].copyWith(enabled: !_screens[idx].enabled);
      }
    });
    _saveScreens();
  }

  void _startEditScreen(DataScreenConfig screen) {
    setState(() {
      _editingScreenId = screen.id;
      _editingScreen = screen;
    });
  }

  void _saveScreenEdit() {
    if (_editingScreen != null) {
      setState(() {
        final idx = _screens.indexWhere((s) => s.id == _editingScreen!.id);
        if (idx >= 0) {
          _screens[idx] = _editingScreen!;
        }
        _editingScreenId = null;
        _editingScreen = null;
      });
      _saveScreens();
    }
  }

  void _cancelScreenEdit() {
    setState(() {
      _editingScreenId = null;
      _editingScreen = null;
    });
  }

  void _addWindowToScreen(String screenId) {
    setState(() {
      final idx = _screens.indexWhere((s) => s.id == screenId);
      if (idx >= 0) {
        final usedSlots = _screens[idx].windows.map((w) => w.slotIndex).toSet();
        int newSlot = 0;
        while (usedSlots.contains(newSlot)) newSlot++;
        final newWindow = DataWindowConfig(
          metricKey: 'pace',
          slotIndex: newSlot,
          enabled: true,
        );
        _screens[idx] = _screens[idx].copyWith(windows: [..._screens[idx].windows, newWindow]);
      }
    });
    _saveScreens();
  }

  void _updateWindow(String screenId, DataWindowConfig window) {
    setState(() {
      final sIdx = _screens.indexWhere((s) => s.id == screenId);
      if (sIdx >= 0) {
        final wIdx = _screens[sIdx].windows.indexWhere((w) => w.metricKey == window.metricKey && w.slotIndex == window.slotIndex);
        if (wIdx >= 0) {
          final newWindows = List<DataWindowConfig>.from(_screens[sIdx].windows);
          newWindows[wIdx] = window;
          _screens[sIdx] = _screens[sIdx].copyWith(windows: newWindows);
        }
      }
    });
    _saveScreens();
  }

  void _deleteWindow(String screenId, DataWindowConfig window) {
    setState(() {
      final sIdx = _screens.indexWhere((s) => s.id == screenId);
      if (sIdx >= 0) {
        _screens[sIdx] = _screens[sIdx].copyWith(
          windows: _screens[sIdx].windows.where((w) => w != window).toList(),
        );
      }
    });
    _saveScreens();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Écrans de données'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addScreen,
            tooltip: 'Ajouter un écran',
          ),
        ],
      ),
      body: ReorderableListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _screens.length,
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (newIndex > oldIndex) newIndex--;
            final item = _screens.removeAt(oldIndex);
            _screens.insert(newIndex, item);
          });
          _saveScreens();
        },
        itemBuilder: (context, index) {
          final screen = _screens[index];
          final isEditing = _editingScreenId == screen.id;
          return _ScreenEditorCard(
            key: ValueKey(screen.id),
            screen: screen,
            isEditing: isEditing,
            editingScreen: isEditing ? _editingScreen : null,
            onEdit: () => _startEditScreen(screen),
            onSave: _saveScreenEdit,
            onCancel: _cancelScreenEdit,
            onDelete: () => _deleteScreen(screen.id),
            onToggleEnabled: () => _toggleScreenEnabled(screen.id),
            onAddWindow: () => _addWindowToScreen(screen.id),
            onUpdateWindow: (w) => _updateWindow(screen.id, w),
            onDeleteWindow: (w) => _deleteWindow(screen.id, w),
            previewWidth: 400,
            previewHeight: 240,
          );
        },
      ),
    );
  }
}

class _ScreenEditorCard extends StatefulWidget {
  final DataScreenConfig screen;
  final bool isEditing;
  final DataScreenConfig? editingScreen;
  final VoidCallback onEdit;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final VoidCallback onDelete;
  final VoidCallback onToggleEnabled;
  final VoidCallback onAddWindow;
  final ValueChanged<DataWindowConfig> onUpdateWindow;
  final ValueChanged<DataWindowConfig> onDeleteWindow;
  final double previewWidth;
  final double previewHeight;

  const _ScreenEditorCard({
    super.key,
    required this.screen,
    required this.isEditing,
    this.editingScreen,
    required this.onEdit,
    required this.onSave,
    required this.onCancel,
    required this.onDelete,
    required this.onToggleEnabled,
    required this.onAddWindow,
    required this.onUpdateWindow,
    required this.onDeleteWindow,
    required this.previewWidth,
    required this.previewHeight,
  });

  @override
  State<_ScreenEditorCard> createState() => _ScreenEditorCardState();
}

class _ScreenEditorCardState extends State<_ScreenEditorCard> {
  late DataScreenConfig _localEditingScreen;
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _localEditingScreen = widget.editingScreen ?? widget.screen;
    _nameController = TextEditingController(text: _localEditingScreen.name);
  }

  @override
  void didUpdateWidget(covariant _ScreenEditorCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isEditing && widget.editingScreen != null) {
      _localEditingScreen = widget.editingScreen!;
      _nameController.text = _localEditingScreen.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _updateLocalScreen(DataScreenConfig updated) {
    setState(() => _localEditingScreen = updated);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayScreen = widget.isEditing ? _localEditingScreen : widget.screen;
    final sortedWindows = List<DataWindowConfig>.from(displayScreen.windows)
      ..sort((a, b) => a.slotIndex.compareTo(b.slotIndex));

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: widget.isEditing ? 8 : 2,
      color: widget.isEditing ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            if (widget.isEditing) ...[
              _buildEditForm(context),
            ] else ...[
              _buildPreview(context, sortedWindows),
              const SizedBox(height: 12),
              _buildWindowList(context, sortedWindows),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final displayScreen = widget.isEditing ? _localEditingScreen : widget.screen;
    return Row(
      children: [
        ReorderableDragStartListener(
          index: 0,
          child: Icon(Icons.drag_indicator, color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayScreen.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${displayScreen.windows.length} fenêtre${displayScreen.windows.length > 1 ? 's' : ''} • ${displayScreen.enabled ? 'Activé' : 'Désactivé'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: displayScreen.enabled ? AppColors.secondary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: displayScreen.enabled,
          onChanged: (_) => widget.onToggleEnabled(),
          activeColor: AppColors.secondary,
        ),
        IconButton(
          icon: Icon(widget.isEditing ? Icons.close : Icons.edit),
          onPressed: widget.isEditing ? widget.onCancel : widget.onEdit,
        ),
        if (widget.isEditing)
          IconButton(
            icon: const Icon(Icons.check, color: AppColors.secondary),
            onPressed: widget.onSave,
          )
        else
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: () => _confirmDelete(context),
          ),
      ],
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cet écran ?'),
        content: Text('L\'écran "${widget.screen.name}" sera supprimé définitivement.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onDelete();
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Nom de l\'écran',
            border: OutlineInputBorder(),
          ),
          onChanged: (v) => _updateLocalScreen(_localEditingScreen.copyWith(name: v)),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: _availableMetrics.map((m) {
            final isUsed = _localEditingScreen.windows.any((w) => w.metricKey == m.key);
            return FilterChip(
              label: Text(m.label),
              selected: isUsed,
              onSelected: (sel) {
                if (sel && !isUsed) {
                  final usedSlots = _localEditingScreen.windows.map((w) => w.slotIndex).toSet();
                  int newSlot = 0;
                  while (usedSlots.contains(newSlot)) newSlot++;
                  setState(() {
                    _localEditingScreen = _localEditingScreen.copyWith(
                      windows: [
                        ..._localEditingScreen.windows,
                        DataWindowConfig(
                          metricKey: m.key,
                          slotIndex: newSlot,
                          enabled: true,
                          customLabel: m.label,
                        ),
                      ],
                    );
                  });
                }
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(onPressed: widget.onCancel, child: const Text('Annuler')),
            const SizedBox(width: 8),
            FilledButton(onPressed: widget.onSave, child: const Text('Enregistrer')),
          ],
        ),
      ],
    );
  }

  Widget _buildPreview(BuildContext context, List<DataWindowConfig> windows) {
    final theme = Theme.of(context);
    final aspectRatio = widget.previewWidth / widget.previewHeight;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Aperçu (400×240)', style: theme.textTheme.labelMedium?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 400),
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[800]!),
              ),
              child: Stack(
                children: [
                  ...windows.map((w) => _buildPreviewWindow(w, widget.previewWidth, widget.previewHeight)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewWindow(DataWindowConfig window, double width, double height) {
    final slotX = (window.slotIndex % 3) * (width / 3);
    final slotY = (window.slotIndex ~/ 3) * (height / 2);
    
    return Positioned(
      left: slotX + 8,
      top: slotY + 8,
      width: (width / 3) - 16,
      height: (height / 2) - 16,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey[700]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              window.customLabel.isEmpty ? _metricLabel(window.metricKey) : window.customLabel,
              style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              _metricSample(window.metricKey),
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  String _metricLabel(String key) {
    switch (key) {
      case 'pace': return 'Allure';
      case 'speed': return 'Vitesse';
      case 'spm': return 'SPM';
      case 'hr': return 'FC';
      case 'distance': return 'Distance';
      case 'time': return 'Temps';
      case 'drive_time': return 'Propulsion';
      case 'recovery_time': return 'Récupération';
      case 'accel_graph': return 'Accélération';
      default: return key;
    }
  }

  String _metricSample(String key) {
    switch (key) {
      case 'pace': return '2:15 /km';
      case 'speed': return '27.0 km/h';
      case 'spm': return '28';
      case 'hr': return '152';
      case 'distance': return '5.24 km';
      case 'time': return '18:45';
      case 'drive_time': return '850 ms';
      case 'recovery_time': return '1.2 s';
      case 'accel_graph': return '█ █ █ ▄ ▄ ▂';
      default: return '--';
    }
  }

  Widget _buildWindowList(BuildContext context, List<DataWindowConfig> windows) {
    if (windows.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.widgets_outlined, size: 48, color: AppColors.textSecondary.withValues(alpha: 0.5)),
              const SizedBox(height: 8),
              Text('Aucune fenêtre', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Ajouter une fenêtre'),
                onPressed: widget.onAddWindow,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        ...windows.asMap().entries.map((entry) {
          final index = entry.key;
          final window = entry.value;
          return _WindowListTile(
            index: index,
            window: window,
            onUpdate: widget.onUpdateWindow,
            onDelete: () => widget.onDeleteWindow(window),
            availableMetrics: _availableMetrics,
          );
        }),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Ajouter une fenêtre'),
          onPressed: widget.onAddWindow,
        ),
      ],
    );
  }
}

class _WindowListTile extends ConsumerStatefulWidget {
  final int index;
  final DataWindowConfig window;
  final ValueChanged<DataWindowConfig> onUpdate;
  final VoidCallback onDelete;
  final List<_MetricOption> availableMetrics;

  const _WindowListTile({
    required this.index,
    required this.window,
    required this.onUpdate,
    required this.onDelete,
    required this.availableMetrics,
  });

  @override
  ConsumerState<_WindowListTile> createState() => _WindowListTileState();
}

class _WindowListTileState extends ConsumerState<_WindowListTile> {
  late DataWindowConfig _window;

  @override
  void initState() {
    super.initState();
    _window = widget.window;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      '#${widget.index + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _window.metricKey,
                    decoration: const InputDecoration(
                      labelText: 'Métrique',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: widget.availableMetrics.map((m) => DropdownMenuItem(
                      value: m.key,
                      child: Text(m.label),
                    )).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _window = _window.copyWith(metricKey: v));
                        widget.onUpdate(_window);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: _window.customLabel,
                    decoration: const InputDecoration(
                      labelText: 'Label (optionnel)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (v) {
                      setState(() => _window = _window.copyWith(customLabel: v));
                      widget.onUpdate(_window);
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: AppColors.error),
                  onPressed: widget.onDelete,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Slot: '),
                DropdownButton<int>(
                  value: _window.slotIndex,
                  items: List.generate(6, (i) => DropdownMenuItem(value: i, child: Text('Slot $i'))),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _window = _window.copyWith(slotIndex: v));
                      widget.onUpdate(_window);
                    }
                  },
                ),
                const SizedBox(width: 16),
                Switch(
                  value: _window.enabled,
                  onChanged: (v) {
                    setState(() => _window = _window.copyWith(enabled: v));
                    widget.onUpdate(_window);
                  },
                  activeColor: AppColors.secondary,
                ),
                const Text('Activé'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricOption {
  final String key;
  final String label;
  final IconData icon;

  const _MetricOption(this.key, this.label, this.icon);
}

const List<_MetricOption> _availableMetrics = [
  _MetricOption('pace', 'Allure', Icons.timer),
  _MetricOption('speed', 'Vitesse', Icons.speed),
  _MetricOption('spm', 'SPM', Icons.repeat),
  _MetricOption('hr', 'Fréquence cardiaque', Icons.favorite),
  _MetricOption('distance', 'Distance', Icons.straighten),
  _MetricOption('time', 'Temps', Icons.access_time),
  _MetricOption('drive_time', 'Temps propulsion', Icons.arrow_upward),
  _MetricOption('recovery_time', 'Temps récupération', Icons.arrow_downward),
  _MetricOption('accel_graph', 'Graphique acc.', Icons.show_chart),
];