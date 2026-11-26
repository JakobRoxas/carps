import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/carps_icons.dart';

import '../../controllers/app_controller.dart';
import '../../core/format.dart';
import '../../core/theme/carps_colors.dart';
import '../../core/widgets/carps_widgets.dart';
import '../../models/carps_models.dart';

const kReportCategories = [
  'Attendance discrepancy',
  'Safety concern',
  'Inappropriate post or comment',
  'Host no-show / sudden cancellation',
  'Account or privacy issue',
  'Something else',
];

/// Figma 22 · Settings and Help, including Settings → Help → report.
class SettingsView extends StatefulWidget {
  const SettingsView({super.key});
  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool _inApp = true;
  bool _emailReminders = false;
  String _category = kReportCategories.first;
  final _link = TextEditingController();
  final _details = TextEditingController();

  @override
  void dispose() {
    _link.dispose();
    _details.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final svc = app.service;
    final me = app.me!;
    final c = context.carps;
    final myReports = svc.casesReportedBy(me.id);

    Widget section(String title, List<Widget> rows, {Widget? trailing}) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Row(children: [
                  CaptionLabel(title),
                  const Spacer(),
                  ?trailing,
                ]),
              ),
              Material(
                color: c.canvas,
                borderRadius: BorderRadius.circular(20),
                clipBehavior: Clip.antiAlias,
                child: Column(children: [
                  for (var i = 0; i < rows.length; i++) ...[
                    rows[i],
                    if (i < rows.length - 1)
                      Divider(height: 1, indent: 64, color: c.borderSubtle),
                  ],
                ]),
              ),
            ],
          ),
        );

    Widget row(IconData icon, String title, String subtitle,
            {VoidCallback? onTap, Widget? trailing}) =>
        ListTile(
          onTap: onTap,
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: c.muted, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 20, color: c.textPrimary),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          trailing: trailing ??
              (onTap == null
                  ? null
                  : Icon(CarpsIcons.caretRight,
                      color: c.textSecondary, size: 18)),
        );

    return Column(children: [
      const CarpsTopBar(),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CaptionLabel('Preferences', color: c.accentFill),
                    Text('Settings & Help',
                        style: Theme.of(context).textTheme.headlineLarge),
                    const SizedBox(height: 16),
                    Material(
                      color: const Color(0xFF0A0A0A),
                      borderRadius: BorderRadius.circular(24),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () => context.go('/profile'),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(children: [
                            CarpsAvatar(user: me, size: 52),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(me.displayName,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600)),
                                  Text(
                                      '${me.handle} · ${me.hostingEnabled ? 'Attendee & Builder' : 'Attendee'}${me.isAdmin ? ' · Admin (assigned)' : ''}',
                                      style: const TextStyle(
                                          color: Color(0xFFA3A3A3),
                                          fontSize: 12)),
                                ],
                              ),
                            ),
                            const CircleAvatar(
                              backgroundColor: Color(0xFF1F1F1F),
                              child: Icon(CarpsIcons.caretRight,
                                  color: Colors.white, size: 18),
                            ),
                          ]),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (me.isAdmin)
                      section('Admin (assigned permission)', [
                        row(
                            CarpsIcons.shieldStar,
                            'Assigned issue reports',
                            '${svc.casesFor(me.id).where((x) => x.status == CaseStatus.open).length} open · review and record outcomes',
                            onTap: () => context.push('/admin')),
                      ]),
                    section('Account & profile', [
                      row(CarpsIcons.identificationCard,
                          'Edit personal profile', 'Photo, name, bio and username',
                          onTap: () => context.push('/edit-profile')),
                      row(CarpsIcons.mapPin, 'Interests & city / area',
                          '${me.area ?? 'No area'} · ${me.interests.take(3).join(', ')}',
                          onTap: () => context.push('/edit-profile')),
                      row(CarpsIcons.usersThree, 'Followed builders',
                          '${me.followingIds.length} following',
                          onTap: () => context.push('/followed')),
                    ]),
                    section('Preferences', [
                      row(CarpsIcons.moon, 'Appearance mode',
                          'Dark mode is a stretch goal for the pilot',
                          trailing: const SimulatedTag(text: 'Coming later')),
                      SwitchListTile(
                        secondary: const Icon(CarpsIcons.bellRinging),
                        title: const Text('In-app notifications',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: const Text(
                            'Requests, approvals, reminders, tags. Device push is a stretch goal.'),
                        value: _inApp,
                        onChanged: (v) => setState(() => _inApp = v),
                      ),
                      SwitchListTile(
                        secondary: const Icon(CarpsIcons.envelope),
                        title: Row(children: const [
                          Flexible(
                            child: Text('Reminder emails',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                          SizedBox(width: 8),
                          SimulatedTag(),
                        ]),
                        subtitle: const Text('Opt in to emailed pre-event reminders.'),
                        value: _emailReminders,
                        onChanged: (v) => setState(() => _emailReminders = v),
                      ),
                    ]),
                    section('Privacy & visibility', [
                      row(CarpsIcons.eye, 'Profile visibility',
                          'Posts from private events are only shown to people who attended them'),
                      row(CarpsIcons.shieldCheck,
                          'Data & Philippine DPA rights',
                          'Request export, correction or deletion (simulated)',
                          onTap: () => showCarpsSnack(context,
                              'Data requests are simulated in this build.')),
                    ]),
                    section('Hosting tools', [
                      row(
                          CarpsIcons.lightning,
                          me.hostingEnabled
                              ? 'Builder profile'
                              : 'Enable hosting tools',
                          me.hostingEnabled
                              ? 'Manage "${me.builderName}"'
                              : 'Host events from this same account',
                          onTap: () => context.push('/builder-setup')),
                    ], trailing: me.hostingEnabled ? const TintPill('Host active') : null),
                    section('Help & community safety', [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(children: [
                          CircleAvatar(
                            backgroundColor: c.accentTint,
                            child: Icon(CarpsIcons.asteriskFill, color: c.error),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Community safety contact',
                                    style: TextStyle(fontWeight: FontWeight.w600)),
                                SelectableText('carpscocustomerservice@gmail.com',
                                    style: TextStyle(fontSize: 12)),
                                SelectableText('09344238977',
                                    style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                        ]),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(children: [
                              Icon(CarpsIcons.warningCircle,
                                  color: c.accentFill),
                              const SizedBox(width: 8),
                              Text('Report an issue',
                                  style: Theme.of(context).textTheme.titleMedium),
                            ]),
                            const SizedBox(height: 4),
                            Text(
                                'Goes to an assigned CARPS admin. They review only what\'s needed and let you know the outcome.',
                                style: Theme.of(context).textTheme.bodySmall),
                            const SizedBox(height: 12),
                            const FieldLabel('Category'),
                            DropdownButtonFormField<String>(
                              initialValue: _category,
                              isExpanded: true,
                              items: [
                                for (final k in kReportCategories)
                                  DropdownMenuItem(value: k, child: Text(k)),
                              ],
                              onChanged: (v) => setState(() => _category = v!),
                            ),
                            const SizedBox(height: 12),
                            const FieldLabel('Event, post or profile link (optional)'),
                            TextField(
                              controller: _link,
                              decoration: const InputDecoration(
                                  hintText: 'carps.ph/event/ev_pb_past'),
                            ),
                            const SizedBox(height: 12),
                            const FieldLabel('What happened?'),
                            TextField(
                              controller: _details,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                  hintText:
                                      'Provide details so the admin can review and take action…'),
                            ),
                            const SizedBox(height: 12),
                            CarpsButton(
                              label: 'Send report',
                              icon: CarpsIcons.paperPlaneTilt,
                              onPressed: () {
                                if (runAction(
                                    context,
                                    () => svc.reportIssue(
                                        me.id, _category, _details.text,
                                        link: _link.text),
                                    success:
                                        'Report sent to an assigned admin')) {
                                  _details.clear();
                                  _link.clear();
                                }
                              },
                            ),
                            if (myReports.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              const CaptionLabel('Your reports'),
                              for (final r in myReports)
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(r.category),
                                  subtitle: Text(
                                      r.status == CaseStatus.open
                                          ? 'Submitted ${relative(r.createdAt, svc.now)} · under review'
                                          : 'Closed ${relative(r.closedAt!, svc.now)} · ${r.outcome == CaseOutcome.noAction ? 'no changes made' : 'action taken'}',
                                      style: Theme.of(context).textTheme.bodySmall),
                                  trailing: StatusChip(
                                      r.status == CaseStatus.open
                                          ? StatusKind.pending
                                          : StatusKind.ended,
                                      label: r.status == CaseStatus.open
                                          ? 'Open'
                                          : 'Closed'),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ]),
                    CarpsButton(
                      label: 'Log out of ${me.displayName.split(' ').first}\'s account',
                      icon: CarpsIcons.signOut,
                      kind: CarpsButtonKind.secondary,
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final router = GoRouter.of(context);
                        try {
                          await app.signOut();
                          if (mounted) router.go('/login');
                        } on FirebaseAuthException catch (error) {
                          if (mounted) {
                            messenger.showSnackBar(SnackBar(
                                content: Text(error.message ??
                                    'Could not sign out. Please try again.')));
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    const CarpsCopyright(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ]);
  }
}
