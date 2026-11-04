import 'package:flutter/material.dart';
import 'package:materialcraft/materialcraft.dart';

import '../model/surface_config.dart';
import '../model/typography_config.dart';

/// All TextTheme styles of the preview theme.
class TypographyShowcase extends StatelessWidget {
  const TypographyShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final caption = t.textTheme.labelSmall?.copyWith(
      color: t.colorScheme.onSurfaceVariant,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final r in TextRole.values) ...[
            Builder(
              builder: (context) {
                final style = r.of(t.textTheme);
                final size = style?.fontSize ?? 0;
                final lh = size * (style?.height ?? 0);
                return Text(
                  '${r.label} · ${size.round()}/${lh.round()} · '
                  '${style?.fontWeight?.value ?? ''}',
                  style: caption,
                );
              },
            ),
            const SizedBox(height: 2),
            Text(
              'The quick brown fox jumps',
              style: r.of(t.textTheme),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

/// Preview of the selected container.
class SurfaceShowcase extends StatelessWidget {
  const SurfaceShowcase({super.key, required this.kind});

  final SurfaceKind kind;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kind.label,
            style: t.textTheme.labelMedium?.copyWith(
              color: t.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          switch (kind) {
            SurfaceKind.card => const _Cards(),
            SurfaceKind.dialog => const _Dialog(),
            SurfaceKind.bottomSheet => const _Sheet(),
            SurfaceKind.appBar => const _Bar(),
            SurfaceKind.navigationBar => const _NavBar(),
            SurfaceKind.navigationRail => const _Rail(),
            SurfaceKind.listTile => const _Tiles(),
            SurfaceKind.divider => const _Dividers(),
            SurfaceKind.fab => const _Fabs(),
            SurfaceKind.tooltip => const _Tooltips(),
            SurfaceKind.tabBar => const _Tabs(),
            SurfaceKind.chip => const _Chips(),
            SurfaceKind.badge => const _Badges(),
            SurfaceKind.menu => const _Menus(),
            SurfaceKind.checkbox ||
            SurfaceKind.radio ||
            SurfaceKind.switchControl ||
            SurfaceKind.slider => const _Controls(),
            SurfaceKind.snackBar => const _Snack(),
          },
        ],
      ),
    );
  }
}

class _Cards extends StatelessWidget {
  const _Cards();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    Widget content(String title) => Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: t.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('€18,420', style: t.textTheme.headlineSmall),
          Text(
            'Monthly revenue',
            style: t.textTheme.bodySmall?.copyWith(
              color: t.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(margin: EdgeInsets.zero, child: content('Card')),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Card.filled(
                margin: EdgeInsets.zero,
                child: content('Filled'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Card.outlined(
                margin: EdgeInsets.zero,
                child: content('Outlined'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Dialog extends StatelessWidget {
  const _Dialog();

  Widget _dialog(BuildContext context, {bool inline = false}) => AlertDialog(
    icon: const Icon(Icons.delete_outline),
    title: const Text('Delete the project?'),
    content: const Text(
      'The project and its 12 files will be permanently removed.',
    ),
    actions: [
      TextButton(
        onPressed: inline ? () {} : () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: inline ? () {} : () => Navigator.pop(context),
        child: const Text('Delete'),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _dialog(context, inline: true),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () =>
              showDialog<void>(context: context, builder: (c) => _dialog(c)),
          icon: const Icon(Icons.open_in_new, size: 18),
          label: const Text('Open as overlay'),
        ),
      ],
    );
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet();

  Widget _content(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Share', style: Theme.of(context).textTheme.titleMedium),
        const ListTile(leading: Icon(Icons.link), title: Text('Copy link')),
        const ListTile(
          leading: Icon(Icons.mail_outline),
          title: Text('Send email'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BottomSheet(
          onClosing: () {},
          enableDrag: false,
          showDragHandle: true,
          builder: _content,
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            showDragHandle: true,
            builder: _content,
          ),
          icon: const Icon(Icons.open_in_new, size: 18),
          label: const Text('Open as overlay'),
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Column(
        children: [
          AppBar(
            primary: false,
            leading: const BackButton(),
            title: const Text('Orders'),
            actions: [
              IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
              IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
            ],
          ),
          Container(
            height: 60,
            alignment: Alignment.center,
            color: Theme.of(context).colorScheme.surface,
            child: const Text('Page content'),
          ),
        ],
      ),
    );
  }
}

class _NavBar extends StatefulWidget {
  const _NavBar();

  @override
  State<_NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<_NavBar> {
  int _i = 0;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: NavigationBar(
        selectedIndex: _i,
        onDestinationSelected: (i) => setState(() => _i = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Badge(label: Text('3'), child: Icon(Icons.inbox_outlined)),
            label: 'Inbox',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _Rail extends StatefulWidget {
  const _Rail();

  @override
  State<_Rail> createState() => _RailState();
}

class _RailState extends State<_Rail> {
  int _i = 0;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 260,
        child: Row(
          children: [
            NavigationRail(
              selectedIndex: _i,
              onDestinationSelected: (i) => setState(() => _i = i),
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  label: Text('Dashboard'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  label: Text('Orders'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings_outlined),
                  label: Text('Settings'),
                ),
              ],
            ),
            const VerticalDivider(width: 1),
            const Expanded(child: Center(child: Text('Content'))),
          ],
        ),
      ),
    );
  }
}

class _Tiles extends StatefulWidget {
  const _Tiles();

  @override
  State<_Tiles> createState() => _TilesState();
}

class _TilesState extends State<_Tiles> {
  bool _on = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.person_outline),
          title: const Text('Profile'),
          subtitle: const Text('Name, photo and contacts'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
        ListTile(
          selected: true,
          leading: const Icon(Icons.notifications_outlined),
          title: const Text('Notifications (selected)'),
          subtitle: const Text('Push and email'),
          onTap: () {},
        ),
        SwitchListTile(
          secondary: const Icon(Icons.dark_mode_outlined),
          title: const Text('Dark theme'),
          value: _on,
          onChanged: (v) => setState(() => _on = v),
        ),
        const ListTile(
          enabled: false,
          leading: Icon(Icons.lock_outline),
          title: Text('Disabled'),
        ),
      ],
    );
  }
}

class _Dividers extends StatelessWidget {
  const _Dividers();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Section one'),
        Divider(),
        Text('Section two'),
        Divider(),
        SizedBox(
          height: 32,
          child: Row(
            children: [Text('Left'), VerticalDivider(), Text('Right')],
          ),
        ),
      ],
    );
  }
}

/// SnackBar inside a local Scaffold, so it uses the preview theme.
class _Snack extends StatefulWidget {
  const _Snack();

  @override
  State<_Snack> createState() => _SnackState();
}

class _SnackState extends State<_Snack> {
  final _messenger = GlobalKey<ScaffoldMessengerState>();

  void _show() {
    _messenger.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Order #1048 archived'),
          action: SnackBarAction(label: 'Cancel', onPressed: () {}),
          duration: const Duration(days: 1),
        ),
      );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _show());
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: ScaffoldMessenger(
          key: _messenger,
          child: Scaffold(
            body: Center(
              child: OutlinedButton(
                onPressed: _show,
                child: const Text('Show again'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Fabs extends StatelessWidget {
  const _Fabs();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        FloatingActionButton(
          heroTag: null,
          onPressed: () {},
          child: const Icon(Icons.add),
        ),
        FloatingActionButton.small(
          heroTag: null,
          onPressed: () {},
          child: const Icon(Icons.edit_outlined),
        ),
        FloatingActionButton.extended(
          heroTag: null,
          onPressed: () {},
          icon: const Icon(Icons.add),
          label: const Text('New customer'),
        ),
      ],
    );
  }
}

/// The real tooltip only appears on hover: below there's also a static
/// copy built with the same TooltipThemeData.
class _Tooltips extends StatelessWidget {
  const _Tooltips();

  @override
  Widget build(BuildContext context) {
    final tip = TooltipTheme.of(context);
    final t = Theme.of(context);
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding:
              tip.padding ??
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration:
              tip.decoration ??
              BoxDecoration(
                color: t.colorScheme.inverseSurface,
                borderRadius: BorderRadius.circular(4),
              ),
          child: Text(
            'Copy the link to the clipboard',
            style:
                tip.textStyle ??
                t.textTheme.bodySmall?.copyWith(
                  color: t.colorScheme.onInverseSurface,
                ),
          ),
        ),
        Tooltip(
          message: 'Real tooltip (hover)',
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.info_outline, size: 18),
            label: const Text('Hover me'),
          ),
        ),
      ],
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Orders'),
              Tab(text: 'Customers'),
            ],
          ),
          const SizedBox(height: 16),
          const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.dashboard_outlined), text: 'With icon'),
              Tab(icon: Icon(Icons.inbox_outlined), text: 'Inbox'),
              Tab(icon: Icon(Icons.person_outline), text: 'Profile'),
            ],
          ),
          SizedBox(
            height: 60,
            child: TabBarView(
              children: [
                for (final l in ['Overview', 'Orders', 'Customers'])
                  Center(child: Text('Content $l')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chips extends StatefulWidget {
  const _Chips();

  @override
  State<_Chips> createState() => _ChipsState();
}

class _ChipsState extends State<_Chips> {
  int _choice = 0;
  final Set<int> _filters = {1};

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (i, l) in const ['Day', 'Week', 'Month'].indexed)
              ChoiceChip(
                label: Text(l),
                selected: _choice == i,
                onSelected: (_) => setState(() => _choice = i),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (i, l) in const [
              'Shipping',
              'Pickup',
              'Express',
            ].indexed)
              FilterChip(
                label: Text(l),
                selected: _filters.contains(i),
                onSelected: (on) =>
                    setState(() => on ? _filters.add(i) : _filters.remove(i)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            const Chip(label: Text('Chip')),
            InputChip(
              avatar: const CircleAvatar(child: Text('G')),
              label: const Text('Emma'),
              onDeleted: () {},
            ),
            ActionChip(
              avatar: const Icon(Icons.event_outlined),
              label: const Text('Schedule'),
              onPressed: () {},
            ),
            const Chip(label: Text('Disabled'), avatar: Icon(Icons.block)),
          ],
        ),
      ],
    );
  }
}

class _Badges extends StatelessWidget {
  const _Badges();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 24,
      runSpacing: 16,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Badge(label: Text('3'), child: Icon(Icons.notifications_outlined)),
        Badge(label: Text('128'), child: Icon(Icons.inbox_outlined)),
        Badge(child: Icon(Icons.chat_bubble_outline)),
        Badge(label: Text('NEW')),
      ],
    );
  }
}

class _Menus extends StatelessWidget {
  const _Menus();

  @override
  Widget build(BuildContext context) {
    final menuTheme = MenuTheme.of(context).style;
    final items = [
      MenuItemButton(
        leadingIcon: const Icon(Icons.edit_outlined, size: 18),
        onPressed: () {},
        child: const Text('Edit'),
      ),
      MenuItemButton(
        leadingIcon: const Icon(Icons.copy_outlined, size: 18),
        onPressed: () {},
        child: const Text('Duplicate'),
      ),
      MenuItemButton(
        leadingIcon: const Icon(Icons.archive_outlined, size: 18),
        onPressed: () {},
        child: const Text('Archive'),
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Static copy of the panel, with the theme's same MenuStyle.
        SizedBox(
          width: 240,
          child: Material(
            color:
                menuTheme?.backgroundColor?.resolve({}) ??
                Theme.of(context).colorScheme.surfaceContainer,
            elevation: menuTheme?.elevation?.resolve({}) ?? 3,
            shape:
                menuTheme?.shape?.resolve({}) ??
                const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
            child: Padding(
              padding:
                  menuTheme?.padding?.resolve({}) ??
                  const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: items,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            MenuAnchor(
              menuChildren: items,
              builder: (context, menu, _) => OutlinedButton(
                onPressed: () => menu.isOpen ? menu.close() : menu.open(),
                child: const Text('MenuAnchor'),
              ),
            ),
            PopupMenuButton<int>(
              tooltip: 'PopupMenuButton',
              itemBuilder: (_) => const [
                PopupMenuItem(value: 1, child: Text('Print')),
                PopupMenuItem(value: 2, child: Text('Duplicate')),
                PopupMenuItem(value: 3, child: Text('Archive')),
              ],
            ),
            const DropdownMenu<int>(
              initialSelection: 1,
              dropdownMenuEntries: [
                DropdownMenuEntry(value: 1, label: 'Italy'),
                DropdownMenuEntry(value: 2, label: 'Switzerland'),
                DropdownMenuEntry(value: 3, label: 'France'),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

/// Checkbox, radio, switch and slider in every state.
class _Controls extends StatefulWidget {
  const _Controls();

  @override
  State<_Controls> createState() => _ControlsState();
}

class _ControlsState extends State<_Controls> {
  bool? _check = true;
  bool _check2 = false;
  int _radio = 1;
  bool _switch = true;
  double _slider = 0.4;
  RangeValues _range = const RangeValues(0.2, 0.7);
  double _discrete = 3;

  @override
  Widget build(BuildContext context) {
    final caption = Theme.of(context).textTheme.labelSmall;
    Widget labeled(String label, Widget child) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
        Text(label, style: caption),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            labeled(
              'Selected',
              Checkbox(
                value: _check,
                tristate: true,
                onChanged: (v) => setState(() => _check = v),
              ),
            ),
            labeled(
              'Empty',
              Checkbox(
                value: _check2,
                onChanged: (v) => setState(() => _check2 = v!),
              ),
            ),
            labeled('Disabled', const Checkbox(value: true, onChanged: null)),
            labeled(
              'Disabled, empty',
              const Checkbox(value: false, onChanged: null),
            ),
            labeled(
              'Error',
              Checkbox(value: false, isError: true, onChanged: (_) {}),
            ),
          ],
        ),
        const SizedBox(height: 8),
        RadioGroup<int>(
          groupValue: _radio,
          onChanged: (v) => setState(() => _radio = v!),
          child: Wrap(
            spacing: 8,
            children: [
              labeled('One', const Radio(value: 1)),
              labeled('Two', const Radio(value: 2)),
              labeled('Disabled', const Radio(value: 3, enabled: false)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            labeled(
              'On',
              AppSwitch(
                value: _switch,
                onChanged: (v) => setState(() => _switch = v),
              ),
            ),
            labeled(
              'Off',
              AppSwitch(
                value: !_switch,
                onChanged: (v) => setState(() => _switch = !v),
              ),
            ),
            labeled('Disabled', const AppSwitch(value: true, onChanged: null)),
          ],
        ),
        const SizedBox(height: 8),
        Slider(value: _slider, onChanged: (v) => setState(() => _slider = v)),
        Slider(
          value: _discrete,
          min: 0,
          max: 5,
          divisions: 5,
          label: _discrete.round().toString(),
          onChanged: (v) => setState(() => _discrete = v),
        ),
        const Slider(value: 0.6, onChanged: null),
        RangeSlider(
          values: _range,
          onChanged: (v) => setState(() => _range = v),
        ),
      ],
    );
  }
}

/// A small dashboard (like the shadcn configurator preview):
/// large cards, inner tiles, bar chart and progress bars.
/// Shows where backgrounds, surfaces, muted, borders and secondary text apply.
class DashboardShowcase extends StatefulWidget {
  const DashboardShowcase({super.key});

  @override
  State<DashboardShowcase> createState() => _DashboardShowcaseState();
}

class _DashboardShowcaseState extends State<DashboardShowcase> {
  double _threshold = 0.25;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;
    final muted = t.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant);
    final caption = t.textTheme.labelSmall?.copyWith(
      color: cs.onSurfaceVariant,
      letterSpacing: 0.6,
    );

    Widget card({
      required String title,
      String? subtitle,
      required List<Widget> children,
      Widget? action,
    }) => Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: t.textTheme.titleSmall),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle, style: muted),
                      ],
                    ],
                  ),
                ),
                ?action,
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );

    // Riquadro interno su muted (bg-muted / surfaceContainerHighest).
    Widget tile(String label, String value, {double? progress}) => Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: caption),
          const SizedBox(height: 6),
          // titleMedium: with Material 3, titleLarge (22px) would wrap.
          Text(
            value,
            style: t.textTheme.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (progress != null) ...[
            const SizedBox(height: 10),
            LinearProgressIndicator(value: progress),
          ],
        ],
      ),
    );

    const bars = [0.35, 0.55, 0.42, 0.68, 0.5, 0.82];
    const months = ['Dec', 'Jan', 'Feb', 'Mar', 'Apr', 'May'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          SizedBox(
            width: 250,
            child: card(
              title: 'Sales trend',
              subtitle: 'Last 6 months',
              children: [
                SizedBox(
                  height: 110,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var i = 0; i < bars.length; i++)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  height: 86 * bars[i],
                                  decoration: BoxDecoration(
                                    // Like "Chart color = base color".
                                    color: cs.onSurfaceVariant.withValues(
                                      alpha: 0.55,
                                    ),
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(4),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(months[i], style: caption),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: tile('Upcoming', 'May 25')),
                    const SizedBox(width: 10),
                    Expanded(child: tile('Plan', 'Pro')),
                  ],
                ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: () {},
                  child: const Text('View report'),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 250,
            child: card(
              title: 'Payment threshold',
              subtitle: 'Minimum amount before the transfer',
              action: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.close, size: 18),
              ),
              children: [
                const TextField(
                  decoration: InputDecoration(hintText: 'EUR — Euro'),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Minimum amount',
                        style: t.textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      '€${(50 + _threshold * 9950).round()}',
                      style: t.textTheme.titleMedium,
                    ),
                  ],
                ),
                Slider(
                  value: _threshold,
                  onChanged: (v) => setState(() => _threshold = v),
                ),
                const TextField(
                  maxLines: 2,
                  decoration: InputDecoration(hintText: 'Payment notes…'),
                ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: () {},
                  child: const Text('Save threshold'),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 250,
            child: card(
              title: 'Goals',
              subtitle: '2025 milestones',
              action: OutlinedButton(
                onPressed: () {},
                child: const Text('New'),
              ),
              children: [
                tile('Retirement', '€420,000', progress: 0.65),
                const SizedBox(height: 10),
                tile('Home', '€85,000', progress: 0.32),
                const SizedBox(height: 12),
                Text("You haven't reached your goals yet.", style: muted),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
