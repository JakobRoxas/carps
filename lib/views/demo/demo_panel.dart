import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/carps_icons.dart';

import '../../controllers/app_controller.dart';
import '../../controllers/registration_controller.dart';
import '../../core/format.dart';
import '../../core/theme/carps_colors.dart';
import '../../core/widgets/carps_widgets.dart';
import '../../models/carps_models.dart';
import '../../repositories/mock_carps_repository.dart';

/// Floating "DEMO" tab. Everything in this panel is a testing aid, not part
/// of the product, and every control calls the same service methods (and
/// therefore the same rule checks) as the real UI.
class DemoLauncher extends StatelessWidget {
  const DemoLauncher({super.key, required this.router});
  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      top: MediaQuery.sizeOf(context).height * 0.42,
      child: Semantics(
        button: true,
        label: 'Open demo controls',
        child: Material(
          color: const Color(0xFF3B2F8F),
          borderRadius:
              const BorderRadius.horizontal(right: Radius.circular(12)),
          elevation: 6,
          child: InkWell(
            borderRadius:
                const BorderRadius.horizontal(right: Radius.circular(12)),
            onTap: () {
              final ctx = router.routerDelegate.navigatorKey.currentContext;
              if (ctx == null) return;
              showModalBottomSheet<void>(
                context: ctx,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (_) => DemoPanel(router: router),
              );
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 12),
              child: RotatedBox(
                quarterTurns: 1,
                child: Text('DEMO',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DemoPanel extends StatefulWidget {
  const DemoPanel({super.key, required this.router});
  final GoRouter router;

  @override
  State<DemoPanel> createState() => _DemoPanelState();
}

class _DemoPanelState extends State<DemoPanel> {
  String? _scanEventId;
  String? _lastResult;

  static const _roles = {
    DemoIds.mika: 'Builder · hosts both communities',
    DemoIds.ana: 'Guest · checks in, posts',
    DemoIds.sofia: 'Guest · checked-in peer',
    DemoIds.paolo: 'Guest · approved no-show',
    DemoIds.marco: 'Guest · request gets declined',
    DemoIds.bea: 'Outsider · follows Mika',
    DemoIds.david: 'Builder · co-host / invited guest',
    DemoIds.sam: 'Assigned admin permission',
  };

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final eventController = app.events;
    final registrationController = app.registrations;
    final c = context.carps;
    final events = app.data.events.toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    final openEvents = events.where((e) => !e.isEnded(eventController.now)).toList();
    // The selected event may have just been ended from this panel.
    if (!openEvents.any((e) => e.id == _scanEventId)) _scanEventId = null;
    _scanEventId ??= openEvents
        .where(registrationController.scannerOpen)
        .map((e) => e.id)
        .firstOrNull;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          Row(children: [
            const Icon(CarpsIcons.flask, color: Color(0xFF3B2F8F)),
            const SizedBox(width: 8),
            Text('Demo controls', style: Theme.of(context).textTheme.titleLarge),
            const Spacer(),
            const SimulatedTag(text: 'Not part of the app'),
          ]),
          const SizedBox(height: 6),
          Text(
              'Testing aids for the pilot review. Each control runs the same rule checks as the real screens.',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 20),
          const CaptionLabel('1 · Switch user'),
          const SizedBox(height: 8),
          for (final id in _roles.keys)
            if (app.data.userById(id) case final u?)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CarpsAvatar(user: u, size: 36),
                title: Text(u.displayName),
                subtitle: Text(_roles[id]!),
                trailing: app.currentUserId == id
                    ? const StatusChip(StatusKind.approved, label: 'Signed in')
                    : null,
                onTap: () {
                  ScaffoldMessenger.maybeOf(context)?.clearSnackBars();
                  app.signIn(id);
                  Navigator.pop(context);
                  widget.router.go('/home');
                },
              ),
          const Divider(height: 32),
          const CaptionLabel('2 · Simulate a pass scan (as the event host)'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _scanEventId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Scanner for event'),
            items: [
              for (final e in openEvents)
                DropdownMenuItem(
                  value: e.id,
                  child: Text(
                      '${e.title} · ${shortDate(e.start)}${registrationController.scannerOpen(e) ? '' : ' (scanner closed)'}',
                      overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (v) => setState(() => _scanEventId = v),
          ),
          const SizedBox(height: 8),
          if (_scanEventId != null) ...[
            Text('Present a pass:', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in app.data.passes.where((p) {
                  final passEvent = app.data.eventById(p.eventId);
                  return passEvent != null && !passEvent.isEnded(eventController.now);
                }))
                  ActionChip(
                    label: Text(
                        '${app.data.userById(p.userId)?.displayName} · ${p.eventId == _scanEventId ? 'this event' : 'other event'}${p.revoked ? ' (revoked)' : ''}'),
                    onPressed: () => _scan(registrationController, eventController.eventById(_scanEventId!)!, p.token),
                  ),
                ActionChip(
                  avatar: const Icon(CarpsIcons.question, size: 16),
                  label: const Text('Unknown code'),
                  onPressed: () => _scan(registrationController, eventController.eventById(_scanEventId!)!, 'CARP-UNKNOWN-0000'),
                ),
              ],
            ),
          ],
          if (_lastResult != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: c.muted, borderRadius: BorderRadius.circular(12)),
              child: Text(_lastResult!),
            ),
          ],
          const Divider(height: 32),
          const CaptionLabel('3 · Advance an event to "ended"'),
          const SizedBox(height: 4),
          Text(
              'Moves the end time to now, exactly as if time had passed. Attendance and eligibility are not touched.',
              style: Theme.of(context).textTheme.bodySmall),
          for (final e in openEvents.where((e) => !e.isCancelled))
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(e.title),
              subtitle: Text(
                  '${dateTime(e.start)}${e.isPrivate ? ' · Private' : ''} · ${registrationController.attendanceForEvent(e.id).length} checked in'),
              trailing: TextButton(
                onPressed: () {
                  registrationController.endEventNow(e.id);
                  showCarpsSnack(context, '${e.title} has ended');
                  setState(() {});
                },
                child: const Text('End now'),
              ),
            ),
          const Divider(height: 32),
          const CaptionLabel('4 · Failure states'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Simulate failed lookups'),
            subtitle: const Text(
                'Attendance history and the post event picker show their failure state.'),
            value: app.simulateLookupFailure,
            onChanged: app.setSimulateFailure,
          ),
          const SizedBox(height: 8),
          CarpsButton(
            label: 'Sign out',
            kind: CarpsButtonKind.secondary,
            height: 44,
            onPressed: () {
              app.signOut();
              Navigator.pop(context);
              widget.router.go('/login');
            },
          ),
        ],
      ),
    );
  }

  void _scan(RegistrationController controller, CarpsEvent event, String token) {
    final r = controller.scan(event.hostId, event.id, token);
    setState(() => _lastResult = describeScan(r));
  }
}

String describeScan(ScanResult r) {
  final name = r.guest?.displayName ?? 'Unknown guest';
  return switch (r.outcome) {
    ScanOutcome.checkedIn =>
      '✅ Checked in: $name at ${timeOfDay(r.arrivedAt!)}. Arrival recorded.',
    ScanOutcome.alreadyCheckedIn =>
      '↩ Already checked in: $name arrived at ${timeOfDay(r.arrivedAt!)}. Not counted again.',
    ScanOutcome.wrongEvent =>
      '⛔ Wrong event: this pass belongs to ${r.event?.title ?? 'another event'}. No arrival recorded.',
    ScanOutcome.invalid => '⛔ Invalid pass. No arrival recorded.',
    ScanOutcome.withdrawn =>
      '⛔ Withdrawn: $name withdrew, so this pass is no longer valid.',
    ScanOutcome.notAuthorized =>
      '⛔ Only the hosting team can scan for this event.',
    ScanOutcome.outsideWindow =>
      '⏸ Scanner is closed (opens 6h before start, closes at the end).',
  };
}
