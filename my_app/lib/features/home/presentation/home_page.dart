import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_navigation_shell.dart';
import '../../posts/presentation/create_post_page.dart';
import '../../profile/data/profile_repository.dart';
import 'widgets/home_content.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.profileStream});

  final Stream<Map<String, dynamic>?>? profileStream;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final ScrollController _pageController = ScrollController();
  late Stream<Map<String, dynamic>?> _profileStream;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _profileStream = _createProfileStream();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      setState(() {
        _profileStream = _createProfileStream();
      });
    }
  }

  Stream<Map<String, dynamic>?> _createProfileStream() =>
      widget.profileStream ?? ProfileRepository().watchCurrentProfile();

  @override
  Widget build(BuildContext context) => StreamBuilder<Map<String, dynamic>?>(
        stream: _profileStream,
        builder: (context, profileSnapshot) => LayoutBuilder(
          builder: (context, size) {
            final desktop = size.maxWidth >= 1180;
            final tablet = size.maxWidth >= 760 && !desktop;

            return MainShell(
              selectedIndex: 0,
              showRightPanel: desktop,
              rightPanel: HomeRightPanel(profile: profileSnapshot.data),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () => showCreatePostComposer(context),
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add_rounded),
                label: const Text(
                  'Tạo',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context)
                    .copyWith(scrollbars: false),
                child: HomeFeed(
                  controller: _pageController,
                  compact: !desktop,
                  mobile: !desktop && !tablet,
                  profile: profileSnapshot.data,
                ),
              ),
            );
          },
        ),
      );
}
