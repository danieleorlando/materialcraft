import 'package:material_ui/material_ui.dart';

import 'storage/storage.dart';

const authorSite = 'https://danieleorlando.me';
const authorLinkedIn = 'https://www.linkedin.com/in/daniele-orlando-2b491014/';
const repoUrl = 'https://github.com/danieleorlando/materialcraft';

/// Who made MaterialCraft, what he offers and how to reach him.
Future<void> showAboutMaterialCraft(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _AboutDialog(),
  );
}

class _AboutDialog extends StatelessWidget {
  const _AboutDialog();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: cs.onSurfaceVariant,
    );
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'MaterialCraft',
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'A free, open source theme editor for Flutter Material 3. '
                'Design the theme visually and export clean Dart code that '
                'stays on top of Material.',
                style: muted,
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                onPressed: () => openUrl(repoUrl),
                icon: const Icon(Icons.star_outline, size: 18),
                label: const Text('Source code and a star on GitHub'),
              ),
              const Divider(height: 32),
              Text(
                'Made by Daniele Orlando',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                "I'm a developer by trade and a maker by choice. I build "
                'iOS, Android and web apps with founders and companies, from '
                'the first idea to the store, and I ship my own products too, '
                'like PureContact, used by tens of thousands of people.',
                style: muted,
              ),
              const SizedBox(height: 16),
              Text('How I can help', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              const _Service(
                icon: Icons.phone_iphone,
                title: 'Mobile apps',
                text: 'iOS and Android apps, from design to the stores.',
              ),
              const _Service(
                icon: Icons.web,
                title: 'Web apps',
                text: 'From internal tools to SaaS platforms.',
              ),
              const _Service(
                icon: Icons.rocket_launch_outlined,
                title: 'MVPs',
                text: 'Working prototypes to test the market fast.',
              ),
              const _Service(
                icon: Icons.lightbulb_outline,
                title: 'Consulting',
                text: 'Feasibility, technology choices, app reviews, roadmaps.',
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () => openUrl(authorSite),
                    icon: const Icon(Icons.handshake_outlined, size: 18),
                    label: const Text('Work with me'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => openUrl(authorLinkedIn),
                    icon: const Icon(Icons.person_outline, size: 18),
                    label: const Text('LinkedIn'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Service extends StatelessWidget {
  const _Service({required this.icon, required this.title, required this.text});

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: cs.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: '$title  ',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                children: [
                  TextSpan(
                    text: text,
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
