import 'package:flutter/material.dart';
import '../../core/carps_icons.dart';

import '../../controllers/app_controller.dart';
import '../../core/format.dart';
import '../../core/theme/carps_colors.dart';
import '../../core/widgets/carps_widgets.dart';
import '../../models/carps_models.dart';

/// Assigned-admin review (derived; pilot has no moderation dashboard).
/// Settings → Help → report → assigned admin → targeted action or no action
/// → recorded outcome → reporter notified without private details.
class AdminView extends StatelessWidget {
  const AdminView({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final me = app.me!;
    if (!me.isAdmin) {
      return const CarpsPage(title: 'Admin', children: [
        EmptyState(
            title: 'Admin permission required',
            message:
                'Admin is an assigned permission, never something you choose at sign-up.'),
      ]);
    }
    final cases = app.service.casesFor(me.id);
    final open = cases.where((c) => c.status == CaseStatus.open).toList();
    final closed = cases.where((c) => c.status == CaseStatus.closed).toList();
    return CarpsPage(
      title: 'Assigned reports',
      children: [
        Text(
            'Review only the information you need. Admins don\'t decide event admission. That stays with builders.',
            style: TextStyle(color: context.carps.textSecondary)),
        const SizedBox(height: 16),
        Text('Open (${open.length})', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (open.isEmpty)
          const EmptyState(title: 'No open reports', message: 'You\'re all caught up.'),
        for (final c in open) _CaseCard(supportCase: c),
        const SizedBox(height: 24),
        Text('Closed (${closed.length})',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        for (final c in closed) _CaseCard(supportCase: c),
      ],
    );
  }
}

class _CaseCard extends StatefulWidget {
  const _CaseCard({required this.supportCase});
  final SupportCase supportCase;
  @override
  State<_CaseCard> createState() => _CaseCardState();
}

class _CaseCardState extends State<_CaseCard> {
  CaseOutcome _outcome = CaseOutcome.noAction;
  bool _hostConfirmed = false;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final svc = app.service;
    final c = context.carps;
    final sc = widget.supportCase;
    final reporter = svc.repo.user(sc.reporterId);
    final link = svc.parseLink(sc.link);
    final event = link.eventId == null ? null : svc.repo.event(link.eventId!);
    final post = link.postId == null ? null : svc.repo.post(link.postId!);
    final reg = event == null ? null : svc.registrationFor(event.id, sc.reporterId);
    final att = event == null ? null : svc.attendanceFor(event.id, sc.reporterId);
    final closed = sc.status == CaseStatus.closed;

    String outcomeLabel(CaseOutcome o) => switch (o) {
          CaseOutcome.noAction => 'Close without changes',
          CaseOutcome.warnedUser => 'Warn the user involved',
          CaseOutcome.removedPost => 'Remove the linked post',
          CaseOutcome.attendanceCorrected => 'Correct attendance (host confirmed)',
        };

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(sc.category,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              StatusChip(closed ? StatusKind.ended : StatusKind.pending,
                  label: closed ? 'Closed' : 'Open'),
            ]),
            Text(
                'From ${reporter?.displayName} · ${relative(sc.createdAt, svc.now)}',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Text(sc.details),
            if (sc.link != null) ...[
              const SizedBox(height: 8),
              Row(children: [
                Icon(CarpsIcons.link, size: 14, color: c.textSecondary),
                const SizedBox(width: 4),
                Text(sc.link!, style: Theme.of(context).textTheme.bodySmall),
              ]),
            ],
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: c.muted, borderRadius: BorderRadius.circular(14)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CaptionLabel('Linked record (minimum needed)'),
                  const SizedBox(height: 6),
                  if (event == null && post == null)
                    const Text('No CARPS record linked.'),
                  if (event != null) ...[
                    Text('${event.title} · ${shortDate(event.start)}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                        'Host: ${svc.repo.user(event.hostId)?.displayName} · ${event.isPrivate ? 'Private' : 'Public'}',
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 4),
                    Text(
                        'Reporter\'s registration: ${reg?.status.name ?? 'none'} · attendance: ${att == null ? 'not recorded' : 'recorded ${timeOfDay(att.arrivedAt)}'}',
                        style: Theme.of(context).textTheme.bodySmall),
                    Text(
                        'A request or approval is not proof of presence. Confirm with the host before correcting.',
                        style: TextStyle(fontSize: 11, color: c.textSecondary)),
                  ],
                  if (post != null)
                    Text(
                        'Post by ${svc.repo.user(post.authorId)?.displayName}: “${post.body}”'),
                  if (link.postId != null && post == null)
                    const Text('Linked post no longer exists.'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (closed) ...[
              Text('Outcome: ${outcomeLabel(sc.outcome!)}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              Text('Decision note: ${sc.decisionNote}',
                  style: Theme.of(context).textTheme.bodySmall),
              Text('Closed ${relative(sc.closedAt!, svc.now)} · reporter notified',
                  style: Theme.of(context).textTheme.bodySmall),
            ] else ...[
              const CaptionLabel('Decision'),
              RadioGroup<CaseOutcome>(
                groupValue: _outcome,
                onChanged: (v) => setState(() => _outcome = v!),
                child: Column(children: [
                  for (final o in CaseOutcome.values)
                    RadioListTile<CaseOutcome>(
                      contentPadding: EdgeInsets.zero,
                      value: o,
                      enabled: switch (o) {
                        CaseOutcome.removedPost => post != null,
                        CaseOutcome.attendanceCorrected =>
                          event != null && reg?.status == RegistrationStatus.approved && att == null,
                        _ => true,
                      },
                      title: Text(outcomeLabel(o)),
                    ),
                ]),
              ),
              if (_outcome == CaseOutcome.attendanceCorrected)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _hostConfirmed,
                  onChanged: (v) => setState(() => _hostConfirmed = v ?? false),
                  title: Text(
                      'I confirmed the arrival with the host (${event == null ? '' : svc.repo.user(event.hostId)?.displayName})'),
                ),
              TextField(
                controller: _note,
                maxLines: 2,
                decoration: const InputDecoration(
                    hintText: 'Record why you made this decision (required)'),
              ),
              const SizedBox(height: 10),
              CarpsButton(
                label: 'Record decision & notify reporter',
                onPressed: () => runAction(
                  context,
                  () => svc.resolveCase(
                    adminId: app.me!.id,
                    caseId: sc.id,
                    outcome: _outcome,
                    note: _note.text,
                    hostConfirmed: _hostConfirmed,
                  ),
                  success: 'Decision recorded. Reporter notified without private details.',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
