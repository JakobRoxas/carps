import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/carps_icons.dart';

import '../../controllers/app_controller.dart';
import '../../core/demo_photos.dart';
import '../../core/format.dart';
import '../../core/theme/carps_colors.dart';
import '../../core/widgets/carps_widgets.dart';
import '../../core/widgets/event_widgets.dart';
import '../../models/carps_models.dart';
import '../onboarding/onboarding_view.dart' show pickSamplePhoto;

/// Figma 13 · Create / Edit Event (Details · Time · Guests).
class EventFormView extends StatefulWidget {
  const EventFormView({super.key, this.eventId});
  final String? eventId;
  @override
  State<EventFormView> createState() => _EventFormViewState();
}

class _EventFormViewState extends State<EventFormView> {
  final _title = TextEditingController();
  final _venue = TextEditingController();
  final _description = TextEditingController();
  final _capacity = TextEditingController();
  final _area = TextEditingController();
  final _peopleQuery = TextEditingController();
  String _topic = kTopics[1];
  EventVisibility _visibility = EventVisibility.public;
  bool _featured = false;
  String? _cover = DemoPhotos.pickleball;
  late DateTime _start;
  late DateTime _end;
  int _tab = 0;
  String? _error;
  bool _busy = false;
  bool _searchingLocations = false;
  List<Map<String, dynamic>> _locationSuggestions = const [];
  final _coHosts = <String>{};
  final _guests = <String>{};
  CarpsEvent? _editing;

  @override
  void initState() {
    super.initState();
    _title.addListener(_refreshPreview);
    _venue.addListener(_refreshPreview);
    final app = context.appRead;
    final svc = app.events;
    final now = svc.now;
    _start = DateTime(now.year, now.month, now.day + 3, 18);
    _end = _start.add(const Duration(hours: 3));
    if (widget.eventId != null) {
      final e = app.data.eventById(widget.eventId!);
      if (e != null) {
        _editing = e;
        _title.text = e.title;
        _venue.text = e.venue;
        _description.text = e.description;
        _capacity.text = e.capacity?.toString() ?? '';
        _topic = e.topic;
        _area.text = e.area;
        _visibility = e.visibility;
        _featured = e.featuredOnProfile;
        _cover = e.coverAsset;
        _start = e.start;
        _end = e.end;
      }
    }
  }

  @override
  void dispose() {
    _title.removeListener(_refreshPreview);
    _venue.removeListener(_refreshPreview);
    _area.dispose();
    _peopleQuery.dispose();
    _title.dispose();
    _venue.dispose();
    _description.dispose();
    _capacity.dispose();
    super.dispose();
  }

  void _refreshPreview() {
    if (mounted) setState(() {});
  }

  Future<void> _searchLocations(String query) async {
    final text = query.trim();
    if (text.length < 3) {
      if (mounted) setState(() => _locationSuggestions = const []);
      return;
    }
    setState(() => _searchingLocations = true);
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': text,
        'format': 'json',
        'addressdetails': '1',
        'limit': '5',
        'countrycodes': 'ph',
      });
      final response = await http.get(
        uri,
        headers: const {'User-Agent': 'CARPS Flutter app'},
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          _locationSuggestions = decoded is List
              ? decoded.whereType<Map<String, dynamic>>().toList()
              : const [];
        });
      }
    } catch (_) {
      if (mounted) setState(() => _locationSuggestions = const []);
    } finally {
      if (mounted) setState(() => _searchingLocations = false);
    }
  }

  Future<void> _submit() async {
    final app = context.appRead;
    final svc = app.events;
    final me = app.me!;
    final problem = svc.validateEventDraft(
      title: _title.text,
      venue: _venue.text,
      start: _start,
      end: _end,
      isNew: _editing == null,
    );
    if (problem != null) {
      setState(() {
        _error = problem;
        _tab = problem.contains('time') ? 1 : 0;
      });
      return;
    }
    setState(() {
      _error = null;
      _busy = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    final capacity = int.tryParse(_capacity.text.trim());
    final ok = runAction(context, () {
      if (_editing == null) {
        final e = svc.createEvent(
          actorId: me.id,
          title: _title.text,
          description: _description.text,
          topic: _topic,
          venue: _venue.text,
          area: _area.text,
          start: _start,
          end: _end,
          visibility: _visibility,
          coverAsset: _cover,
          capacity: capacity,
          featuredOnProfile: _featured,
        );
        for (final id in _coHosts) {
          svc.inviteCoHost(me.id, e.id, id);
        }
        for (final id in _guests) {
          svc.inviteGuest(me.id, e.id, id);
        }
        context.pushReplacement('/event/${e.id}');
      } else {
        svc.updateEvent(
          actorId: me.id,
          eventId: _editing!.id,
          title: _title.text,
          description: _description.text,
          topic: _topic,
          venue: _venue.text,
          area: _area.text,
          start: _start,
          end: _end,
          visibility: _visibility,
          coverAsset: _cover,
          capacity: capacity,
          featuredOnProfile: _featured,
        );
        for (final id in _coHosts) {
          svc.inviteCoHost(me.id, _editing!.id, id);
        }
        for (final id in _guests) {
          svc.inviteGuest(me.id, _editing!.id, id);
        }
        context.pop();
      }
    }, success: _editing == null ? 'Published!' : 'Changes saved');
    if (!ok && mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final me = app.me!;
    final c = context.carps;
    if (!me.hostingEnabled) {
      return CarpsPage(
        title: 'Create event',
        children: [
          EmptyState(
            title: 'Turn on hosting first',
            message: 'Attendees can activate hosting tools on this same account. No second account needed.',
            actionLabel: 'Enable hosting',
            onAction: () => context.pushReplacement('/builder-setup'),
          ),
        ],
      );
    }
    if (_editing != null && !_editing!.isHostingTeam(me.id)) {
      return const CarpsPage(
        title: 'Edit event',
        children: [
          EmptyState(
            title: 'Not your event',
            message: 'Only the hosting team can edit this listing.',
          ),
        ],
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 780;
        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                BackHeader(
                  title: _editing == null ? 'Create event' : 'Edit event',
                ),
                Expanded(
                  child: desktop
                      ? LayoutBuilder(
                          builder: (context, constraints) => Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1240),
                              child: SizedBox(
                                height: constraints.maxHeight,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            _tabsBar(desktop: true),
                                            Expanded(
                                              child: DarkSheet(
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                      28,
                                                      28,
                                                      28,
                                                      32,
                                                    ),
                                                child: Builder(
                                                  builder: (context) =>
                                                      SingleChildScrollView(
                                                        child: _activeTab(
                                                          context,
                                                        ),
                                                      ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 24),
                                      SizedBox(
                                        width: 300,
                                        child: SingleChildScrollView(
                                          child: _draftPreview(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _tabsBar(desktop: false),
                            Expanded(
                              child: DarkSheet(
                                child: Builder(
                                  builder: (context) => SingleChildScrollView(
                                    child: _activeTab(context),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: desktop
              ? null
              : BottomActionBar(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Icon(
                                CarpsIcons.warningCircle,
                                color: c.error,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: TextStyle(
                                    color: c.error,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Row(
                        children: [
                          StatusChip(
                            _visibility == EventVisibility.private
                                ? StatusKind.private
                                : StatusKind.public,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CarpsButton(
                              label: _editing == null
                                  ? 'Publish'
                                  : 'Save changes',
                              trailingArrow: true,
                              loading: _busy,
                              onPressed: _submit,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _tabsBar({required bool desktop}) => Padding(
    padding: EdgeInsets.fromLTRB(16, desktop ? 16 : 4, 16, 20),
    child: SegmentedTabs(
      labels: const ['Details', 'Time', 'Guests'],
      selected: _tab,
      onChanged: (i) => setState(() => _tab = i),
    ),
  );

  Widget _activeTab(BuildContext context) => switch (_tab) {
    0 => _details(context),
    1 => _time(context),
    _ => _guestsTab(context),
  };

  Widget _draftPreview(BuildContext context) {
    final c = context.carps;
    final title = _title.text.trim();
    final venue = _venue.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CaptionLabel('Listing preview'),
        const SizedBox(height: 10),
        SurfaceCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: _cover == null
                      ? Container(
                          color: c.inverseRaised,
                          child: Icon(
                            topicIcon(_topic),
                            size: 40,
                            color: c.textSecondary,
                          ),
                        )
                      : Image.asset(_cover!, fit: BoxFit.cover),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TintPill(_topic),
                    const SizedBox(height: 10),
                    Text(
                      title.isEmpty ? 'Your event title' : title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          CarpsIcons.calendarBlank,
                          size: 18,
                          color: c.accentFill,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(dateTime(_start))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(CarpsIcons.mapPin, size: 18, color: c.accentFill),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            venue.isEmpty ? 'Venue to be added' : venue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    StatusChip(
                      _visibility == EventVisibility.private
                          ? StatusKind.private
                          : StatusKind.public,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SurfaceCard(
          color: c.muted,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ready when you are',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              Text(
                'Your listing and invitations go live when you publish.',
                style: TextStyle(color: c.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: TextStyle(color: c.error, fontSize: 13)),
        ],
        const SizedBox(height: 16),
        CarpsButton(
          label: _editing == null ? 'Publish event' : 'Save changes',
          trailingArrow: true,
          loading: _busy,
          onPressed: _submit,
        ),
      ],
    );
  }

  Widget _details(BuildContext context) {
    final d = context.carps;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_cover != null)
                  Image.asset(_cover!, fit: BoxFit.cover)
                else
                  Container(
                    color: d.inverseRaised,
                    child: Icon(
                      topicIcon(_topic),
                      size: 40,
                      color: d.textSecondary,
                    ),
                  ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: CarpsButton(
                    label: _cover == null ? 'Add cover' : 'Change cover',
                    icon: CarpsIcons.camera,
                    kind: CarpsButtonKind.inverse,
                    height: 38,
                    expand: false,
                    onPressed: () async {
                      final p = await pickSamplePhoto(
                        context,
                        options: DemoPhotos.all,
                      );
                      if (p != null) setState(() => _cover = p);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const CaptionLabel('Event title'),
        const SizedBox(height: 8),
        TextField(
          controller: _title,
          decoration: const InputDecoration(
            hintText: 'e.g. Sunday pickleball open play',
          ),
        ),
        const SizedBox(height: 16),
        const CaptionLabel('Topic'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in kTopics)
              SelectChip(
                label: t,
                selected: _topic == t,
                icon: topicIcon(t),
                onTap: () => setState(() => _topic = t),
              ),
          ],
        ),
        const SizedBox(height: 16),
        const CaptionLabel('Venue'),
        const SizedBox(height: 8),
        TextField(
          controller: _venue,
          onChanged: _searchLocations,
          decoration: const InputDecoration(
            hintText: 'The Upper Deck Sports Center, Court 3',
            prefixIcon: Icon(CarpsIcons.mapPin, size: 20),
          ),
        ),
        if (_searchingLocations)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        if (_locationSuggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          SurfaceCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Column(
              children: [
                for (final location in _locationSuggestions)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(CarpsIcons.mapPin, color: d.accentFill),
                    title: Text(
                      location['name']?.toString() ??
                          location['display_name']?.toString() ??
                          '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      location['display_name']?.toString() ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      final address =
                          location['address'] is Map<String, dynamic>
                          ? location['address'] as Map<String, dynamic>
                          : const <String, dynamic>{};
                      final area =
                          address['city'] ??
                          address['municipality'] ??
                          address['suburb'] ??
                          address['county'] ??
                          address['state'];
                      setState(() {
                        _venue.text =
                            location['display_name']?.toString() ?? _venue.text;
                        if (area != null) _area.text = area.toString();
                        _locationSuggestions = const [];
                      });
                      _venue.selection = TextSelection.collapsed(
                        offset: _venue.text.length,
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        TextField(
          controller: _area,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Area / neighborhood',
            hintText: 'Makati, Salcedo Village, Bonifacio Global City',
          ),
        ),
        const SizedBox(height: 16),
        const CaptionLabel('Description'),
        const SizedBox(height: 8),
        TextField(
          controller: _description,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'What should guests expect? Skill level, what to bring…',
          ),
        ),
        const SizedBox(height: 16),
        const CaptionLabel('Capacity (optional)'),
        const SizedBox(height: 8),
        TextField(
          controller: _capacity,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: '20'),
        ),
        const SizedBox(height: 20),
        const CaptionLabel('Visibility'),
        const SizedBox(height: 8),
        SegmentedTabs(
          labels: const ['Public', 'Private'],
          selected: _visibility == EventVisibility.public ? 0 : 1,
          onChanged: (i) => setState(
            () => _visibility = i == 0
                ? EventVisibility.public
                : EventVisibility.private,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _visibility == EventVisibility.public
              ? 'Anyone can find this listing and request to join. Signed-out visitors can view it.'
              : 'Hidden from discovery and profiles. Only people you invite can see it and request to join.',
          style: TextStyle(fontSize: 12, color: d.textSecondary),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Feature on my profile'),
          subtitle: Text(
            'Shows under Profile → Events. Listings are not posts.',
            style: TextStyle(fontSize: 12, color: d.textSecondary),
          ),
          value: _featured,
          onChanged: (v) => setState(() => _featured = v),
        ),
      ],
    );
  }

  Widget _time(BuildContext context) {
    final d = context.carps;
    final svc = context.app.events;
    Future<void> pick(bool isStart) async {
      final base = isStart ? _start : _end;
      final date = await showDatePicker(
        context: context,
        initialDate: base,
        firstDate: svc.now.subtract(const Duration(days: 1)),
        lastDate: svc.now.add(const Duration(days: 365)),
      );
      if (date == null || !context.mounted) return;
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(base),
      );
      if (time == null) return;
      final dt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      setState(() {
        if (isStart) {
          final dur = _end.difference(_start);
          _start = dt;
          _end = dt.add(dur);
        } else {
          _end = dt;
        }
      });
    }

    Widget wheel(bool isStart) => Container(
      height: 180,
      decoration: BoxDecoration(
        color: d.inverseRaised,
        borderRadius: BorderRadius.circular(20),
      ),
      child: CupertinoTheme(
        data: const CupertinoThemeData(
          brightness: Brightness.dark,
          textTheme: CupertinoTextThemeData(
            dateTimePickerTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontFamily: 'Inter',
            ),
          ),
        ),
        child: CupertinoDatePicker(
          key: ValueKey('wheel-$isStart'),
          mode: isStart
              ? CupertinoDatePickerMode.dateAndTime
              : CupertinoDatePickerMode.time,
          initialDateTime: isStart ? _start : _end,
          minuteInterval: 1,
          onDateTimeChanged: (v) => setState(() {
            if (isStart) {
              final dur = _end.difference(_start);
              _start = v;
              _end = v.add(dur);
            } else {
              _end = DateTime(
                _start.year,
                _start.month,
                _start.day,
                v.hour,
                v.minute,
              );
            }
          }),
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final useWheel = constraints.maxWidth < 600;
        Widget editor(bool isStart) {
          final value = isStart ? _start : _end;
          if (useWheel) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CaptionLabel(isStart ? 'Starts' : 'Ends'),
                    const Spacer(),
                    Text(
                      dateTime(value),
                      style: TextStyle(
                        color: d.accentOnInverse,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                wheel(isStart),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CaptionLabel(isStart ? 'Starts' : 'Ends'),
              const SizedBox(height: 8),
              SurfaceCard(
                color: d.inverse,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isStart ? CarpsIcons.calendarBlank : CarpsIcons.clock,
                          size: 20,
                          color: d.accentOnInverse,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            dateTime(value),
                            style: TextStyle(
                              color: d.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CarpsButton(
                      label: isStart ? 'Change start' : 'Change end',
                      icon: isStart
                          ? CarpsIcons.calendarBlank
                          : CarpsIcons.clock,
                      kind: CarpsButtonKind.muted,
                      onPressed: () => pick(isStart),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        final sideBySide = !useWheel && constraints.maxWidth >= 680;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (sideBySide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: editor(true)),
                  const SizedBox(width: 16),
                  Expanded(child: editor(false)),
                ],
              )
            else ...[
              editor(true),
              const SizedBox(height: 20),
              editor(false),
            ],
            if (!_end.isAfter(_start))
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'End time must be after the start time.',
                  style: TextStyle(color: d.error, fontSize: 12),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _guestsTab(BuildContext context) {
    final app = context.app;
    final svc = app.events;
    final me = app.me!;
    final d = context.carps;
    final builders = context.appRead.data.users
        .where(
          (u) => u.hostingEnabled && u.id != me.id && u.displayName.isNotEmpty,
        )
        .toList();
    final people = context.appRead.data.users
        .where((u) => u.id != me.id && u.displayName.isNotEmpty && !u.isAdmin)
        .toList();
    bool alreadyCoHost(String id) =>
        _editing != null &&
        (_editing!.isHostingTeam(id) ||
            svc.coHostInvitation(_editing!.id, id) != null);
    bool alreadyGuest(String id) =>
        _editing != null && svc.guestInvitation(_editing!.id, id) != null;
    final query = _peopleQuery.text;
    final visibleBuilders = builders.where((b) {
      final q = query.toLowerCase().trim();
      return q.isEmpty ||
          b.displayName.toLowerCase().contains(q) ||
          b.username.contains(q) ||
          (b.builderName?.toLowerCase().contains(q) ?? false);
    }).toList();
    final visiblePeople = people.where((p) {
      final q = query.toLowerCase().trim();
      return q.isEmpty ||
          p.displayName.toLowerCase().contains(q) ||
          p.username.contains(q) ||
          (p.builderName?.toLowerCase().contains(q) ?? false);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _peopleQuery,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'Search co-hosts and attendees',
            prefixIcon: Icon(CarpsIcons.magnifyingGlass, size: 20),
          ),
        ),
        const SizedBox(height: 16),
        Text('Co-hosts', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          'Builders you invite get hosting tools (approve requests, scan passes) only after they accept.',
          style: TextStyle(fontSize: 12, color: d.textSecondary),
        ),
        const SizedBox(height: 12),
        for (final b in visibleBuilders)
          _PersonCheck(
            user: b,
            subtitle: b.builderName ?? b.handle,
            checked: _coHosts.contains(b.id) || alreadyCoHost(b.id),
            locked: alreadyCoHost(b.id),
            lockedLabel: _editing?.coHostIds.contains(b.id) == true
                ? 'Co-host'
                : 'Invited',
            onChanged: (v) => setState(() {
              v ? _coHosts.add(b.id) : _coHosts.remove(b.id);
              _guests.remove(b.id);
            }),
          ),
        const SizedBox(height: 24),
        Text(
          'Private guest invitations',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          _visibility == EventVisibility.private
              ? 'Invite attendees or other builders as GUESTS. An invitation lets them see the listing and request to join. It doesn\'t grant host privileges or guarantee admission.'
              : 'Public events don\'t need invitations, but you can still nudge people. They still request to join.',
          style: TextStyle(fontSize: 12, color: d.textSecondary),
        ),
        const SizedBox(height: 12),
        for (final p in visiblePeople)
          _PersonCheck(
            user: p,
            subtitle: p.hostingEnabled
                ? 'Builder · invited as guest only'
                : p.handle,
            checked: _guests.contains(p.id) || alreadyGuest(p.id),
            locked: alreadyGuest(p.id),
            lockedLabel: 'Invited',
            enabled: !_coHosts.contains(p.id),
            onChanged: (v) =>
                setState(() => v ? _guests.add(p.id) : _guests.remove(p.id)),
          ),
        const SizedBox(height: 8),
        Text(
          'Invitations are sent when you ${_editing == null ? 'publish' : 'save'}.',
          style: TextStyle(fontSize: 12, color: d.textSecondary),
        ),
      ],
    );
  }
}

class _PersonCheck extends StatelessWidget {
  const _PersonCheck({
    required this.user,
    required this.subtitle,
    required this.checked,
    required this.onChanged,
    this.locked = false,
    this.lockedLabel = 'Invited',
    this.enabled = true,
  });
  final UserProfile user;
  final String subtitle;
  final bool checked;
  final bool locked;
  final String lockedLabel;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      enabled: enabled,
      leading: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push('/user/${user.id}'),
        child: CarpsAvatar(user: user, size: 40),
      ),
      title: Text(user.displayName),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      trailing: locked
          ? StatusChip(StatusKind.invited, label: lockedLabel)
          : Checkbox(
              value: checked,
              onChanged: enabled ? (v) => onChanged(v ?? false) : null,
            ),
      onTap: locked || !enabled ? null : () => onChanged(!checked),
    );
  }
}
