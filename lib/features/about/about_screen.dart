import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';

/// About / Credits screen.
///
/// Displays the application identity and the legally relevant attribution.
/// Websites are shown as selectable text (no external launcher dependency is
/// introduced in this phase).
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                const Icon(Icons.lock_outline, size: 64),
                const SizedBox(height: 12),
                Text(
                  AppInfo.appName,
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(AppInfo.packageId, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _Section(
            title: 'Attribution',
            child: SelectableText(AppInfo.attribution),
          ),
          const Divider(height: 32),
          _Section(
            title: 'Developed by',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(AppInfo.developer),
                SizedBox(height: 4),
                Text(AppInfo.company),
              ],
            ),
          ),
          const Divider(height: 32),
          const _Section(
            title: 'Application website',
            child: SelectableText(AppInfo.appWebsite),
          ),
          const SizedBox(height: 12),
          const _Section(
            title: 'Developer website',
            child: SelectableText(AppInfo.developerWebsite),
          ),
          const SizedBox(height: 12),
          const _Section(
            title: 'Company website',
            child: SelectableText(AppInfo.companyWebsite),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
