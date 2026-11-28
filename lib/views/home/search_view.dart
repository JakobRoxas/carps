import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/carps_icons.dart';

import '../../controllers/app_controller.dart';
import '../../core/theme/carps_colors.dart';
import '../../core/widgets/carps_widgets.dart';
import '../../core/widgets/event_widgets.dart';
import '../../models/carps_models.dart';

enum _DateFilter { any, today, weekend, pick }

/// Figma 07 · Search and Filters. Topic, date, area and builder combine.
class SearchView extends StatefulWidget {
  const SearchView({super.key});
  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final _query = TextEditingController();
  final _builder = TextEditingController();
  final _topics = <String>{};
  final _areas = <String>{};
  _DateFilter _date = _DateFilter.any;
  DateTime? _picked;
  bool _showFilters = true;

  @override
  void dispose() {
    _query.dispose();
    _builder.dispose();
    super.dispose();
  }

  int get _filterCount =>
      _topics.length +
      _areas.length +
      (_date == _DateFilter.any ? 0 : 1) +
      (_builder.text.trim().isEmpty ? 0 : 1);

  (DateTime?, DateTime?) _range(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    switch (_date) {
      case _DateFilter.any:
        return (null, null);
      case _DateFilter.today:
        return (today, today.add(const Duration(days: 1)));
      case _DateFilter.weekend:
        final sat = today.add(Duration(days: (6 - now.weekday) % 7));
        return (sat, sat.add(const Duration(days: 2)));
      case _DateFilter.pick:
        if (_picked == null) return (null, null);
        return (_picked, _picked!.add(const Duration(days: 1)));
    }
  }

  void _clear() => setState(() {
    _topics.clear();
    _areas.clear();
    _date = _DateFilter.any;
    _picked = null;
    _builder.clear();
    _query.clear();
  });

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final svc = app.events;
    final c = context.carps;
    final (from, to) = _range(svc.now);
    final results = svc.search(
      viewerId: app.me?.id,
      query: _query.text,
      topics: _topics,
      areas: _areas,
      from: from,
      to: to,
      builderQuery: _builder.text,
    );
    final people = _query.text.trim().isEmpty
        ? const <UserProfile>[]
        : app.profiles.searchPeople(_query.text, excludeId: app.me?.id);

    Widget chipGroup<T>(
      String label,
      List<T> items,
      bool Function(T) sel,
      void Function(T) toggle,
      String Function(T) text,
    ) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CaptionLabel(label),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final i in items)
                SelectChip(
                  label: text(i),
                  selected: sel(i),
                  icon: sel(i) ? CarpsIcons.checkBold : null,
                  onTap: () => setState(() => toggle(i)),
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      );
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackHeader(title: 'Search events'),
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF0A0A0A),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(36),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Theme(
                data: Theme.of(context).copyWith(
                  inputDecorationTheme: Theme.of(context).inputDecorationTheme
                      .copyWith(fillColor: const Color(0xFF1F1F1F)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _query,
                            autofocus: true,
                            style: const TextStyle(color: Colors.white),
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Search events, builders, topics',
                              hintStyle: const TextStyle(
                                color: Color(0xFFA3A3A3),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(999),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(999),
                                borderSide: BorderSide.none,
                              ),
                              prefixIcon: const Icon(
                                CarpsIcons.magnifyingGlass,
                                color: Color(0xFFA3A3A3),
                              ),
                              suffixIcon: _query.text.isEmpty
                                  ? null
                                  : IconButton(
                                      tooltip: 'Clear search',
                                      icon: const Icon(
                                        CarpsIcons.x,
                                        color: Color(0xFFA3A3A3),
                                      ),
                                      onPressed: () =>
                                          setState(() => _query.clear()),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Material(
                          color: c.accentFill,
                          shape: const StadiumBorder(),
                          child: InkWell(
                            customBorder: const StadiumBorder(),
                            onTap: () =>
                                setState(() => _showFilters = !_showFilters),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    CarpsIcons.slidersHorizontal,
                                    size: 18,
                                    color: c.onAccent,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Filters',
                                    style: TextStyle(
                                      color: c.onAccent,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (_filterCount > 0) ...[
                                    const SizedBox(width: 6),
                                    CircleAvatar(
                                      radius: 10,
                                      backgroundColor: c.inverse,
                                      child: Text(
                                        '$_filterCount',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_filterCount > 0) ...[
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            const Text(
                              'ACTIVE:',
                              style: TextStyle(
                                color: Color(0xFFA3A3A3),
                                fontSize: 11,
                                letterSpacing: 0.6,
                              ),
                            ),
                            for (final label in [
                              ..._topics,
                              ..._areas,
                              if (_date != _DateFilter.any)
                                switch (_date) {
                                  _DateFilter.today => 'Today',
                                  _DateFilter.weekend => 'This weekend',
                                  _ => 'Picked date',
                                },
                              if (_builder.text.trim().isNotEmpty)
                                'Builder: ${_builder.text.trim()}',
                            ])
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Chip(
                                  label: Text(
                                    label,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                  backgroundColor: const Color(0xFF1F1F1F),
                                  side: BorderSide.none,
                                  shape: const StadiumBorder(),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_showFilters) ...[
                            Row(
                              children: [
                                Icon(
                                  CarpsIcons.funnelSimple,
                                  color: c.accentFill,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Filter Discovery',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const Spacer(),
                                Text(
                                  '$_filterCount filters applied',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            chipGroup<String>(
                              'Topic / category',
                              kTopics,
                              _topics.contains,
                              (t) {
                                _topics.contains(t)
                                    ? _topics.remove(t)
                                    : _topics.add(t);
                              },
                              (t) => t,
                            ),
                            const CaptionLabel('Date & schedule'),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                SelectChip(
                                  label: 'Today',
                                  selected: _date == _DateFilter.today,
                                  icon: CarpsIcons.sun,
                                  onTap: () => setState(
                                    () => _date = _date == _DateFilter.today
                                        ? _DateFilter.any
                                        : _DateFilter.today,
                                  ),
                                ),
                                SelectChip(
                                  label: 'This weekend',
                                  selected: _date == _DateFilter.weekend,
                                  icon: CarpsIcons.calendarStar,
                                  onTap: () => setState(
                                    () => _date = _date == _DateFilter.weekend
                                        ? _DateFilter.any
                                        : _DateFilter.weekend,
                                  ),
                                ),
                                SelectChip(
                                  label: _picked == null
                                      ? 'Pick a date…'
                                      : '${_picked!.month}/${_picked!.day}',
                                  selected: _date == _DateFilter.pick,
                                  icon: CarpsIcons.calendarBlank,
                                  onTap: () async {
                                    final d = await showDatePicker(
                                      context: context,
                                      firstDate: svc.now,
                                      lastDate: svc.now.add(
                                        const Duration(days: 180),
                                      ),
                                      initialDate: svc.now,
                                    );
                                    if (d != null) {
                                      setState(() {
                                        _picked = d;
                                        _date = _DateFilter.pick;
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            chipGroup<String>(
                              'Area / hub',
                              kAreas,
                              _areas.contains,
                              (a) {
                                _areas.contains(a)
                                    ? _areas.remove(a)
                                    : _areas.add(a);
                              },
                              (a) => a,
                            ),
                            const CaptionLabel('Builder / community host'),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _builder,
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                hintText:
                                    'Search by community organizer or guild…',
                                prefixIcon: Icon(
                                  CarpsIcons.userCircleGear,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: CarpsButton(
                                    label: 'Clear all',
                                    kind: CarpsButtonKind.muted,
                                    onPressed: _clear,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: CarpsButton(
                                    label: 'Show results (${results.length})',
                                    onPressed: () =>
                                        setState(() => _showFilters = false),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                          ],
                          Row(
                            children: [
                              Text(
                                'Explore Results',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(width: 8),
                              TintPill('${results.length} matches'),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (results.isEmpty)
                            EmptyState(
                              title: 'No events match',
                              message: 'Try fewer filters or a different area. Private events never appear in search.',
                              actionLabel: 'Clear filters',
                              onAction: _clear,
                            ),
                          for (final e in results) ...[
                            EventPhotoCard(event: e),
                            const SizedBox(height: 16),
                          ],
                          if (results.isNotEmpty)
                            TextButton(
                              onPressed: () => context.go('/home'),
                              child: const Text('Back to For You'),
                            ),
                          if (people.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            Text(
                              'Find People',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 12),
                            Column(
                              children: [
                                for (var i = 0; i < people.length; i++) ...[
                                  if (i > 0)
                                    Divider(
                                      height: 1,
                                      thickness: 1,
                                      color: Theme.of(context).dividerColor
                                          .withValues(alpha: 0.35),
                                    ),
                                  Material(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                    clipBehavior: Clip.antiAlias,
                                    child: InkWell(
                                      key: ValueKey('person-${people[i].id}'),
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: () =>
                                          context.push('/user/${people[i].id}'),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 10,
                                        ),
                                        child: Row(
                                          children: [
                                            CarpsAvatar(
                                              user: people[i],
                                              size: 40,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    people[i].displayName,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyLarge,
                                                  ),
                                                  Text(
                                                    people[i].hostingEnabled
                                                        ? '${people[i].handle} · Builder'
                                                        : people[i].handle,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Icon(
                                              CarpsIcons.caretRight,
                                              size: 18,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
