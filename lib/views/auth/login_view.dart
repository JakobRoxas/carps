import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../core/carps_icons.dart';

import '../../controllers/app_controller.dart';
import '../../core/theme/carps_colors.dart';
import '../../core/widgets/carps_widgets.dart';
import '../../models/carps_models.dart';
import '../../services/carps_service.dart';

/// Spin the ring once on entry; the wordmark and form stay still.
class _LoginLogo extends StatelessWidget {
  const _LoginLogo();

  @override
  Widget build(BuildContext context) {
    final logo = ClipOval(
      child: Image.asset('assets/images/koi_ring.jpg',
          width: 64, height: 64, semanticLabel: 'CARPS koi ring logo'),
    );
    if (MediaQuery.disableAnimationsOf(context)) return logo;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 750),
      curve: Curves.easeOutCubic,
      child: logo,
      builder: (context, turns, child) => Transform.rotate(
        angle: turns * 2 * math.pi,
        child: child,
      ),
    );
  }
}

/// Figma 01 · Login and Sign-up.
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _signUp = false;
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    final app = context.appRead;
    try {
      final user = _signUp
          ? app.service.signUp(_email.text, _password.text)
          : app.service.logIn(_email.text, _password.text);
      app.signIn(user.id); // router redirects to onboarding or Home
    } on RuleViolation catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _google() async {
    final app = context.appRead;
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => _GoogleChooser(users: app.repo.users),
    );
    if (picked == null || !mounted) return;
    if (picked == '__new__') {
      final user = app.service.signUp(
          'newmember${app.repo.users.length}@gmail.com', 'carps-google-sim');
      app.signIn(user.id);
    } else {
      app.signIn(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.carps;
    return Scaffold(
      backgroundColor: c.page,
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                Container(
                  color: c.canvas,
                  width: double.infinity,
                  padding: EdgeInsets.only(
                      top: MediaQuery.paddingOf(context).top + 16, bottom: 24),
                  child: Column(
                    children: [
                      const _LoginLogo(),
                      const SizedBox(height: 12),
                      const CarpsWordmark(size: 32),
                      const SizedBox(height: 6),
                      Text('Are you Game? Find your crowd here.',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: c.textSecondary)),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 35),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 320),
                          child: SegmentedTabs(
                            labels: const ['Log in', 'Sign up'],
                            selected: _signUp ? 1 : 0,
                            onChanged: (i) => setState(() {
                              _signUp = i == 1;
                              _error = null;
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                DarkSheet(
                  roundBottom: MediaQuery.sizeOf(context).width > 480,
                  padding: const EdgeInsets.fromLTRB(16, 28, 16, 40),
                  child: Builder(builder: (context) {
                    final d = context.carps;
                    return Form(
                      key: _form,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Material(
                            color: d.inverseRaised,
                            shape: const StadiumBorder(),
                            child: InkWell(
                              customBorder: const StadiumBorder(),
                              onTap: _google,
                              child: SizedBox(
                                height: 48,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SvgPicture.asset('assets/images/google_g.svg',
                                        width: 20, height: 20),
                                    const SizedBox(width: 12),
                                    const Text('Continue with Google',
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white)),
                                    const SizedBox(width: 8),
                                    const SimulatedTag(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Row(children: [
                              Expanded(child: Divider(color: d.inverseRaised)),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Text('or with email',
                                    style: TextStyle(
                                        fontSize: 12, color: d.textSecondary)),
                              ),
                              Expanded(child: Divider(color: d.inverseRaised)),
                            ]),
                          ),
                          const FieldLabel('Email'),
                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            textInputAction: TextInputAction.next,
                            style: const TextStyle(fontSize: 14),
                            decoration: const InputDecoration(
                              hintText: 'ana.reyes@example.com',
                              prefixIcon: Icon(CarpsIcons.envelopeSimple,
                                  size: 20),
                            ),
                            validator: (v) => CarpsService.isValidEmail(v ?? '')
                                ? null
                                : 'Enter a valid email address.',
                          ),
                          const SizedBox(height: 16),
                          FieldLabel('Password',
                              trailing: _signUp
                                  ? null
                                  : InkWell(
                                      onTap: () => context.push('/recover'),
                                      child: Text('Forgot password?',
                                          style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: d.accentOnInverse)),
                                    )),
                          TextFormField(
                            controller: _password,
                            obscureText: _obscure,
                            autofillHints: const [AutofillHints.password],
                            onFieldSubmitted: (_) => _submit(),
                            style: const TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: _signUp ? 'At least 8 characters' : 'Password',
                              prefixIcon:
                                  const Icon(CarpsIcons.lock, size: 20),
                              suffixIcon: IconButton(
                                tooltip: _obscure ? 'Show password' : 'Hide password',
                                icon: Icon(_obscure
                                    ? CarpsIcons.eyeSlash
                                    : CarpsIcons.eye),
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                              ),
                            ),
                            validator: (v) {
                              if ((v ?? '').isEmpty) return 'Enter your password.';
                              if (_signUp && v!.length < 8) {
                                return 'Use at least 8 characters.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),
                          Row(children: [
                            Icon(CarpsIcons.checkCircle,
                                size: 13, color: d.success),
                            const SizedBox(width: 6),
                            Text('Encrypted and protected',
                                style: TextStyle(
                                    fontSize: 12, color: d.textSecondary)),
                          ]),
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Row(children: [
                              Icon(CarpsIcons.warningCircle,
                                  size: 16, color: d.error),
                              const SizedBox(width: 6),
                              Expanded(
                                  child: Text(_error!,
                                      style: TextStyle(
                                          color: d.error, fontSize: 13))),
                            ]),
                          ],
                          const SizedBox(height: 20),
                          CarpsButton(
                            label: _signUp ? 'Create account' : 'Log in',
                            trailingArrow: true,
                            loading: _busy,
                            height: 52,
                            onPressed: _submit,
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_signUp ? 'Have an account?' : 'New here?',
                                  style: TextStyle(
                                      fontSize: 14, color: d.textSecondary)),
                              TextButton(
                                onPressed: () =>
                                    setState(() => _signUp = !_signUp),
                                child: Text(
                                    _signUp ? 'Log in' : 'Create an account',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: d.accentOnInverse)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const CarpsCopyright(),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleChooser extends StatelessWidget {
  const _GoogleChooser({required this.users});
  final List<UserProfile> users;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Row(children: [
            Text('Choose an account',
                style: Theme.of(context).textTheme.titleLarge),
            const Spacer(),
            const SimulatedTag(text: 'Simulated Google'),
          ]),
          const SizedBox(height: 4),
          Text('No real Google sign-in happens in this build.',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          for (final u in users.where((u) => u.displayName.isNotEmpty))
            ListTile(
              leading: CarpsAvatar(user: u, size: 36),
              title: Text(u.displayName),
              subtitle: Text(u.email),
              onTap: () => Navigator.pop(context, u.id),
            ),
          ListTile(
            leading: const Icon(CarpsIcons.userPlus),
            title: const Text('Use a new Google account'),
            subtitle: const Text('Starts first-time onboarding'),
            onTap: () => Navigator.pop(context, '__new__'),
          ),
        ],
      ),
    );
  }
}
