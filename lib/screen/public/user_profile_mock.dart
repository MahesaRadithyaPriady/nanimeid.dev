import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../widgets/vip_badge.dart';
import '../../services/profile_service.dart';
import '../../models/profile_model.dart';

class UserProfileMockScreen extends StatefulWidget {
  final int userId;
  final String username; // kept for compatibility (used as fallback before data loads)
  final String? avatarUrl; // kept for compatibility
  final String vipLevel; // kept for compatibility

  const UserProfileMockScreen({
    super.key,
    required this.userId,
    required this.username,
    this.avatarUrl,
    this.vipLevel = '',
  });

  @override
  State<UserProfileMockScreen> createState() => _UserProfileMockScreenState();
}

class _UserProfileMockScreenState extends State<UserProfileMockScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  String? _error;
  PublicProfileAggregateModel? _data;
  late final AnimationController _vipCtrl;

  @override
  void initState() {
    super.initState();
    _fetch();
    _vipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ProfileService.getPublicProfileById(widget.userId);
      if (!mounted) return;
      if (res.isSuccess && res.profile != null) {
        setState(() {
          _data = res.profile;
          _loading = false;
        });
      } else {
        setState(() {
          _error = res.message.isNotEmpty ? res.message : 'Gagal memuat profil';
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Terjadi kesalahan saat memuat profil';
        _loading = false;
      });
    }
  }

  Color _vipAccent(String level) {
    switch (level.toLowerCase()) {
      case 'bronze':
        return const Color(0xFF8B4513);
      case 'silver':
        return const Color(0xFFC0C0C0);
      case 'gold':
        return Colors.amber;
      case 'diamond':
        return const Color(0xFF9C27B0);
      case 'master':
        return Colors.redAccent;
      default:
        return Colors.white12;
    }
  }

  String _displayName() {
    final full = _data?.profile.fullName ?? '';
    if (full.isNotEmpty) return full;
    final un = _data?.username ?? widget.username;
    return un.isNotEmpty ? un : 'Profil Pengguna';
  }

  String? _avatar() {
    return _data?.profile.avatarUrl ?? widget.avatarUrl;
  }

  String _vipLevel() {
    // Prefer VIP level from vip.vip_level (e.g., Master, Diamond)
    final vipLvl = _data?.vip?.vipLevel;
    if (vipLvl != null && vipLvl.isNotEmpty) return vipLvl.toLowerCase();
    // Fallback: some payloads may only provide a level title (e.g., Bronze)
    final title = _data?.level?.title;
    if (title != null && title.isNotEmpty) return title.toLowerCase();
    return widget.vipLevel.toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final name = _displayName();
    final avatarUrl = _avatar();
    final vipLevel = _vipLevel();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          name,
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        actions: [
          if (!_loading)
            IconButton(
              icon: const Icon(LucideIcons.refreshCw, color: Colors.white),
              onPressed: _fetch,
              tooltip: 'Muat ulang',
            )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.pinkAccent))
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _fetch)
              : _ProfileBody(
                  userId: widget.userId,
                  name: name,
                  avatarUrl: avatarUrl,
                  vipLevel: vipLevel,
                  stats: _data?.stats,
                  xp: _data?.xp,
                  level: _data?.level,
                  xpProgress: _data?.xpProgress,
                  bio: _data?.profile.bio,
                ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  final int userId;
  final String name;
  final String? avatarUrl;
  final String vipLevel;
  final PublicStatsModel? stats;
  final String? bio;
  final PublicXpLiteModel? xp;
  final PublicLevelLiteModel? level;
  final PublicXpProgressLiteModel? xpProgress;

  const _ProfileBody({
    required this.userId,
    required this.name,
    required this.avatarUrl,
    required this.vipLevel,
    required this.stats,
    required this.bio,
    required this.xp,
    required this.level,
    required this.xpProgress,
  });

  @override
  Widget build(BuildContext context) {
    final accent = _vipAccentStatic(vipLevel);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AvatarWithVipBorder(
                avatarUrl: avatarUrl,
                name: name,
                vipLevel: vipLevel,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name.isEmpty ? 'Pengguna' : name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (vipLevel.isNotEmpty) VipBadge(level: vipLevel),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ID: $userId',
                      style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _StatChip(icon: LucideIcons.messageCircle, label: 'Komentar', value: _fmt(stats?.commentsCount), accent: accent),
                        _StatChip(icon: LucideIcons.heart, label: 'Disukai', value: _fmt(stats?.likesReceived), accent: accent),
                        _StatChip(icon: LucideIcons.clapperboard, label: 'Menonton (mnt)', value: _fmt(stats?.minutesWatched), accent: accent),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // XP Level Section (Public)
          _buildXpCard(accent),
          const SizedBox(height: 24),
          Text('Tentang', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF121212),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withOpacity(0.35)),
            ),
            child: Text(
              (bio != null && bio!.isNotEmpty)
                  ? bio!
                  : 'Belum ada bio. Pengguna ini belum menambahkan informasi tentang dirinya.',
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  static String _fmt(int? n) => n == null ? '—' : n.toString();

  Widget _buildXpCard(Color accent) {
    // Use public aggregate data to render a simple level card
    final int? levelNumber = level?.levelNumber;
    final String levelTitle = (level?.title ?? '').toString();
    final int currentXp = xp?.currentXp ?? 0;
    final int totalRequired = level?.xpRequiredTotal ?? 0;
    // Prefer xp_progress percent_to_next; fallback to currentXp/totalRequired
    final double percent = xpProgress != null
        ? (xpProgress!.percentToNext / 100.0).clamp(0.0, 1.0)
        : (totalRequired > 0 ? (currentXp / totalRequired).clamp(0.0, 1.0) : 0.0);
    final int targetNext = xpProgress?.nextLevelRequired ?? (totalRequired > 0 ? totalRequired : 0);
    final int xpToNext = xpProgress?.xpToNext ?? (totalRequired > currentXp ? (totalRequired - currentXp) : 0);
    final int nextLevelNumber = xpProgress?.nextLevelNumber ?? ((levelNumber ?? 0) + 1);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, color: accent),
              const SizedBox(width: 8),
              Text(
                levelTitle.isNotEmpty ? levelTitle : 'Level',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (levelNumber != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: accent.withOpacity(0.7)),
                  ),
                  child: Text(
                    'Lv $levelNumber',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 10,
              backgroundColor: Colors.white12,
              color: accent,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'XP: $currentXp · Sisa: $xpToNext',
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
              ),
              Text(
                targetNext > 0 ? 'Target Lv $nextLevelNumber: $targetNext' : '—',
                style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.alertCircle, color: Colors.redAccent.shade200, size: 36),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(LucideIcons.refreshCw),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;
  const _StatChip({required this.icon, required this.label, required this.value, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withOpacity(0.6)),
      ),
      child: Row(
        children: [
          Icon(icon, color: accent, size: 16),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
          const SizedBox(width: 6),
          Text(value, style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// Helper to map vip level to accent for stateless usage
Color _vipAccentStatic(String level) {
  switch (level.toLowerCase()) {
    case 'bronze':
      return const Color(0xFF8B4513);
    case 'silver':
      return const Color(0xFFC0C0C0);
    case 'gold':
      return Colors.amber;
    case 'diamond':
      return const Color(0xFF9C27B0);
    case 'master':
      return Colors.redAccent;
    default:
      return Colors.white12;
  }
}

class _AvatarWithVipBorder extends StatelessWidget {
  final String? avatarUrl;
  final String name;
  final String vipLevel;
  const _AvatarWithVipBorder({required this.avatarUrl, required this.name, required this.vipLevel});

  @override
  Widget build(BuildContext context) {
    final level = vipLevel.toLowerCase();
    final core = CircleAvatar(
      radius: 36,
      backgroundColor: Colors.pinkAccent,
      backgroundImage: (avatarUrl != null && avatarUrl!.isNotEmpty)
          ? NetworkImage(avatarUrl!)
          : null,
      child: (avatarUrl == null || avatarUrl!.isEmpty)
          ? Text(
              (name.isNotEmpty ? name[0] : '?').toUpperCase(),
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );

    if (level == 'diamond' || level == 'master') {
      // Use a static sweep gradient without animation for simplicity in stateless context
      final colors = level == 'diamond'
          ? const [Color(0xFF9C27B0), Color(0xFFE040FB), Color(0xFF7E57C2), Color(0xFF9C27B0)]
          : const [Color(0xFFE53935), Color(0xFFFF7043), Color(0xFFD81B60), Color(0xFFE53935)];
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(colors: colors),
        ),
        padding: const EdgeInsets.all(2),
        child: ClipOval(child: core),
      );
    }

    final accent = _vipAccentStatic(level);
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: accent.withOpacity(level.isEmpty ? 0.2 : 0.8), width: 2),
      ),
      child: core,
    );
  }
}

