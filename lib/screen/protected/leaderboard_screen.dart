import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/leaderboard_service.dart';
import '../../models/leaderboard_model.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardSkeleton extends StatelessWidget {
  const _LeaderboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Podium skeleton
        Row(
          children: const [
            _SkeletonBox(width: 0, height: 0), // spacer placeholder not used
          ],
        ),
        Row(
          children: const [
            Expanded(child: _SkeletonCard(height: 100)),
            SizedBox(width: 12),
            Expanded(child: _SkeletonCard(height: 100)),
            SizedBox(width: 12),
            Expanded(child: _SkeletonCard(height: 100)),
          ],
        ),
        const SizedBox(height: 16),
        // List skeleton
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF121212),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            children: List.generate(8, (i) => const _SkeletonListTile()),
          ),
        ),
      ],
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final String? url;
  final double size;
  const _UserAvatar({required this.url, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final hasAvatar = url != null && url!.isNotEmpty;
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: Colors.white24,
      backgroundImage: hasAvatar ? NetworkImage(url!) : null,
      child: hasAvatar
          ? null
          : Icon(Icons.person, color: Colors.white54, size: size / 2),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  final double height;
  const _SkeletonCard({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
    );
  }
}

class _SkeletonListTile extends StatelessWidget {
  const _SkeletonListTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 12, width: 140, color: Colors.white10),
                const SizedBox(height: 6),
                Container(height: 10, width: 80, color: Colors.white10),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white24),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  const _SkeletonBox({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(width: width, height: height, color: Colors.white10);
  }
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  String _scope = 'Harian'; // Harian, Mingguan, Bulanan
  late Future<LeaderboardResponseModel> _future;
  

  String _scopeToPeriod(String scope) {
    switch (scope) {
      case 'Mingguan':
        return 'weekly';
      case 'Bulanan':
        return 'monthly';
      case 'Harian':
      default:
        return 'daily';
    }
  }

  void _loadData() {
    _future = LeaderboardService.getLeaderboard(
      period: _scopeToPeriod(_scope),
      limit: 50,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          'Leaderboard Level',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Info card about benefits
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF121212),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.amber.withOpacity(0.35)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.emoji_events, color: Colors.amber),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Raih Top 1 ~ 3 Bulanan',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Naikkan level dan XP kamu setiap hari. Top 1 ~ 3 Bulanan mendapatkan benefit spesial.',
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Scope selector
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ScopeChip(
                  label: 'Harian',
                  selected: _scope == 'Harian',
                  onTap: () => setState(() {
                    _scope = 'Harian';
                    _loadData();
                  }),
                ),
                const SizedBox(width: 8),
                _ScopeChip(
                  label: 'Mingguan',
                  selected: _scope == 'Mingguan',
                  onTap: () => setState(() {
                    _scope = 'Mingguan';
                    _loadData();
                  }),
                ),
                const SizedBox(width: 8),
                _ScopeChip(
                  label: 'Bulanan',
                  selected: _scope == 'Bulanan',
                  onTap: () => setState(() {
                    _scope = 'Bulanan';
                    _loadData();
                  }),
                ),
              ],
            ),
            const SizedBox(height: 16),

            const SizedBox(height: 16),

            // Data loader
            FutureBuilder<LeaderboardResponseModel>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const _LeaderboardSkeleton();
                }
                if (snap.hasError || snap.data?.data == null) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF121212),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Text(
                      'Gagal memuat leaderboard',
                      style: GoogleFonts.poppins(color: Colors.white70),
                    ),
                  );
                }
                final data = snap.data!.data!;
                final List<LeaderboardEntryModel> entries = List.from(data.entries);
                final top3 = entries.take(3).toList();
                final rest = entries.length > 3
                    ? entries.sublist(3)
                    : <LeaderboardEntryModel>[];

                return Column(
                  children: [
                    // Top 3 podium
                    _PodiumFromApi(topUsers: top3),
                    const SizedBox(height: 16),
                    // Leader list
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF121212),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: rest.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: Colors.white10),
                        itemBuilder: (context, index) {
                          final item = rest[index];
                          final rank = item.rank;
                          final name = (item.user.fullName?.isNotEmpty == true)
                              ? item.user.fullName!
                              : '@${item.user.username}';
                          return InkWell(
                            onTap: () {},
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 28,
                                    child: Text(
                                      '$rank',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      textAlign: TextAlign.left,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  _UserAvatar(
                                    url: item.user.avatarUrl,
                                    size: 40,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          '${item.totalXp} XP',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right,
                                    color: Colors.white54,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ScopeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ScopeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.amber.withOpacity(0.15) : Colors.white10,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? Colors.amber : Colors.white24),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;
  final String? avatarUrl;
  final double size;
  const _RankBadge({required this.rank, this.avatarUrl, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final hasAvatar = avatarUrl != null && avatarUrl!.isNotEmpty;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: size / 2,
          backgroundColor: Colors.white24,
          backgroundImage: hasAvatar ? NetworkImage(avatarUrl!) : null,
          child: hasAvatar
              ? null
              : Text(
                  '$rank',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.amber, width: 1.2),
            ),
            child: Text(
              '$rank',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PodiumFromApi extends StatelessWidget {
  final List<LeaderboardEntryModel> topUsers;
  const _PodiumFromApi({required this.topUsers});

  @override
  Widget build(BuildContext context) {
    List<Widget> tiles = [];
    for (final u in topUsers) {
      tiles.add(
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.symmetric(horizontal: 6),
            height: 140,
            decoration: BoxDecoration(
              color: const Color(0xFF121212),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                _RankBadge(rank: u.rank, avatarUrl: u.user.avatarUrl, size: 56),
                const SizedBox(height: 8),
                Text(
                  (u.user.fullName?.isNotEmpty == true)
                      ? u.user.fullName!
                      : '@${u.user.username}',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
                const SizedBox(height: 4),
                Text(
                  '${u.totalXp} XP',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(children: tiles);
  }
}
