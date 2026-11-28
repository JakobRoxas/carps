import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/carps_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../controllers/app_controller.dart';
import '../../core/format.dart';
import '../../core/theme/carps_colors.dart';
import '../../core/theme/carps_theme.dart';
import '../../core/widgets/carps_widgets.dart';
import '../../models/carps_models.dart';

/// Figma 25 · Guest QR Pass. Unique to this guest and this event.
class PassView extends StatelessWidget {
  const PassView({super.key, required this.eventId});
  final String eventId;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final svc = app.registrations;
    final me = app.me!;
    final event = app.data.eventById(eventId);
    final pass = svc.passFor(eventId, me.id);
    final reg = svc.registrationFor(eventId, me.id);
    final att = svc.attendanceFor(eventId, me.id);
    final light = CarpsColors.light;

    Widget body;
    if (event == null || pass == null) {
      final reason = switch (reg?.status) {
        RegistrationStatus.pending =>
          'Your request is still pending. Passes are issued only after the host approves.',
        RegistrationStatus.declined =>
          'The host declined this request, so no pass was issued.',
        RegistrationStatus.withdrawn =>
          'You withdrew, so your pass is no longer valid.',
        _ => event?.isCancelled == true
            ? 'This event was cancelled. Passes no longer work.'
            : 'You don\'t have a pass for this event.',
      };
      body = Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          const Icon(CarpsIcons.ticket, size: 56, color: Color(0xFFA3A3A3)),
          const SizedBox(height: 12),
          const Text('No pass',
              style: TextStyle(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(reason,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFA3A3A3))),
        ]),
      );
    } else {
      body = Column(children: [
        HighlightCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                att != null
                    ? StatusChip(StatusKind.checkedIn,
                        label: 'Checked in · ${timeOfDay(att.arrivedAt)}')
                    : const StatusChip(StatusKind.approved),
                const Spacer(),
                Text('TICKET #${pass.id.split('_').last.padLeft(3, '0')}',
                    style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 0.4,
                        color: light.textSecondary)),
              ]),
              const SizedBox(height: 16),
              Text(event.title,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Row(children: [
                Icon(CarpsIcons.clock,
                    size: 16, color: light.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                    child: Text(timeRange(event.start, event.end),
                        style: TextStyle(color: light.textSecondary))),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                Icon(CarpsIcons.mapPin,
                    size: 16, color: light.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                    child: Text(event.venue,
                        style: TextStyle(color: light.textSecondary))),
              ]),
              const SizedBox(height: 20),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20)),
                  child: Semantics(
                    label: 'QR pass code for ${me.displayName}',
                    child: QrImageView(
                      data: pass.token,
                      size: 220,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square, color: Color(0xFF0A0A0A)),
                      dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Color(0xFF0A0A0A)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${me.displayName} (${me.handle})',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600)),
                      SelectableText(pass.token,
                          style: TextStyle(
                              fontSize: 11,
                              letterSpacing: 0.4,
                              color: light.textSecondary,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ])),
                    ],
                  ),
                ),
                Opacity(
                  opacity: 0.25,
                  child: Image.asset('assets/images/carp_orange.png',
                      width: 64, height: 64),
                ),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 16),
        CarpsButton(
          label: 'Add to calendar',
          icon: CarpsIcons.calendarPlus,
          kind: CarpsButtonKind.muted,
          onPressed: () =>
              showCarpsSnack(context, 'Calendar export is simulated.'),
        ),
        const SizedBox(height: 12),
        Text(
            att != null
                ? 'Your arrival is recorded. A repeat scan won\'t count twice.'
                : 'Show this pass to the host at the venue. Approval alone is not attendance; the scan records your arrival.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFA3A3A3), fontSize: 12)),
      ]);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Row(children: [
              CircleIconButton(
                icon: CarpsIcons.x,
                tooltip: 'Close pass',
                background: const Color(0xFF1F1F1F),
                foreground: Colors.white,
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go('/rsvps'),
              ),
              const Expanded(
                child: Text('GUEST PASS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Color(0xFFA3A3A3),
                        letterSpacing: 1.4,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 44),
            ]),
            const SizedBox(height: 16),
            Center(
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Theme(data: carpsDarkTheme, child: body)),
            ),
          ],
        ),
      ),
    );
  }
}
