import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/carps_icons.dart';

import '../../core/theme/carps_colors.dart';
import '../../core/widgets/carps_widgets.dart';
import '../../controllers/app_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/carps_models.dart';

/// Figma 02 · Password Recovery. Email sending is simulated.
class RecoveryView extends StatefulWidget {
  const RecoveryView({super.key});

  @override
  State<RecoveryView> createState() => _RecoveryViewState();
}

class _RecoveryViewState extends State<RecoveryView> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _sent = false;
  bool _busy = false;
  bool _simulated = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = context.appRead.auth;
    try {
      final sent = await auth.sendPasswordResetEmail(_email.text);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _sent = true;
        _simulated = !sent;
      });
    } on RuleViolation catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = error.message;
        });
      }
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  color: c.canvas,
                  padding: EdgeInsets.fromLTRB(
                      16, MediaQuery.paddingOf(context).top + 16, 16, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        CircleIconButton(
                          icon: CarpsIcons.arrowLeft,
                          tooltip: 'Back to log in',
                          size: 48,
                          onPressed: () => context.canPop()
                              ? context.pop()
                              : context.go('/login'),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                              color: c.muted,
                              borderRadius: BorderRadius.circular(999)),
                          child: Row(children: [
                            Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                    color: c.accentFill,
                                    shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Text('CARPS ID',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: c.textSecondary)),
                          ]),
                        ),
                      ]),
                      const SizedBox(height: 24),
                      const TintPill('Account security',
                          icon: CarpsIcons.clockCounterClockwise),
                      const SizedBox(height: 12),
                      Text('Reset your password',
                          style: Theme.of(context).textTheme.headlineLarge),
                      const SizedBox(height: 8),
                      Text(
                          'Enter your registered email and we\'ll send you a secure link to recover your account.',
                          style: TextStyle(
                              fontSize: 14, color: c.textSecondary, height: 1.4)),
                    ],
                  ),
                ),
                DarkSheet(
                  fill: true,
                  child: Builder(builder: (context) {
                    final d = context.carps;
                    if (_sent) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Icon(CarpsIcons.envelopeSimpleOpenFill,
                              size: 48, color: d.accentOnInverse),
                          const SizedBox(height: 16),
                          Text('Check your inbox',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 8),
                          Text(
                              'If ${_email.text.trim()} has a CARPS account, a reset link is on its way.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: d.textSecondary)),
                          const SizedBox(height: 12),
                          if (_simulated)
                            const Center(
                                child: SimulatedTag(
                                    text: 'Simulated · no email sent')),
                          const SizedBox(height: 24),
                          CarpsButton(
                              label: 'Back to log in',
                              onPressed: () => context.go('/login')),
                        ],
                      );
                    }
                    return Form(
                      key: _form,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const CaptionLabel('Email address'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _email,
                            onChanged: (_) => setState(() => _error = null),
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              hintText: 'ana@example.com',
                              prefixIcon: Icon(CarpsIcons.envelopeSimple,
                                  size: 20),
                            ),
                            validator: (v) => AuthController.isValidEmail(v ?? '')
                                ? null
                                : 'Enter a valid email address.',
                            onFieldSubmitted: (_) => _send(),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 8),
                            Text(_error!,
                                style: TextStyle(color: d.error, fontSize: 13)),
                          ],
                          const SizedBox(height: 24),
                          CarpsButton(
                              label: 'Send reset link',
                              trailingArrow: true,
                              loading: _busy,
                              onPressed: _send),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () => context.go('/login'),
                            child: Text('Remembered your password? Log in',
                                style: TextStyle(color: d.textSecondary)),
                          ),
                          const SizedBox(height: 16),
                          SurfaceCard(
                            child: Row(children: [
                              Icon(CarpsIcons.lifebuoy,
                                  color: d.accentOnInverse),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Need immediate help?',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600)),
                                    Text(
                                        'Lost access to your email? Contact the CARPS safety desk from any device.',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: d.textSecondary)),
                                  ],
                                ),
                              ),
                            ]),
                          ),
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
