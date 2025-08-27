import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/home_header.dart';
import '../../services/profile_service.dart';
import '../../models/profile_model.dart';
import '../../services/vip_service.dart';
import '../../models/vip_model.dart';
import '../../widgets/exit_confirmation.dart';
import './account_settings_screen.dart';
import './membership_info_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late Future<ProfileResponseModel> _profileFuture;
  late Future<VipResponseModel> _vipFuture;
  late final AnimationController _diamondCtrl;

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

  Widget _buildStatusBadge(String text, String level) {
    final color = _vipAccent(level);
    if (level.toLowerCase() == 'diamond') {
      return AnimatedBuilder(
        animation: _diamondCtrl,
        builder: (context, _) {
          final angle = _diamondCtrl.value * 2 * math.pi;
          return Container(
            padding: const EdgeInsets.all(1.5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: SweepGradient(
                colors: const [
                  Color(0xFF9C27B0),
                  Color(0xFFE040FB),
                  Color(0xFF7E57C2),
                  Color(0xFF9C27B0),
                ],
                transform: GradientRotation(angle),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                text,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      );
    }
    if (level.toLowerCase() == 'master') {
      return AnimatedBuilder(
        animation: _diamondCtrl,
        builder: (context, _) {
          final angle = _diamondCtrl.value * 2 * math.pi;
          return Container(
            padding: const EdgeInsets.all(1.5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: SweepGradient(
                colors: const [
                  Color(0xFFE53935), // red
                  Color(0xFFFF7043), // deep orange
                  Color(0xFFD81B60), // pink
                  Color(0xFFE53935),
                ],
                transform: GradientRotation(angle),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.redAccent.withOpacity(0.35),
                  blurRadius: 10 + 6 * (0.5 + 0.5 * math.sin(angle)),
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                text,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: color is MaterialColor ? color.shade200 : color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadData();
    _diamondCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  void _loadData() {
    _profileFuture = ProfileService.getMyProfile();
    _vipFuture = VipService.getMyVip();
  }

  Future<void> _onRefresh() async {
    setState(() {
      _loadData();
    });
    // optionally wait for one of them to complete
    await Future.any([_profileFuture, _vipFuture]);
  }

  @override
  void dispose() {
    _diamondCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => showExitConfirmationDialog(context),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _onRefresh,
            color: Colors.pinkAccent,
            backgroundColor: Colors.black,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  const HomeHeader(coinBalance: 1000, isVip: true),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Profil Saya',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Profile info fetched from API
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: FutureBuilder<ProfileResponseModel>(
                      future: _profileFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const _ProfileSkeleton();
                        }
                        if (snapshot.hasError) {
                          return Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.redAccent,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Gagal memuat profil',
                                  style: GoogleFonts.poppins(
                                    color: Colors.redAccent,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }

                        final res = snapshot.data;
                        final profile = res?.profile;
                        if (res == null || profile == null) {
                          return Row(
                            children: [
                              const Icon(
                                Icons.person_outline,
                                color: Colors.white54,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Profil tidak tersedia',
                                style: GoogleFonts.poppins(
                                  color: Colors.white60,
                                ),
                              ),
                            ],
                          );
                        }

                        final initials = profile.fullName.isNotEmpty
                            ? profile.fullName.trim()[0].toUpperCase()
                            : 'U';

                        String? formattedBirthdate;
                        if (profile.birthdate != null) {
                          final d = profile.birthdate!.toLocal();
                          const months = [
                            'Jan',
                            'Feb',
                            'Mar',
                            'Apr',
                            'Mei',
                            'Jun',
                            'Jul',
                            'Agu',
                            'Sep',
                            'Okt',
                            'Nov',
                            'Des',
                          ];
                          formattedBirthdate =
                              '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
                        }

                        return FutureBuilder<VipResponseModel>(
                          future: _vipFuture,
                          builder: (context, vipSnap) {
                            final level = vipSnap.data?.vip?.vipLevel ?? '';
                            final borderColor = level.isEmpty
                                ? Colors.white10
                                : _vipAccent(level).withOpacity(0.35);
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF121212),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: borderColor),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 36,
                                        backgroundColor: Colors.pinkAccent,
                                        backgroundImage:
                                            (profile.avatarUrl != null &&
                                                profile.avatarUrl!.isNotEmpty)
                                            ? NetworkImage(profile.avatarUrl!)
                                            : null,
                                        child:
                                            (profile.avatarUrl == null ||
                                                profile.avatarUrl!.isEmpty)
                                            ? Text(
                                                initials,
                                                style: GoogleFonts.poppins(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 24,
                                                ),
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              profile.fullName,
                                              style: GoogleFonts.poppins(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'User ID: ${profile.userId}',
                                              style: GoogleFonts.poppins(
                                                color: Colors.white60,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if ((profile.bio ?? '').isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      profile.bio!,
                                      style: GoogleFonts.poppins(
                                        color: Colors.white70,
                                        fontSize: 13,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      if (formattedBirthdate != null)
                                        _InfoPill(
                                          icon: Icons.cake,
                                          label: 'Tanggal Lahir',
                                          value: formattedBirthdate,
                                          accent: _vipAccent(
                                            vipSnap.data?.vip?.vipLevel ?? '',
                                          ),
                                        ),
                                      if ((profile.gender ?? '')
                                          .isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        _InfoPill(
                                          icon: Icons.person,
                                          label: 'Gender',
                                          value: profile.gender!,
                                          accent: _vipAccent(
                                            vipSnap.data?.vip?.vipLevel ?? '',
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  // VIP info
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: FutureBuilder<VipResponseModel>(
                      future: _vipFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const _VipSkeleton();
                        }

                        final vip = snapshot.data?.vip;
                        if (snapshot.hasError) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.redAccent,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Gagal memuat status VIP',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        if (vip == null) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF121212),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.workspace_premium,
                                  color: Colors.white38,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Tidak ada langganan VIP aktif',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white60,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        String fmtDate(DateTime? d) {
                          if (d == null) return '-';
                          final x = d.toLocal();
                          const months = [
                            'Jan',
                            'Feb',
                            'Mar',
                            'Apr',
                            'Mei',
                            'Jun',
                            'Jul',
                            'Agu',
                            'Sep',
                            'Okt',
                            'Nov',
                            'Des',
                          ];
                          return '${x.day.toString().padLeft(2, '0')} ${months[x.month - 1]} ${x.year}';
                        }

                        // Build inner content used for all VIP levels
                        Widget innerContent(
                          Color? overrideBorderColor,
                        ) => Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF121212),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: overrideBorderColor ?? Colors.white12,
                            ),
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
                                  Icon(
                                    Icons.workspace_premium,
                                    color: _vipAccent(vip.vipLevel),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'VIP ${vip.vipLevel}',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const Spacer(),
                                  _buildStatusBadge(vip.status, vip.vipLevel),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  _InfoPill(
                                    icon: Icons.event,
                                    label: 'Mulai',
                                    value: fmtDate(vip.startAt),
                                    accent: _vipAccent(vip.vipLevel),
                                  ),
                                  const SizedBox(width: 8),
                                  _InfoPill(
                                    icon: Icons.event_available,
                                    label: 'Berakhir',
                                    value: fmtDate(vip.endAt),
                                    accent: _vipAccent(vip.vipLevel),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  _InfoPill(
                                    icon: Icons.autorenew,
                                    label: 'Auto Renew',
                                    value: vip.autoRenew ? 'Aktif' : 'Nonaktif',
                                    accent: _vipAccent(vip.vipLevel),
                                  ),
                                  if ((vip.paymentMethod ?? '').isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    _InfoPill(
                                      icon: Icons.account_balance_wallet,
                                      label: 'Metode',
                                      value: vip.paymentMethod!,
                                      accent: _vipAccent(vip.vipLevel),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        );

                        final level = (vip.vipLevel).toLowerCase();
                        if (level == 'diamond') {
                          // Rotating purple RGB border using SweepGradient
                          return AnimatedBuilder(
                            animation: _diamondCtrl,
                            builder: (context, child) {
                              final angle = _diamondCtrl.value * 2 * math.pi;
                              return Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  gradient: SweepGradient(
                                    colors: const [
                                      Color(0xFF9C27B0), // purple
                                      Color(0xFFE040FB), // purple accent
                                      Color(0xFF7E57C2), // deep purple
                                      Color(0xFF9C27B0),
                                    ],
                                    transform: GradientRotation(angle),
                                  ),
                                ),
                                padding: const EdgeInsets.all(2),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: innerContent(Colors.transparent),
                                ),
                              );
                            },
                          );
                        }
                        if (level == 'master') {
                          // Rotating red RGB border with pulsing glow
                          return AnimatedBuilder(
                            animation: _diamondCtrl,
                            builder: (context, child) {
                              final angle = _diamondCtrl.value * 2 * math.pi;
                              final glow =
                                  12 + 8 * (0.5 + 0.5 * math.sin(angle));
                              return Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  gradient: SweepGradient(
                                    colors: const [
                                      Color(0xFFE53935), // red
                                      Color(0xFFFF7043), // deep orange
                                      Color(0xFFD81B60), // pink
                                      Color(0xFFE53935),
                                    ],
                                    transform: GradientRotation(angle),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.redAccent.withOpacity(0.35),
                                      blurRadius: glow,
                                      spreadRadius: 1.5,
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(2),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: innerContent(Colors.transparent),
                                ),
                              );
                            },
                          );
                        }

                        Color borderColor;
                        if (level == 'bronze') {
                          borderColor = const Color(0xFF8B4513); // brown
                        } else if (level == 'silver') {
                          borderColor = const Color(0xFFC0C0C0); // silver
                        } else if (level == 'gold') {
                          borderColor = Colors.amber; // gold/yellow
                        } else {
                          borderColor = Colors.white12; // default
                        }

                        return innerContent(borderColor);
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(
                            Icons.workspace_premium,
                            color: Colors.white,
                          ),
                          title: Text(
                            'VIP / Membership',
                            style: GoogleFonts.poppins(color: Colors.white),
                          ),
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const MembershipInfoScreen(),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          leading: const Icon(
                            Icons.settings,
                            color: Colors.white,
                          ),
                          title: Text(
                            'Pengaturan Akun',
                            style: GoogleFonts.poppins(color: Colors.white),
                          ),
                          onTap: () async {
                            final result = await Navigator.of(context)
                                .push<bool>(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const AccountSettingsScreen(),
                                  ),
                                );
                            if (result == true) {
                              // refresh profile and vip data
                              // ignore: use_build_context_synchronously
                              _onRefresh();
                            }
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.lock, color: Colors.white),
                          title: Text(
                            'Privasi & Keamanan',
                            style: GoogleFonts.poppins(color: Colors.white),
                          ),
                          onTap: () {},
                        ),
                        ListTile(
                          leading: const Icon(
                            Icons.logout,
                            color: Colors.redAccent,
                          ),
                          title: Text(
                            'Keluar',
                            style: GoogleFonts.poppins(color: Colors.redAccent),
                          ),
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  const _SkeletonBox({
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // avatar
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Colors.white10,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _SkeletonBox(width: 160, height: 16),
                    SizedBox(height: 8),
                    _SkeletonBox(width: 120, height: 12),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _SkeletonBox(width: double.infinity, height: 14),
          const SizedBox(height: 12),
          Row(
            children: const [
              _SkeletonBox(width: 120, height: 32, borderRadius: 10),
              SizedBox(width: 8),
              _SkeletonBox(width: 100, height: 32, borderRadius: 10),
            ],
          ),
        ],
      ),
    );
  }
}

class _VipSkeleton extends StatelessWidget {
  const _VipSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              _SkeletonBox(width: 20, height: 20, borderRadius: 6),
              SizedBox(width: 8),
              _SkeletonBox(width: 100, height: 16),
              Spacer(),
              _SkeletonBox(width: 64, height: 24, borderRadius: 999),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: const [
              _SkeletonBox(width: 120, height: 32, borderRadius: 10),
              SizedBox(width: 8),
              _SkeletonBox(width: 120, height: 32, borderRadius: 10),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: const [
              _SkeletonBox(width: 120, height: 32, borderRadius: 10),
              SizedBox(width: 8),
              _SkeletonBox(width: 120, height: 32, borderRadius: 10),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? accent;

  const _InfoPill({
    required this.icon,
    required this.label,
    required this.value,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final Color borderColor = (accent ?? Colors.white12).withOpacity(
      accent == null ? 1 : 0.7,
    );
    final Color iconColor = accent ?? Colors.pinkAccent;
    final Color bgColor = (accent ?? Colors.white10).withOpacity(
      accent == null ? 1 : 0.15,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: Colors.white60,
                  fontSize: 10,
                  height: 1.0,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
