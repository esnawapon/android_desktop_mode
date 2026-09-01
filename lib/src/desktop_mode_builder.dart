import 'package:flutter/widgets.dart';

import '../android_desktop_mode.dart';

/// Rebuilds when the device enters or leaves desktop mode.
///
/// ```dart
/// DesktopModeBuilder(
///   builder: (context, state) => state.isDesktopMode
///       ? const DesktopLayout()
///       : const PhoneLayout(),
/// )
/// ```
class DesktopModeBuilder extends StatefulWidget {
  /// Creates a widget that rebuilds on desktop-mode changes.
  const DesktopModeBuilder({super.key, required this.builder});

  /// Called with the latest known state. Before the first state arrives it is called with
  /// [DesktopModeState.notDesktop], so the phone layout is what shows first.
  final Widget Function(BuildContext context, DesktopModeState state) builder;

  @override
  State<DesktopModeBuilder> createState() => _DesktopModeBuilderState();
}

class _DesktopModeBuilderState extends State<DesktopModeBuilder> {
  late final Stream<DesktopModeState> _stream = AndroidDesktopMode.stateChanges;

  @override
  Widget build(BuildContext context) => StreamBuilder<DesktopModeState>(
    stream: _stream,
    builder: (BuildContext context, AsyncSnapshot<DesktopModeState> snapshot) =>
        widget.builder(
          context,
          snapshot.data ?? const DesktopModeState.notDesktop(),
        ),
  );
}
