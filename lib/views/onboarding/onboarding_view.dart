import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/carps_icons.dart';

import '../../controllers/app_controller.dart';
import '../../core/theme/carps_colors.dart';
import '../../core/widgets/carps_widgets.dart';
import '../../models/carps_models.dart';

/// First-use setup: Terms → Role → Interests & profile → People.
/// Each step is saved, so a returning user resumes where they left off and a
/// fully set-up user never sees this screen (router redirect).
class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  int? _step;

  int _initialStep(UserProfile me) {
    if (!me.termsAccepted) return 0;
    if (me.primaryRole == null) return 1;
    if (!me.profileComplete) return 2;
    return 3;
  }

  @override
  Widget build(BuildContext context) {
    final me = context.app.me;
    if (me == null) return const SizedBox.shrink();
    final step = _step ??= _initialStep(me);
    void next() => setState(() => _step = step + 1);
    void back() => setState(() => _step = step - 1);
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: switch (step) {
            0 => _TermsStep(onDone: next),
            1 => _RoleStep(onDone: next, onBack: back),
            2 => _ProfileStep(onDone: next, onBack: back),
            _ => _PeopleStep(onBack: back),
          },
        ),
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.step, this.onBack, this.trailing});
  final int step; // 1-based
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.carps;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(children: [
        Row(children: [
          if (onBack != null)
            CircleIconButton(
                icon: CarpsIcons.arrowLeft,
                tooltip: 'Previous step',
                size: 48,
                onPressed: onBack)
          else
            const SizedBox(width: 48),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: c.muted, borderRadius: BorderRadius.circular(999)),
            child: Row(children: [
              Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                      color: c.accentFill, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text('Step $step of 4',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
          ),
          const Spacer(),
          trailing ?? const SizedBox(width: 48),
        ]),
        const SizedBox(height: 16),
        Semantics(
          label: 'Step $step of 4',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: step / 4,
              minHeight: 6,
              backgroundColor: c.muted,
              color: c.selectFill,
            ),
          ),
        ),
      ]),
    );
  }
}

// -----------------------------------------------------------------------------
// Step 1 · Terms, community rules, Philippine Data Privacy Act
// -----------------------------------------------------------------------------

class _TermsStep extends StatefulWidget {
  const _TermsStep({required this.onDone});
  final VoidCallback onDone;
  @override
  State<_TermsStep> createState() => _TermsStepState();
}

class _TermsStepState extends State<_TermsStep> {
  bool _agree = false;

  static const _policies = [
    (
      CarpsIcons.gavel,
      'Terms of Use',
      'Community guidelines and platform standards',
      'CARPS connects people for in-person community events. You are responsible for what you post. Every social post must be about an officially registered CARPS event you attended. Reposts are not available.'
    ),
    (
      CarpsIcons.handshake,
      'Community Rules & Fair Play',
      'Friendly games, mutual respect & no-shows',
      'Be kind, show up when approved or withdraw before the start, respect hosts\' admission decisions, and keep private sessions private. Report problems through Settings → Help.'
    ),
    (
      CarpsIcons.shieldCheck,
      'Philippine Data Privacy (DPA)',
      'Republic Act No. 10173 & attendee privacy',
      'We process your account, interests, area and attendance only to run CARPS. Rosters are visible to the hosting team only. Contact discovery is opt-in. You may request access, correction or deletion of your data.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.carps;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF0A0A0A),
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(36)),
                ),
                padding: EdgeInsets.fromLTRB(
                    16, MediaQuery.paddingOf(context).top + 16, 16, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(CarpsIcons.shieldCheck,
                          color: c.accentOnInverse, size: 20),
                      const SizedBox(width: 8),
                      const Text('ONBOARDING',
                          style: TextStyle(
                              color: Color(0xFFA3A3A3),
                              fontSize: 12,
                              letterSpacing: 0.6,
                              fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: const Color(0xFF1F1F1F),
                            borderRadius: BorderRadius.circular(999)),
                        child: Text('STEP 1 OF 4',
                            style: TextStyle(
                                color: c.accentOnInverse,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      ),
                    ]),
                    const SizedBox(height: 14),
                    Row(children: [
                      for (var i = 0; i < 4; i++)
                        Expanded(
                          child: Container(
                            height: 4,
                            margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
                            decoration: BoxDecoration(
                              color: i == 0
                                  ? c.accentOnInverse
                                  : const Color(0xFF2A2A2A),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                    ]),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                          color: const Color(0xFF2B1609),
                          borderRadius: BorderRadius.circular(999)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                                color: c.accentOnInverse,
                                shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text('Are you Game?',
                            style: TextStyle(
                                color: c.accentOnInverse,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ]),
                    ),
                    const SizedBox(height: 10),
                    const Text('Welcome to CARPS',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.8)),
                    const SizedBox(height: 8),
                    const Text(
                        'Please review and accept our community standards and data privacy terms before you get started.',
                        style: TextStyle(
                            color: Color(0xFFA3A3A3), fontSize: 14, height: 1.4)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    Row(children: [
                      Text('Policies & Guidelines',
                          style: Theme.of(context).textTheme.titleMedium),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                            color: c.borderSubtle,
                            borderRadius: BorderRadius.circular(999)),
                        child: const Text('Required',
                            style: TextStyle(fontSize: 11)),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    for (final p in _policies) ...[
                      SurfaceCard(
                        color: c.muted,
                        onTap: () => showModalBottomSheet<void>(
                          context: context,
                          builder: (_) => Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.$2,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge),
                                const SizedBox(height: 12),
                                Text(p.$4,
                                    style:
                                        Theme.of(context).textTheme.bodyLarge),
                              ],
                            ),
                          ),
                        ),
                        child: Row(children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: c.canvas,
                            child: Icon(p.$1, color: c.textPrimary, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.$2,
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500)),
                                Text(p.$3,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 12, color: c.textSecondary)),
                              ],
                            ),
                          ),
                          Icon(CarpsIcons.caretRight,
                              color: c.textSecondary, size: 18),
                        ]),
                      ),
                      const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 4),
                    SurfaceCard(
                      onTap: () => setState(() => _agree = !_agree),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _agree,
                            onChanged: (v) => setState(() => _agree = v!),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 10),
                                const Text(
                                    'I agree to the CARPS Terms & Privacy Notice',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500)),
                                const SizedBox(height: 4),
                                Text(
                                    'By continuing, you acknowledge our community rules and RA 10173 data handling policies.',
                                    style: TextStyle(
                                        fontSize: 12, color: c.textSecondary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: CarpsButton(
            label: 'Continue',
            trailingArrow: true,
            onPressed: _agree
                ? () {
                    final app = context.appRead;
                    app.service.updateUser(app.me!.copyWith(termsAccepted: true));
                    widget.onDone();
                  }
                : null,
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Step 2 · Role (admin is never offered)
// -----------------------------------------------------------------------------

class _RoleStep extends StatefulWidget {
  const _RoleStep({required this.onDone, required this.onBack});
  final VoidCallback onDone;
  final VoidCallback onBack;
  @override
  State<_RoleStep> createState() => _RoleStepState();
}

class _RoleStepState extends State<_RoleStep> {
  PrimaryRole? _role;

  @override
  void initState() {
    super.initState();
    _role = context.appRead.me?.primaryRole;
  }

  Widget _option(PrimaryRole role, String image, String title, String subtitle) {
    final c = context.carps;
    final selected = _role == role;
    return Semantics(
      selected: selected,
      button: true,
      label: '$title. $subtitle',
      child: Material(
        color: selected ? c.canvas : Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => setState(() => _role = role),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: selected ? c.selectFill : Colors.transparent,
                  width: 2),
            ),
            child: ExcludeSemantics(
              child: Column(children: [
                Image.asset(image, width: 96, height: 96),
                const SizedBox(height: 12),
                Text(title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: c.textSecondary)),
                if (selected) ...[
                  const SizedBox(height: 8),
                  Icon(CarpsIcons.checkCircleFill, color: c.accentFill),
                ],
              ]),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.carps;
    return SafeArea(
      child: Column(children: [
        _StepHeader(step: 2, onBack: widget.onBack),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              const SizedBox(height: 16),
              Text('Choose your role',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 8),
              Text('How do you plan to swim in CARPS?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: c.textSecondary)),
              const SizedBox(height: 24),
              _option(PrimaryRole.attendee, 'assets/images/carp_orange.png',
                  'Community Explorer', 'Attendee · Discover meets, RSVP & catch the wave'),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('or',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12,
                        letterSpacing: 1.2,
                        color: c.textSecondary)),
              ),
              _option(PrimaryRole.builder, 'assets/images/carp_black.png',
                  'Community Builder', 'Host sessions, lead tribes & drop pins'),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(children: [
            CarpsButton(
              label: 'Continue',
              onPressed: _role == null
                  ? null
                  : () {
                      final app = context.appRead;
                      final me = app.me!;
                      app.service.updateUser(me.copyWith(
                        primaryRole: _role,
                        // Builders get hosting tools on this same account.
                        hostingEnabled:
                            _role == PrimaryRole.builder || me.hostingEnabled,
                      ));
                      widget.onDone();
                    },
            ),
            const SizedBox(height: 12),
            Text('You can always change or dual-wield roles later.',
                style: TextStyle(fontSize: 12, color: c.textSecondary)),
          ]),
        ),
      ]),
    );
  }
}

// -----------------------------------------------------------------------------
// Step 3 · Interests, area and profile (Figma 04)
// -----------------------------------------------------------------------------

/// Simulated photo picker: chooses from bundled event images.
Future<String?> pickSamplePhoto(BuildContext context,
    {required List<String> options}) {
  return showModalBottomSheet<String>(
    context: context,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('Choose a photo', style: Theme.of(ctx).textTheme.titleLarge),
            const Spacer(),
            const SimulatedTag(text: 'Simulated upload'),
          ]),
          const SizedBox(height: 4),
          Text('Device photo access is simulated with sample images.',
              style: Theme.of(ctx).textTheme.bodySmall),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final a in options)
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.pop(ctx, a),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(a, width: 88, height: 88, fit: BoxFit.cover),
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _ProfileStep extends StatefulWidget {
  const _ProfileStep({required this.onDone, required this.onBack});
  final VoidCallback onDone;
  final VoidCallback onBack;
  @override
  State<_ProfileStep> createState() => _ProfileStepState();
}

class _ProfileStepState extends State<_ProfileStep> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _username;
  late final TextEditingController _name;
  late final TextEditingController _area;
  late final TextEditingController _bio;
  late Set<String> _interests;
  bool _triedSubmit = false;

  @override
  void initState() {
    super.initState();
    final me = context.appRead.me!;
    _username = TextEditingController(text: me.username)
      ..addListener(() => setState(() {}));
    _name = TextEditingController(text: me.displayName)
      ..addListener(() => setState(() {}));
    _area = TextEditingController(text: me.area ?? '');
    _bio = TextEditingController(text: me.bio)..addListener(() => setState(() {}));
    _interests = {...me.interests};
  }

  @override
  void dispose() {
    _username.dispose();
    _name.dispose();
    _area.dispose();
    _bio.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _triedSubmit = true);
    final ok = _form.currentState!.validate();
    if (!ok || _interests.length < 3) return;
    final app = context.appRead;
    app.service.updateUser(app.me!.copyWith(
      username: _username.text.trim().replaceFirst('@', ''),
      displayName: _name.text.trim(),
      area: _area.text.trim(),
      bio: _bio.text.trim(),
      interests: _interests.toList(),
      profileComplete: true,
      builderName: app.me!.builderName ??
          (app.me!.primaryRole == PrimaryRole.builder ? _name.text.trim() : null),
    ));
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.carps;
    final svc = context.svc;
    final me = context.app.me!;
    final usernameProblem = _username.text.isEmpty
        ? null
        : svc.usernameProblem(_username.text, ownerId: me.id);
    return SafeArea(
      child: Column(
        children: [
          _StepHeader(
            step: 3,
            onBack: widget.onBack,
            trailing: CircleIconButton(
              icon: CarpsIcons.question,
              tooltip: 'Why we ask: interests tune your For You feed',
              size: 48,
              onPressed: () => showCarpsSnack(context,
                  'Interests and area only tune your For You recommendations.'),
            ),
          ),
          Expanded(
            child: Form(
              key: _form,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const TintPill('Personalize'),
                          const SizedBox(width: 8),
                          Text('${_interests.length} selected',
                              style: TextStyle(
                                  fontSize: 11, color: c.textSecondary)),
                        ]),
                        const SizedBox(height: 6),
                        Text('What are you game for?',
                            style: Theme.of(context).textTheme.headlineLarge),
                        const SizedBox(height: 4),
                        Text(
                            'Pick at least 3 interests to tune your hyper-local feed and match with nearby squads.',
                            style: TextStyle(
                                fontSize: 14, color: c.textSecondary)),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final t in kTopics)
                              SelectChip(
                                label: t,
                                selected: _interests.contains(t),
                                onTap: () => setState(() =>
                                    _interests.contains(t)
                                        ? _interests.remove(t)
                                        : _interests.add(t)),
                              ),
                          ],
                        ),
                        if (_triedSubmit && _interests.length < 3)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text('Pick at least 3 interests.',
                                style: TextStyle(color: c.error, fontSize: 12)),
                          ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                  DarkSheet(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
                    child: Builder(builder: (context) {
                      final d = context.carps;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Profile Details',
                              style: Theme.of(context).textTheme.titleLarge),
                          Text('How other CARPS members recognize you',
                              style: TextStyle(
                                  fontSize: 12, color: d.textSecondary)),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                                color: d.inverseRaised,
                                borderRadius: BorderRadius.circular(12)),
                            child: Row(children: [
                              CarpsAvatar(
                                user: me.copyWith(displayName: _name.text),
                                size: 64,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text('Your initials appear on your profile.',
                                    style: TextStyle(color: d.textSecondary)),
                              ),
                            ]),
                          ),
                          const SizedBox(height: 16),
                          FieldLabel('Username',
                              trailing: _username.text.isEmpty
                                  ? null
                                  : Row(mainAxisSize: MainAxisSize.min, children: [
                                      Icon(
                                          usernameProblem == null
                                              ? CarpsIcons.checkCircleFill
                                              : CarpsIcons.warningCircle,
                                          size: 12,
                                          color: usernameProblem == null
                                              ? d.success
                                              : d.error),
                                      const SizedBox(width: 4),
                                      Text(
                                          usernameProblem == null
                                              ? 'Username available'
                                              : 'Not available',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: usernameProblem == null
                                                  ? d.success
                                                  : d.error)),
                                    ])),
                          TextFormField(
                            controller: _username,
                            decoration: const InputDecoration(
                                prefixText: '@', hintText: 'anareyes'),
                            validator: (v) =>
                                svc.usernameProblem(v ?? '', ownerId: me.id),
                          ),
                          const SizedBox(height: 16),
                          const FieldLabel('Display name'),
                          TextFormField(
                            controller: _name,
                            textCapitalization: TextCapitalization.words,
                            decoration:
                                const InputDecoration(hintText: 'Ana Reyes'),
                            validator: (v) => (v ?? '').trim().length < 2
                                ? 'Enter the name people will see.'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          FieldLabel('Area / City',
                              trailing: Text('Optional',
                                  style: TextStyle(
                                      fontSize: 11, color: d.textSecondary))),
                          AreaField(controller: _area),
                          const SizedBox(height: 16),
                          FieldLabel('Short bio',
                              trailing: Text('${_bio.text.length}/120',
                                  style: TextStyle(
                                      fontSize: 11, color: d.textSecondary))),
                          TextFormField(
                            controller: _bio,
                            maxLines: 3,
                            maxLength: 120,
                            buildCounter: (_,
                                    {required currentLength,
                                    required isFocused,
                                    maxLength}) =>
                                null,
                            decoration: const InputDecoration(
                                hintText: 'Always game for pickleball and coffee.'),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                                color: d.inverseRaised.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(CarpsIcons.shieldCheck,
                                    color: d.accentOnInverse, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                      'Your exact location stays hidden. Others only see your preferred area and interests.',
                                      style: TextStyle(
                                          fontSize: 12, color: d.textSecondary)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: CarpsButton(
                label: 'Continue', trailingArrow: true, onPressed: _submit),
          ),
        ],
      ),
    );
  }
}

/// Free-text area with suggestions from [kAreas].
class AreaField extends StatelessWidget {
  const AreaField({super.key, required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      initialValue: controller.value,
      optionsBuilder: (v) => kAreas.where(
          (a) => a.toLowerCase().contains(v.text.toLowerCase())),
      onSelected: (v) => controller.text = v,
      fieldViewBuilder: (context, textController, focus, onSubmit) {
        return TextField(
          controller: textController,
          focusNode: focus,
          onChanged: (v) => controller.text = v,
          decoration: const InputDecoration(
            hintText: 'Bonifacio Global City',
            prefixIcon: Icon(CarpsIcons.mapPin, size: 20),
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// Step 4 · Find people (Figma 05). Contact discovery is opt-in + simulated.
// -----------------------------------------------------------------------------

class _PeopleStep extends StatefulWidget {
  const _PeopleStep({required this.onBack});
  final VoidCallback onBack;
  @override
  State<_PeopleStep> createState() => _PeopleStepState();
}

class _PeopleStepState extends State<_PeopleStep> {
  String _query = '';

  void _finish() {
    final app = context.appRead;
    app.service.updateUser(app.me!.copyWith(discoveryDone: true));
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final me = app.me!;
    final c = context.carps;
    final people = app.service.searchPeople(_query, excludeId: me.id);
    return SafeArea(
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: c.selectFill, borderRadius: BorderRadius.circular(999)),
              child: Text('STEP 4 OF 4',
                  style: TextStyle(
                      color: c.onSelect,
                      fontSize: 10,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 8),
            IconButton(
                tooltip: 'Previous step',
                onPressed: widget.onBack,
                icon: const Icon(CarpsIcons.arrowLeft, size: 18)),
            const Spacer(),
            TextButton(
              onPressed: _finish,
              child: Text('Skip to Home',
                  style: TextStyle(color: c.textSecondary)),
            ),
          ]),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                    color: const Color(0xFF0A0A0A),
                    borderRadius: BorderRadius.circular(28)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFF1F1F1F),
                      child: Icon(CarpsIcons.userPlus,
                          color: c.accentOnInverse),
                    ),
                    const SizedBox(height: 16),
                    const Text('Find people you know',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            height: 1.15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.6)),
                    const SizedBox(height: 10),
                    const Text(
                        'Events are better with friends and fellow players. Connect with builders, organizers and attendees nearby.',
                        style: TextStyle(color: Color(0xFFA3A3A3), height: 1.4)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SurfaceCard(
                color: c.muted,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: c.accentTint,
                          child: Icon(CarpsIcons.addressBook,
                              color: c.accentFill),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Sync contacts to find friends',
                                  style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(
                                  'Opt-in only, under the Philippine DPA. Contacts are never shared or stored publicly.',
                                  style: TextStyle(
                                      fontSize: 12, color: c.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(children: [
                      const SimulatedTag(text: 'Simulated · contacts not read'),
                      const Spacer(),
                      CarpsButton(
                        label: me.contactDiscoveryOptIn
                            ? 'Opted in'
                            : 'Sync contacts',
                        icon: me.contactDiscoveryOptIn
                            ? CarpsIcons.check
                            : CarpsIcons.arrowsClockwise,
                        kind: me.contactDiscoveryOptIn
                            ? CarpsButtonKind.muted
                            : CarpsButtonKind.inverse,
                        height: 44,
                        expand: false,
                        onPressed: () {
                          app.service.updateUser(me.copyWith(
                              contactDiscoveryOptIn:
                                  !me.contactDiscoveryOptIn));
                          showCarpsSnack(
                              context,
                              me.contactDiscoveryOptIn
                                  ? 'Contact discovery turned off'
                                  : 'Opted in. (Simulated: no contacts were accessed.)');
                        },
                      ),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Search by username or name…',
                  prefixIcon: Icon(CarpsIcons.magnifyingGlass, size: 20),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
              const SizedBox(height: 16),
              Text(_query.isEmpty ? 'Suggested for you' : 'Results',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (people.isEmpty)
                const EmptyState(
                    title: 'No one found',
                    message: 'Try another name or @username.'),
              for (final p in people) ...[
                PersonFollowTile(person: p),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: CarpsButton(
              label: 'Explore events', trailingArrow: true, onPressed: _finish),
        ),
      ]),
    );
  }
}

class PersonFollowTile extends StatelessWidget {
  const PersonFollowTile({super.key, required this.person});
  final UserProfile person;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final me = app.me!;
    final c = context.carps;
    final following = me.followingIds.contains(person.id);
    return SurfaceCard(
      padding: const EdgeInsets.all(12),
      onTap: () => context.push('/user/${person.id}'),
      child: Row(children: [
        CarpsAvatar(user: person, size: 48),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(person.displayName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w600)),
              Text(
                  person.hostingEnabled
                      ? 'Builder · ${person.builderName ?? person.handle}'
                      : '${person.handle}${person.area == null ? '' : ' · ${person.area}'}',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: c.textSecondary)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        CarpsButton(
          label: following ? 'Following' : 'Follow',
          icon: following
              ? CarpsIcons.check
              : CarpsIcons.userPlus,
          kind: following ? CarpsButtonKind.muted : CarpsButtonKind.inverse,
          height: 40,
          expand: false,
          onPressed: () =>
              runAction(context, () => app.service.toggleFollow(me.id, person.id)),
        ),
      ]),
    );
  }
}
