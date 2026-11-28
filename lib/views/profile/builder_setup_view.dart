import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/carps_icons.dart';

import '../../controllers/app_controller.dart';
import '../../core/theme/carps_colors.dart';
import '../../core/widgets/carps_widgets.dart';
import '../../models/carps_models.dart';

/// Figma 11 · Builder Profile Setup (Individual / Group mode).
/// Turns on hosting tools for THIS account; no second account is created.
class BuilderSetupView extends StatefulWidget {
  const BuilderSetupView({super.key});
  @override
  State<BuilderSetupView> createState() => _BuilderSetupViewState();
}

class _BuilderSetupViewState extends State<BuilderSetupView> {
  late final TextEditingController _name;
  late final TextEditingController _about;
  bool _group = false;
  bool _pledge = false;
  late Set<String> _topics;

  @override
  void initState() {
    super.initState();
    final me = context.appRead.me!;
    _name = TextEditingController(text: me.builderName ?? me.displayName);
    _about = TextEditingController(text: me.builderAbout ?? '')
      ..addListener(() => setState(() {}));
    _topics = me.interests.take(3).toSet();
    _pledge = me.hostingEnabled;
  }

  @override
  void dispose() {
    _name.dispose();
    _about.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final me = app.me!;
    final c = context.carps;

    Widget mode(
      bool group,
      IconData icon,
      String title,
      String sub,
      String? tag,
    ) {
      final selected = _group == group;
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Semantics(
          selected: selected,
          button: true,
          child: Material(
            color: selected ? c.muted : c.canvas,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => setState(() => _group = group),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: selected ? c.accentTint : c.muted,
                      child: Icon(
                        icon,
                        color: selected ? c.accentFill : c.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (tag != null) TintPill(tag),
                            ],
                          ),
                          Text(
                            sub,
                            style: TextStyle(
                              fontSize: 12,
                              color: c.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (selected)
                      Icon(CarpsIcons.checkCircleFill, color: c.selectFill),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    void enableHosting() {
      if (runAction(
        context,
        () => app.profiles.enableHosting(
          me.id,
          builderName: _name.text,
          about: _about.text,
        ),
        success: 'Hosting tools are on for this account',
      )) {
        context.pop();
      }
    }

    Widget actionButton() => CarpsButton(
      label: me.hostingEnabled ? 'Save builder profile' : 'Enable hosting',
      trailingArrow: true,
      onPressed: _pledge ? enableHosting : null,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 780;

        Widget modeSection() {
          final individual = mode(
            false,
            CarpsIcons.user,
            'Individual Host',
            'Host sports sessions, food crawls, or pickup games under your name.',
            'Recommended',
          );
          final group = mode(
            true,
            CarpsIcons.usersThree,
            'Group / Guild / Organization',
            'Multi-host meetups and recurring club sessions. Invite co-hosts per event.',
            null,
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    'Select hosting mode',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  Text(
                    'Step 1 of 3',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (desktop)
                Row(
                  children: [
                    Expanded(child: individual),
                    const SizedBox(width: 12),
                    Expanded(child: group),
                  ],
                )
              else ...[
                individual,
                group,
              ],
            ],
          );
        }

        Widget identitySection() => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  _group ? 'Organization identity' : 'Builder identity',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                  'Step 2 of 3',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            FieldLabel(
              _group ? 'Guild / organization name' : 'Builder / squad name',
            ),
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                prefixIcon: Icon(CarpsIcons.identificationBadge, size: 20),
              ),
            ),
            const SizedBox(height: 16),
            FieldLabel(
              'About your community',
              trailing: Text(
                '${_about.text.length}/300',
                style: TextStyle(fontSize: 11, color: c.textSecondary),
              ),
            ),
            TextField(
              controller: _about,
              maxLines: 3,
              maxLength: 300,
              buildCounter: (
                _, {
                required currentLength,
                required isFocused,
                maxLength,
              }) => null,
              decoration: const InputDecoration(
                hintText: 'Weekly pickleball open play and casual coffee runs around High Street.',
              ),
            ),
          ],
        );

        Widget topicsSection() => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const FieldLabel('Primary category / topic (up to 3)'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in kTopics)
                  SelectChip(
                    label: t,
                    selected: _topics.contains(t),
                    onTap: () => setState(() {
                      if (_topics.contains(t)) {
                        _topics.remove(t);
                      } else if (_topics.length < 3) {
                        _topics.add(t);
                      }
                    }),
                  ),
              ],
            ),
          ],
        );

        Widget pledgeSection() => SurfaceCard(
          color: c.muted,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(CarpsIcons.shieldCheck, color: c.success),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Community host guidelines',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  Text(
                    'Step 3 of 3',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Review join requests fairly, scan passes on site so attendance is real, and keep private rosters private.',
                style: TextStyle(fontSize: 12, color: c.textSecondary),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _pledge,
                onChanged: (v) => setState(() => _pledge = v ?? false),
                title: const Text(
                  'I agree to the builder community pledge',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        );

        Widget heroIntro() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TintPill('Are you Game?'),
            const SizedBox(height: 12),
            Text(
              'Become a Community Builder',
              style: TextStyle(
                color: Colors.white,
                fontSize: desktop ? 34 : 26,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Host events, review join requests, and build your crowd from your existing account.',
              style: TextStyle(color: Color(0xFFA3A3A3)),
            ),
          ],
        );

        Widget accountNote() => Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1F1F1F),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(CarpsIcons.starFill, color: c.accentOnInverse),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Walang iwanan! Attendee and host privileges stay in your single CARPS account.',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
        );

        return CarpsPage(
          title: 'Builder setup',
          padding: EdgeInsets.zero,
          maxWidth: desktop ? 1200 : 720,
          bottomBar: desktop ? null : actionButton(),
          children: [
            Container(
              color: const Color(0xFF0A0A0A),
              padding: EdgeInsets.fromLTRB(
                desktop ? 40 : 16,
                24,
                desktop ? 40 : 16,
                40,
              ),
              child: desktop
                  ? Row(
                      children: [
                        Expanded(flex: 6, child: heroIntro()),
                        const SizedBox(width: 40),
                        Expanded(flex: 4, child: accountNote()),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        heroIntro(),
                        const SizedBox(height: 16),
                        accountNote(),
                      ],
                    ),
            ),
            Transform.translate(
              offset: const Offset(0, -24),
              child: Container(
                decoration: BoxDecoration(
                  color: c.page,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(36),
                  ),
                ),
                padding: EdgeInsets.fromLTRB(
                  desktop ? 32 : 16,
                  28,
                  desktop ? 32 : 16,
                  desktop ? 24 : 16,
                ),
                child: desktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 6,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                modeSection(),
                                const SizedBox(height: 16),
                                identitySection(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 28),
                          Expanded(
                            flex: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                topicsSection(),
                                const SizedBox(height: 20),
                                pledgeSection(),
                                const SizedBox(height: 16),
                                actionButton(),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          modeSection(),
                          const SizedBox(height: 16),
                          identitySection(),
                          const SizedBox(height: 16),
                          topicsSection(),
                          const SizedBox(height: 20),
                          pledgeSection(),
                        ],
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}
