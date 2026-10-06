import 'package:flutter/material.dart';

import 'feed.dart';

export 'chat_panel.dart';
export 'feed.dart';
export 'realtime_actions.dart';
export 'right_panel.dart';
export 'top_bar.dart';

/// Composition widget for home content.
class HomeContent extends StatelessWidget {
  const HomeContent({
    super.key,
    required this.controller,
    required this.compact,
    required this.mobile,
    required this.profile,
  });

  final ScrollController controller;
  final bool compact;
  final bool mobile;
  final Map<String, dynamic>? profile;

  @override
  Widget build(BuildContext context) => HomeFeed(
        controller: controller,
        compact: compact,
        mobile: mobile,
        profile: profile,
      );
}
