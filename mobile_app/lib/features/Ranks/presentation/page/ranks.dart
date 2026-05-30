import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_app/bloc/index.dart';
import 'package:mobile_app/models/index.dart';
import 'package:mobile_app/features/Ranks/presentation/widgets/horizontalWidget.dart';
import 'package:mobile_app/features/Ranks/presentation/widgets/verticalWidget.dart';

class RanksPage extends StatefulWidget {
  const RanksPage({super.key});

  @override
  State<RanksPage> createState() => _RanksPageState();
}

class _RanksPageState extends State<RanksPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    context.read<LeaderboardBloc>().add(const LeaderboardFetchEvent());
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: BlocBuilder<LeaderboardBloc, LeaderboardState>(
        builder: (context, state) {
          final entries = state is LeaderboardLoaded
              ? state.entries
              : <LeaderboardEntry>[];

          final first = entries.length > 0 ? entries[0] : null;
          final second = entries.length > 1 ? entries[1] : null;
          final third = entries.length > 2 ? entries[2] : null;
          final rest = entries.length > 3
              ? entries.sublist(3)
              : <LeaderboardEntry>[];
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              if (state is LeaderboardLoading)
                Expanded(child: _buildLoadingState())
              else if (state is LeaderboardFailure)
                Expanded(child: _buildErrorState(state.message))
              else if (entries.isEmpty)
                Expanded(child: _buildEmptyState())
              else
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Transform.translate(
                        offset: const Offset(0, -38),
                        child: _buildPodium(
                          first: first,
                          second: second,
                          third: third,
                        ),
                      ),
                      FadeTransition(
                        opacity: Tween<double>(
                          begin: 0,
                          end: 1,
                        ).animate(
                          CurvedAnimation(
                            parent: _controller,
                            curve: const Interval(
                              0.4,
                              0.7,
                              curve: Curves.easeOut,
                            ),
                          ),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.fromLTRB(20, 0, 0, 16),
                          child: Text(
                            'All Rankings',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: SlideTransition(
                          position:
                              Tween<Offset>(
                                begin: const Offset(-0.3, 0),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: _controller,
                                  curve: const Interval(
                                    0.5,
                                    0.9,
                                    curve: Curves.easeOutCubic,
                                  ),
                                ),
                              ),
                          child: FadeTransition(
                            opacity: Tween<double>(
                              begin: 0,
                              end: 1,
                            ).animate(
                              CurvedAnimation(
                                parent: _controller,
                                curve: const Interval(
                                  0.5,
                                  0.9,
                                  curve: Curves.easeOut,
                                ),
                              ),
                            ),
                            child: ListView.builder(
                              padding: const EdgeInsets.only(bottom: 16),
                              itemCount: rest.length,
                              itemBuilder: (context, index) {
                                final entry = rest[index];
                                return hozrizontalWidget(
                                  name: entry.username,
                                  points: entry.points.toString(),
                                  image: entry.avatarUrl,
                                  level: ((entry.points ~/ 500) + 1)
                                      .toString(),
                                  rank: entry.rank.toString(),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 180),
          decoration: const BoxDecoration(
            color: Color(0xFF3F6EDC),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
        ),
        Positioned(
          top: -40,
          right: -30,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: -40,
          left: -30,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 18, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('🏆', style: TextStyle(fontSize: 28)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Leaderboard',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  'Top civic heroes this month',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPodium({
    required LeaderboardEntry? first,
    required LeaderboardEntry? second,
    required LeaderboardEntry? third,
  }) {
    return SizedBox(
      height: 280,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(-0.5, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _controller,
                    curve: const Interval(
                      0.2,
                      0.5,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                ),
            child: FadeTransition(
              opacity: Tween<double>(begin: 0, end: 1).animate(
                CurvedAnimation(
                  parent: _controller,
                  curve: const Interval(0.2, 0.5, curve: Curves.easeOut),
                ),
              ),
              child: verticalWidget(
                name: second?.username ?? 'N/A',
                points: (second?.points ?? 0).toString(),
                image: second?.avatarUrl,
                level: (((second?.points ?? 0) ~/ 500) + 1).toString(),
                rank: (second?.rank ?? 2).toString(),
                badgeColor: const Color(0xFF3F6EDC),
              ),
            ),
          ),
          ScaleTransition(
            scale: Tween<double>(begin: 0, end: 1).animate(
              CurvedAnimation(
                parent: _controller,
                curve: const Interval(0.1, 0.6, curve: Curves.elasticOut),
              ),
            ),
            child: FadeTransition(
              opacity: Tween<double>(begin: 0, end: 1).animate(
                CurvedAnimation(
                  parent: _controller,
                  curve: const Interval(0.1, 0.5, curve: Curves.easeOut),
                ),
              ),
              child: verticalWidget(
                name: first?.username ?? 'N/A',
                points: (first?.points ?? 0).toString(),
                image: first?.avatarUrl,
                level: (((first?.points ?? 0) ~/ 500) + 1).toString(),
                rank: (first?.rank ?? 1).toString(),
                badgeColor: Colors.amber,
              ),
            ),
          ),
          SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0.5, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _controller,
                    curve: const Interval(
                      0.3,
                      0.6,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                ),
            child: FadeTransition(
              opacity: Tween<double>(begin: 0, end: 1).animate(
                CurvedAnimation(
                  parent: _controller,
                  curve: const Interval(0.3, 0.6, curve: Curves.easeOut),
                ),
              ),
              child: verticalWidget(
                name: third?.username ?? 'N/A',
                points: (third?.points ?? 0).toString(),
                image: third?.avatarUrl,
                level: (((third?.points ?? 0) ~/ 500) + 1).toString(),
                rank: (third?.rank ?? 3).toString(),
                badgeColor: const Color(0xFF3F6EDC),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 18),
            Text(
              'Loading leaderboard...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    final errorUi = _leaderboardErrorUi(message);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: errorUi.iconBackgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  errorUi.icon,
                  color: errorUi.iconColor,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                errorUi.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                errorUi.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: () {
                  context.read<LeaderboardBloc>().add(
                    const LeaderboardFetchEvent(),
                  );
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: errorUi.buttonColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 40,
              color: Color(0xFF94A3B8),
            ),
            SizedBox(height: 14),
            Text(
              'No rankings available yet.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'The backend is reachable, but there are no leaderboard records to show yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  _LeaderboardErrorUi _leaderboardErrorUi(String message) {
    final normalized = message.toLowerCase();

    if (normalized.contains('endpoint is not available') ||
        normalized.contains('404')) {
      return const _LeaderboardErrorUi(
        title: 'Leaderboard backend is missing',
        description:
            'This app could reach the server, but the leaderboard endpoint is not available there yet.',
        icon: Icons.route_outlined,
        iconColor: Color(0xFF2563EB),
        iconBackgroundColor: Color(0xFFDBEAFE),
        buttonColor: Color(0xFF2563EB),
      );
    }

    if (normalized.contains('backend server') ||
        normalized.contains('unable to reach') ||
        normalized.contains('clientexception') ||
        normalized.contains('socketexception')) {
      return const _LeaderboardErrorUi(
        title: 'Backend is unreachable',
        description:
            'The leaderboard service could not be reached. Make sure the backend is running and the app is pointing to the right URL.',
        icon: Icons.wifi_off_rounded,
        iconColor: Color(0xFF3B82F6),
        iconBackgroundColor: Color(0xFFDBEAFE),
        buttonColor: Color(0xFF3F6EDC),
      );
    }

    if (normalized.contains('backend setup') ||
        normalized.contains('server logs') ||
        normalized.contains('status: 500') ||
        normalized.contains('status: 502') ||
        normalized.contains('status: 503')) {
      return const _LeaderboardErrorUi(
        title: 'Leaderboard service failed',
        description:
            'The backend responded with a server error. This usually means the service is misconfigured or failed while reading leaderboard data.',
        icon: Icons.dns_outlined,
        iconColor: Color(0xFFF97316),
        iconBackgroundColor: Color(0xFFFFEDD5),
        buttonColor: Color(0xFFF97316),
      );
    }

    return const _LeaderboardErrorUi(
      title: 'Couldn\'t load the leaderboard',
      description:
          'Something went wrong while loading leaderboard data. Please try again in a moment.',
      icon: Icons.error_outline,
      iconColor: Color(0xFF3B82F6),
      iconBackgroundColor: Color(0xFFDBEAFE),
      buttonColor: Color(0xFF3F6EDC),
    );
  }
}

class _LeaderboardErrorUi {
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final Color buttonColor;

  const _LeaderboardErrorUi({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.buttonColor,
  });
}
