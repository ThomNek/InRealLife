import 'package:flutter/material.dart';

import 'profile_activity.dart';
import 'profile_header.dart';
import 'profile_info.dart';
import 'profile_showcase.dart';
import 'profile_stats.dart';

export 'profile_activity.dart';
export 'profile_header.dart';
export 'profile_info.dart';
export 'profile_showcase.dart';
export 'profile_stats.dart';

/// Modular composite wrapper for Profile Content
class ProfileContent extends StatelessWidget {
  const ProfileContent({super.key, this.profile});

  final Map<String, dynamic>? profile;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          ProfileHeader(profile: profile),
          const SizedBox(height: 16),
          ProfileInfo(profile: profile),
          const SizedBox(height: 16),
          ProfileStats(profile: profile),
          const SizedBox(height: 16),
          ProfileShowcase(profile: profile),
          const SizedBox(height: 16),
          const ProfileActivity(),
        ],
      );
}
