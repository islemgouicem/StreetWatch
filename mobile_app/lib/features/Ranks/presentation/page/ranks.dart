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

  static const String _fallbackAvatar = 'lounis.png';

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
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
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
              Stack(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        height: 180,
                        decoration: const BoxDecoration(
                          color: Color(0xFF3F6EDC),
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(30),
                          ),
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
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 30),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🏆 Leaderboard',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Top civic heroes this month',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (state is LeaderboardLoading)
                    const Positioned.fill(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (state is LeaderboardFailure)
                    Positioned.fill(
                      child: Center(
                        child: Text(
                          'Failed to load leaderboard',
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(top: 120),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                                  curve: const Interval(
                                    0.2,
                                    0.5,
                                    curve: Curves.easeOut,
                                  ),
                                ),
                              ),
                              child: verticalWidget(
                                name: second?.username ?? 'N/A',
                                points: (second?.points ?? 0).toString(),
                                image: _fallbackAvatar,
                                level: (((second?.points ?? 0) ~/ 500) + 1)
                                    .toString(),
                                rank: (second?.rank ?? 2).toString(),
                                badgeColor: const Color(0xFF3F6EDC),
                              ),
                            ),
                          ),
                          ScaleTransition(
                            scale: Tween<double>(begin: 0, end: 1).animate(
                              CurvedAnimation(
                                parent: _controller,
                                curve: const Interval(
                                  0.1,
                                  0.6,
                                  curve: Curves.elasticOut,
                                ),
                              ),
                            ),
                            child: FadeTransition(
                              opacity: Tween<double>(begin: 0, end: 1).animate(
                                CurvedAnimation(
                                  parent: _controller,
                                  curve: const Interval(
                                    0.1,
                                    0.5,
                                    curve: Curves.easeOut,
                                  ),
                                ),
                              ),
                              child: verticalWidget(
                                name: first?.username ?? 'N/A',
                                points: (first?.points ?? 0).toString(),
                                image: _fallbackAvatar,
                                level: (((first?.points ?? 0) ~/ 500) + 1)
                                    .toString(),
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
                                  curve: const Interval(
                                    0.3,
                                    0.6,
                                    curve: Curves.easeOut,
                                  ),
                                ),
                              ),
                              child: verticalWidget(
                                name: third?.username ?? 'N/A',
                                points: (third?.points ?? 0).toString(),
                                image: _fallbackAvatar,
                                level: (((third?.points ?? 0) ~/ 500) + 1)
                                    .toString(),
                                rank: (third?.rank ?? 3).toString(),
                                badgeColor: const Color(0xFF3F6EDC),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              FadeTransition(
                opacity: Tween<double>(begin: 0, end: 1).animate(
                  CurvedAnimation(
                    parent: _controller,
                    curve: const Interval(0.4, 0.7, curve: Curves.easeOut),
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 0, 16),
                  child: Text('All Rankings'),
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
                    opacity: Tween<double>(begin: 0, end: 1).animate(
                      CurvedAnimation(
                        parent: _controller,
                        curve: const Interval(0.5, 0.9, curve: Curves.easeOut),
                      ),
                    ),
                    child: ListView.builder(
                      itemCount: rest.length,
                      itemBuilder: (context, index) {
                        final entry = rest[index];
                        return hozrizontalWidget(
                          name: entry.username,
                          points: entry.points.toString(),
                          image: _fallbackAvatar,
                          level: ((entry.points ~/ 500) + 1).toString(),
                          rank: entry.rank.toString(),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
