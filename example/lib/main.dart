import 'dart:convert';

import 'package:android_desktop_mode/android_desktop_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const ExampleApp());

/// Demo app for the `android_desktop_mode` plugin.
class ExampleApp extends StatelessWidget {
  /// Creates the demo app.
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Desktop mode',
    theme: ThemeData(colorSchemeSeed: Colors.indigo),
    darkTheme: ThemeData(
      colorSchemeSeed: Colors.indigo,
      brightness: Brightness.dark,
    ),
    home: const HomePage(),
  );
}

/// Shows the live desktop-mode state and every signal behind it.
class HomePage extends StatefulWidget {
  /// Creates the page.
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DesktopModeState _state = const DesktopModeState.notDesktop();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    AndroidDesktopMode.stateChanges.listen(_apply, onError: (Object _) {});
  }

  Future<void> _load() async {
    try {
      _apply(await AndroidDesktopMode.getState());
    } on Object {
      // No Android implementation behind the channel (a test host, for instance).
      _apply(const DesktopModeState.notDesktop());
    }
  }

  void _apply(DesktopModeState state) {
    if (!mounted) return;
    setState(() {
      _state = state;
      _loading = false;
    });
  }

  Future<void> _copyReport() async {
    await Clipboard.setData(
      ClipboardData(
        text: const JsonEncoder.withIndent('  ').convert(_state.toMap()),
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Signals copied — paste them into a device report.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final signals = _state.signals;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Desktop mode'),
        actions: <Widget>[
          IconButton(
            onPressed: _copyReport,
            icon: const Icon(Icons.copy_all),
            tooltip: 'Copy signals',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                _Verdict(state: _state),
                const SizedBox(height: 16),
                _Section(
                  title: 'Reasons',
                  child: _state.reasons.isEmpty
                      ? const Text('No desktop-mode signal fired.')
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            for (final String reason in _state.reasons)
                              Chip(label: Text(reason)),
                          ],
                        ),
                ),
                _Section(
                  title: 'Vendor',
                  child: Column(
                    children: <Widget>[
                      _SignalTile(
                        'Samsung DeX APIs available',
                        signals.samsungDexAvailable,
                      ),
                      _SignalTile(
                        'Samsung DeX enabled',
                        signals.samsungDexEnabled,
                      ),
                      _ValueTile(
                        'DeX display type',
                        signals.samsungDexDisplayType.name,
                      ),
                      _SignalTile('ChromeOS (ARC)', signals.isChromeOs),
                      _SignalTile(
                        'Vendor desktop probe hit',
                        signals.vendorDesktopActive,
                      ),
                      _ValueTile('Vendor probe', signals.vendorProbe ?? '—'),
                      _ValueTile(
                        'Vendor desktop features',
                        signals.vendorDesktopFeatures.isEmpty
                            ? '—'
                            : signals.vendorDesktopFeatures.join('\n'),
                      ),
                    ],
                  ),
                ),
                _Section(
                  title: 'Windowing',
                  child: Column(
                    children: <Widget>[
                      _SignalTile('Freeform window', signals.inFreeformWindow),
                      _SignalTile(
                        'System caption bar',
                        signals.captionBarVisible,
                      ),
                      _SignalTile('Desk UI mode', signals.isDeskUiMode),
                      _SignalTile('Multi-window', signals.inMultiWindow),
                      _SignalTile(
                        'Supports freeform windows',
                        signals.supportsFreeformWindows,
                      ),
                      _SignalTile('PC device type', signals.isPcDeviceType),
                    ],
                  ),
                ),
                _Section(
                  title: 'Displays and input',
                  child: Column(
                    children: <Widget>[
                      _SignalTile(
                        'Running on external display',
                        signals.onExternalDisplay,
                      ),
                      _ValueTile(
                        'External displays',
                        '${signals.externalDisplayCount}',
                      ),
                      _SignalTile(
                        'Hardware keyboard',
                        signals.hasHardwareKeyboard,
                      ),
                      _SignalTile(
                        'Mouse or trackpad',
                        signals.hasPointerDevice,
                      ),
                    ],
                  ),
                ),
                _Section(
                  title: 'Device',
                  child: Column(
                    children: <Widget>[
                      _ValueTile('Manufacturer', signals.manufacturer),
                      _ValueTile('Brand', signals.brand),
                      _ValueTile('Model', signals.model),
                      _ValueTile('SDK', '${signals.sdkInt}'),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _Verdict extends StatelessWidget {
  const _Verdict({required this.state});

  final DesktopModeState state;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool isDesktop = state.isDesktopMode;
    return Card(
      color: isDesktop
          ? colors.primaryContainer
          : colors.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: <Widget>[
            Icon(
              isDesktop ? Icons.desktop_windows : Icons.smartphone,
              size: 44,
              color: isDesktop
                  ? colors.onPrimaryContainer
                  : colors.onSurfaceVariant,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    isDesktop ? 'Desktop mode' : 'Not desktop mode',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${state.implementation.name} · ${state.confidence.name} confidence',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(padding: const EdgeInsets.all(12), child: child),
        ),
      ],
    ),
  );
}

class _SignalTile extends StatelessWidget {
  const _SignalTile(this.label, this.value);

  final String label;
  final bool value;

  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    contentPadding: EdgeInsets.zero,
    leading: Icon(
      value ? Icons.check_circle : Icons.remove_circle_outline,
      color: value ? Colors.green : Theme.of(context).disabledColor,
    ),
    title: Text(label),
  );
}

class _ValueTile extends StatelessWidget {
  const _ValueTile(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    subtitle: Text(value),
  );
}
