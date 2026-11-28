import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/carps_icons.dart';

import '../../controllers/app_controller.dart';
import '../../core/theme/carps_colors.dart';
import '../../core/widgets/carps_widgets.dart';
import '../../models/carps_models.dart';
import '../onboarding/onboarding_view.dart' show AreaField;

/// Figma 10 · Edit Personal Profile.
class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});
  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _username;
  late final TextEditingController _bio;
  late final TextEditingController _area;
  late Set<String> _interests;

  @override
  void initState() {
    super.initState();
    final me = context.appRead.me!;
    _name = TextEditingController(text: me.displayName)
      ..addListener(() => setState(() {}));
    _username = TextEditingController(text: me.username)
      ..addListener(() => setState(() {}));
    _bio = TextEditingController(text: me.bio)..addListener(() => setState(() {}));
    _area = TextEditingController(text: me.area ?? '');
    _interests = {...me.interests};
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _bio.dispose();
    _area.dispose();
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    if (_interests.length < 3) {
      showCarpsSnack(context, 'Keep at least 3 interests.', error: true);
      return;
    }
    final app = context.appRead;
    app.profiles.updateUser(app.me!.copyWith(
      displayName: _name.text.trim(),
      username: _username.text.trim().replaceFirst('@', ''),
      bio: _bio.text.trim(),
      area: _area.text.trim(),
      interests: _interests.toList(),
    ));
    showCarpsSnack(context, 'Profile saved');
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final me = app.me!;
    final svc = app.profiles;
    final c = context.carps;
    final usernameProblem = svc.usernameProblem(_username.text, ownerId: me.id);
    return Form(
      key: _form,
      child: CarpsPage(
        title: 'Edit profile',
        trailing: TextButton(
            onPressed: _save,
            child: Text('Save',
                style: TextStyle(
                    color: c.accentText, fontWeight: FontWeight.w600))),
        bottomBar: Column(mainAxisSize: MainAxisSize.min, children: [
          CarpsButton(label: 'Save changes', trailingArrow: true, onPressed: _save),
          TextButton(onPressed: () => context.pop(), child: const Text('Cancel')),
        ]),
        children: [
          Text('Edit Personal Profile',
              style: Theme.of(context).textTheme.headlineMedium),
          Text('Manage your public presence and account details.',
              style: TextStyle(color: c.textSecondary)),
          const SizedBox(height: 16),
          SurfaceCard(
            color: c.accentTint,
            child: Row(children: [
              Icon(CarpsIcons.lightbulb, color: c.accentFill),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                    'Complete profiles help builders recognize you when reviewing requests.',
                    style: TextStyle(fontSize: 13)),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          Center(
            child: CarpsAvatar(
              user: me.copyWith(displayName: _name.text),
              size: 80,
            ),
          ),
          const SizedBox(height: 12),
          FieldLabel('Display name',
              trailing: Text('REQUIRED',
                  style: TextStyle(fontSize: 10, color: c.textSecondary))),
          TextFormField(
            controller: _name,
            validator: (v) =>
                (v ?? '').trim().length < 2 ? 'Enter your display name.' : null,
          ),
          const SizedBox(height: 4),
          Text('Your real or preferred name shown to fellow players.',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          FieldLabel('Username',
              trailing: Text(
                  usernameProblem ?? '✓ Username available',
                  style: TextStyle(
                      fontSize: 11,
                      color: usernameProblem == null ? c.success : c.error))),
          TextFormField(
            controller: _username,
            decoration: const InputDecoration(prefixText: '@'),
            validator: (v) => svc.usernameProblem(v ?? '', ownerId: me.id),
          ),
          const SizedBox(height: 4),
          Text('Only lowercase letters, numbers and underscores.',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          FieldLabel('Short bio',
              trailing: Text('${_bio.text.length} / 120',
                  style: TextStyle(fontSize: 11, color: c.textSecondary))),
          TextFormField(
            controller: _bio,
            maxLines: 3,
            maxLength: 120,
            buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                null,
          ),
          const SizedBox(height: 16),
          FieldLabel('Area / City',
              trailing: Text('Optional',
                  style: TextStyle(fontSize: 11, color: c.textSecondary))),
          AreaField(controller: _area),
          const SizedBox(height: 20),
          Text('Your interests', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final t in kTopics)
              SelectChip(
                label: t,
                selected: _interests.contains(t),
                onTap: () => setState(() => _interests.contains(t)
                    ? _interests.remove(t)
                    : _interests.add(t)),
              ),
          ]),
        ],
      ),
    );
  }
}
