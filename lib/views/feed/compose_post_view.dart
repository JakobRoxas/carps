import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/carps_icons.dart';

import '../../controllers/app_controller.dart';
import '../../core/demo_photos.dart';
import '../../core/format.dart';
import '../../core/theme/carps_colors.dart';
import '../../core/widgets/carps_widgets.dart';
import '../../core/widgets/event_widgets.dart';
import '../../models/carps_models.dart';
import '../onboarding/onboarding_view.dart' show pickSamplePhoto;

/// Figma 19 · Create Experience Post. Starts with the REQUIRED attended-event
/// picker: only completed, non-cancelled sessions with verified attendance.
class ComposePostView extends StatefulWidget {
  const ComposePostView({super.key, this.initialEventId});
  final String? initialEventId;
  @override
  State<ComposePostView> createState() => _ComposePostViewState();
}

class _ComposePostViewState extends State<ComposePostView> {
  late Future<List<CarpsEvent>> _eligible;
  String? _eventId;
  final _body = TextEditingController();
  String? _photo;
  final _tags = <String>{};
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _body.addListener(() => setState(() {}));
    _load();
  }

  void _load() {
    final app = context.appRead;
    _eligible = app.lookup(() => app.service.eligiblePostEvents(app.me!.id));
    _eligible.then((list) {
      if (!mounted) return;
      if (_eventId == null &&
          widget.initialEventId != null &&
          list.any((e) => e.id == widget.initialEventId)) {
        setState(() => _eventId = widget.initialEventId);
      }
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    setState(() => _busy = true);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    final app = context.appRead;
    var postId = '';
    final ok = runAction(context, () {
      postId = app.service
          .publishPost(
            authorId: app.me!.id,
            eventId: _eventId,
            body: _body.text,
            photoAsset: _photo,
            taggedIds: _tags.toList(),
          )
          .id;
    }, success: 'Published to the event, your Posts and tagged profiles');
    setState(() => _busy = false);
    if (ok) context.pushReplacement('/post/$postId');
  }

  Future<void> _pickEvent(List<CarpsEvent> events) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (ctx, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Text('Choose the session', style: Theme.of(ctx).textTheme.titleLarge),
            Text('Completed sessions where your attendance was verified.',
                style: Theme.of(ctx).textTheme.bodySmall),
            const SizedBox(height: 12),
            for (final e in events)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: EventRowTile(
                  event: e,
                  selected: e.id == _eventId,
                  onTap: () => Navigator.pop(ctx, e.id),
                  trailing: e.isPrivate
                      ? const StatusChip(StatusKind.private)
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
    if (picked != null) {
      setState(() {
        _eventId = picked;
        _tags.clear(); // tags must come from the selected session
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final svc = app.service;
    final me = app.me!;
    final c = context.carps;
    final event = _eventId == null ? null : svc.repo.event(_eventId!);
    final initialBlocked = widget.initialEventId != null &&
            svc.repo.event(widget.initialEventId!) != null
        ? svc.postBlocker(me.id, svc.repo.event(widget.initialEventId!)!)
        : null;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          BackHeader(title: 'New experience post'),
          Expanded(
            child: FutureBuilder<List<CarpsEvent>>(
              future: _eligible,
              builder: (context, snap) {
                final children = <Widget>[
                  SurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const TintPill('New moment'),
                          const Spacer(),
                          Text('Linked to one attended event',
                              style: Theme.of(context).textTheme.bodySmall),
                        ]),
                        const SizedBox(height: 8),
                        Text('Create Experience Post',
                            style: Theme.of(context).textTheme.headlineLarge),
                        Text('Share a moment from an event you attended',
                            style: TextStyle(color: c.textSecondary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(children: [
                    Text('Linked event (required)',
                        style: Theme.of(context).textTheme.titleSmall),
                    const Spacer(),
                    if (event != null)
                      Row(children: [
                        Icon(CarpsIcons.sealCheckFill,
                            size: 14, color: c.success),
                        const SizedBox(width: 4),
                        Text('Attended',
                            style: TextStyle(fontSize: 12, color: c.success)),
                      ]),
                  ]),
                  const SizedBox(height: 8),
                ];

                if (snap.connectionState != ConnectionState.done) {
                  children.add(const LoadingBlock(lines: 1));
                } else if (snap.hasError) {
                  // Failed lookup: distinct from empty; publishing disabled.
                  children.add(ErrorState(
                    message:
                        'We couldn\'t load your attendance history, so we can\'t confirm which events you can post about.',
                    onRetry: () => setState(_load),
                  ));
                } else if (snap.data!.isEmpty) {
                  children.add(EmptyState(
                    title: 'No attended events yet',
                    message:
                        'Posts must be about a completed event where the host checked you in. Once that happens, it shows up here.',
                    actionLabel: 'View attendance history',
                    onAction: () => context.push('/history'),
                  ));
                } else {
                  if (initialBlocked != null && event == null) {
                    children.add(Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(initialBlocked,
                          style: TextStyle(color: c.error, fontSize: 13)),
                    ));
                  }
                  children.add(SurfaceCard(
                    color: c.muted,
                    padding: const EdgeInsets.all(12),
                    onTap: () => _pickEvent(snap.data!),
                    child: Row(children: [
                      CircleAvatar(
                        backgroundColor: c.canvas,
                        child: Icon(
                            event == null
                                ? CarpsIcons.calendarPlus
                                : CarpsIcons.checkCircleFill,
                            color: event == null ? c.textSecondary : c.success),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: event == null
                            ? Text('Choose from your attendance history',
                                style: TextStyle(color: c.textSecondary))
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(event.title,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall),
                                  Text(
                                      shortDate(event.start),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall),
                                ],
                              ),
                      ),
                      CarpsButton(
                        label: event == null ? 'Choose' : 'Change',
                        kind: CarpsButtonKind.secondary,
                        height: 36,
                        expand: false,
                        onPressed: () => _pickEvent(snap.data!),
                      ),
                    ]),
                  ));
                  if (event != null) children.addAll(_composer(context, event));
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 640),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: children,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ]),
      ),
      bottomNavigationBar: BottomActionBar(
        child: CarpsButton(
          label: 'Publish post',
          trailingArrow: true,
          loading: _busy,
          onPressed: event == null || _body.text.trim().isEmpty
              ? null
              : _publish,
        ),
      ),
    );
  }

  List<Widget> _composer(BuildContext context, CarpsEvent event) {
    final svc = context.app.service;
    final me = context.app.me!;
    final c = context.carps;
    final candidates = svc.tagCandidates(event.id, me.id);
    return [
      const SizedBox(height: 20),
      Row(children: [
        Text(_photo == null ? 'Your experience' : 'Caption',
            style: Theme.of(context).textTheme.titleSmall),
        const Spacer(),
        Text('${_body.text.length} / 280',
            style: Theme.of(context).textTheme.bodySmall),
      ]),
      const SizedBox(height: 8),
      TextField(
        controller: _body,
        maxLines: 4,
        maxLength: 280,
        buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
            null,
        decoration: InputDecoration(
            hintText: _photo == null
                ? 'What was it like?'
                : 'Add a caption to your photo'),
      ),
      const SizedBox(height: 12),
      if (_photo != null)
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(fit: StackFit.expand, children: [
              Image.asset(_photo!, fit: BoxFit.cover),
              Positioned(
                right: 12,
                top: 12,
                child: CircleIconButton(
                  icon: CarpsIcons.x,
                  tooltip: 'Remove photo',
                  background: const Color(0xCC0A0A0A),
                  foreground: Colors.white,
                  onPressed: () => setState(() => _photo = null),
                ),
              ),
            ]),
          ),
        )
      else
        Align(
          alignment: Alignment.centerLeft,
          child: CarpsButton(
            label: 'Add photo',
            icon: CarpsIcons.camera,
            kind: CarpsButtonKind.muted,
            height: 40,
            expand: false,
            onPressed: () async {
              final p = await pickSamplePhoto(context, options: DemoPhotos.all);
              if (p != null) setState(() => _photo = p);
            },
          ),
        ),
      const SizedBox(height: 20),
      Text('Tag the builder & checked-in friends (optional)',
          style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 4),
      Text('Only the builder and people checked in at this session can be tagged.',
          style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 8),
      if (candidates.isEmpty)
        Text('No one else to tag from this session.',
            style: Theme.of(context).textTheme.bodySmall)
      else
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final u in candidates)
            FilterChip(
              avatar: CarpsAvatar(user: u, size: 22),
              label: Text(u.handle),
              selected: _tags.contains(u.id),
              selectedColor: c.selectFill,
              checkmarkColor: c.onSelect,
              labelStyle: TextStyle(
                  color: _tags.contains(u.id) ? c.onSelect : c.textPrimary),
              shape: const StadiumBorder(),
              side: BorderSide.none,
              backgroundColor: c.muted,
              onSelected: (v) =>
                  setState(() => v ? _tags.add(u.id) : _tags.remove(u.id)),
            ),
        ]),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: c.accentTint, borderRadius: BorderRadius.circular(20)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: c.canvas,
              child: Icon(
                  event.isPrivate
                      ? CarpsIcons.lockSimple
                      : CarpsIcons.globeSimple,
                  color: c.accentFill,
                  size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      event.isPrivate
                          ? 'Visible to: hosting team & verified attendees'
                          : 'Visible to: everyone on CARPS',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(svc.audienceLabel(event),
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    ];
  }
}
