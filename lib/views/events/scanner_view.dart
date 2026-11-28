import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/carps_icons.dart';

import '../../controllers/app_controller.dart';
import '../../core/format.dart';
import '../../core/theme/carps_colors.dart';
import '../../core/widgets/carps_widgets.dart';
import '../../models/carps_models.dart';

/// Event-specific QR scanner (derived from Figma 15's scanner card).
/// The camera is SIMULATED: the host picks which pass is "in front of the
/// camera" or types the code. Results come from the real scan rules.
class ScannerView extends StatefulWidget {
  const ScannerView({super.key, required this.eventId});
  final String eventId;
  @override
  State<ScannerView> createState() => _ScannerViewState();
}

class _ScannerViewState extends State<ScannerView> {
  final _code = TextEditingController();
  final _camera = MobileScannerController();
  ScanResult? _result;
  bool _cameraDenied = false;

  @override
  void dispose() {
    _code.dispose();
    _camera.dispose();
    super.dispose();
  }

  void _scan(String token) {
    final app = context.appRead;
    setState(
      () => _result = app.registrations.scan(app.me!.id, widget.eventId, token),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final svc = app.registrations;
    final me = app.me!;
    final event = app.data.eventById(widget.eventId);
    if (event == null || !event.isHostingTeam(me.id)) {
      return const CarpsPage(
        title: 'Scanner',
        children: [
          EmptyState(
            title: 'Hosting team only',
            message: 'Only the builder and accepted co-hosts can scan passes.',
          ),
        ],
      );
    }
    final open = svc.scannerOpen(event);
    final approved = svc
        .registrationsForEvent(event.id)
        .where((r) => r.status == RegistrationStatus.approved)
        .toList();
    final checkedIn = svc.attendanceForEvent(event.id).length;
    // Passes a guest might hold up: this event's passes plus passes for the
    // host's other events (so wrong-event scans can be tried).
    final presentable = app.data.passes.where((p) {
      final e = app.data.eventById(p.eventId);
      return e != null && e.isHostingTeam(me.id) && !e.isEnded(svc.now);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Theme(
          data: Theme.of(context).copyWith(extensions: [CarpsColors.dark]),
          child: Builder(
            builder: (context) {
              final d = context.carps;
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Close scanner',
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(CarpsIcons.x, color: Colors.white),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            const Text(
                              'CHECK-IN SCANNER',
                              style: TextStyle(
                                color: Color(0xFFA3A3A3),
                                fontSize: 11,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              event.title,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TintPill(
                      '$checkedIn of ${approved.length} checked in',
                      icon: CarpsIcons.sealCheckFill,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: AspectRatio(
                      aspectRatio: 1.2,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF161616),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: _resultColor(d) ?? const Color(0xFF2A2A2A),
                            width: 3,
                          ),
                        ),
                        child: !open
                            ? _centerMsg(
                                CarpsIcons.clock,
                                'Scanner closed',
                                event.isCancelled
                                    ? 'This event was cancelled.'
                                    : (event.isEnded(svc.now)
                                          ? 'The event has ended.'
                                          : 'Opens 6 hours before start (${dateTime(event.start)}).'),
                              )
                            : _cameraDenied
                            ? _centerMsg(
                                CarpsIcons.cameraSlash,
                                'Camera permission denied',
                                'Allow camera access in your device settings, or enter the pass code below.',
                              )
                            : _result == null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: MobileScanner(
                                  controller: _camera,
                                  onDetect: (capture) {
                                    final code =
                                        capture.barcodes.first.rawValue;
                                    if (code != null &&
                                        code.isNotEmpty &&
                                        _result == null) {
                                      _scan(code);
                                    }
                                  },
                                ),
                              )
                            : _resultView(context, _result!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const TintPill('Live camera'),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () =>
                            setState(() => _cameraDenied = !_cameraDenied),
                        child: Text(
                          _cameraDenied
                              ? 'Grant camera (simulate)'
                              : 'Simulate camera denied',
                          style: TextStyle(
                            color: d.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (open) ...[
                    const SizedBox(height: 16),
                    if (!_cameraDenied) ...[
                      const CaptionLabel('Passes being presented'),
                      const SizedBox(height: 8),
                      if (presentable.isEmpty)
                        Text(
                          'No passes issued yet.',
                          style: TextStyle(color: d.textSecondary),
                        ),
                      for (final p in presentable)
                        Builder(
                          builder: (context) {
                            final guest = app.data.userById(p.userId);
                            final pe = app.data.eventById(p.eventId)!;
                            final other = p.eventId != event.id;
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CarpsAvatar(user: guest, size: 40),
                              title: Text(
                                guest?.displayName ?? '',
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                '${other ? 'Pass for ${pe.title} (${shortDate(pe.start)})' : 'Pass for this event'}${p.revoked ? ' · withdrawn' : ''}',
                                style: TextStyle(
                                  color: d.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              trailing: CarpsButton(
                                label: 'Scan',
                                icon: CarpsIcons.qrCode,
                                kind: CarpsButtonKind.inverse,
                                height: 36,
                                expand: false,
                                onPressed: () => _scan(p.token),
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 16),
                    ],
                    const CaptionLabel('Or enter the pass code'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _code,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'CARP-…',
                              fillColor: Color(0xFF1F1F1F),
                            ),
                            onSubmitted: _scan,
                          ),
                        ),
                        const SizedBox(width: 8),
                        CarpsButton(
                          label: 'Check',
                          height: 52,
                          expand: false,
                          onPressed: () => _scan(_code.text),
                        ),
                      ],
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Color? _resultColor(CarpsColors d) {
    final r = _result;
    if (r == null) return null;
    return switch (r.outcome) {
      ScanOutcome.checkedIn => d.success,
      ScanOutcome.alreadyCheckedIn => d.accentOnInverse,
      _ => d.error,
    };
  }

  Widget _centerMsg(IconData icon, String title, String body) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 56, color: const Color(0xFFA3A3A3)),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          body,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFFA3A3A3), fontSize: 13),
        ),
      ],
    ),
  );

  Widget _resultView(BuildContext context, ScanResult r) {
    final d = context.carps;
    final guest = r.guest;
    final (IconData icon, String title, String body) = switch (r.outcome) {
      ScanOutcome.checkedIn => (
        CarpsIcons.sealCheckFill,
        'Checked in',
        '${guest?.displayName} · arrived ${timeOfDay(r.arrivedAt!)}',
      ),
      ScanOutcome.alreadyCheckedIn => (
        CarpsIcons.arrowCounterClockwiseFill,
        'Already checked in',
        '${guest?.displayName} arrived at ${timeOfDay(r.arrivedAt!)}. Not counted again.',
      ),
      ScanOutcome.wrongEvent => (
        CarpsIcons.xCircleFill,
        'Wrong event',
        'This pass is for ${r.event?.title ?? 'another event'}. No arrival recorded.',
      ),
      ScanOutcome.invalid => (
        CarpsIcons.xCircleFill,
        'Invalid pass',
        'This code isn\'t a valid pass for this event. No arrival recorded.',
      ),
      ScanOutcome.withdrawn => (
        CarpsIcons.xCircleFill,
        'Pass withdrawn',
        '${guest?.displayName ?? 'This guest'} withdrew. The pass is no longer valid.',
      ),
      ScanOutcome.notAuthorized => (
        CarpsIcons.lockFill,
        'Not authorized',
        'Only the hosting team can scan.',
      ),
      ScanOutcome.outsideWindow => (
        CarpsIcons.clockFill,
        'Scanner closed',
        'Check-in opens 6 hours before start.',
      ),
    };
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (guest != null) CarpsAvatar(user: guest, size: 64),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: _resultColor(d), size: 22),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: _resultColor(d),
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => setState(() => _result = null),
              child: const Text('Scan next'),
            ),
          ],
        ),
      ),
    );
  }
}
