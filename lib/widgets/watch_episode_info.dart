import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/download_service.dart';
import '../models/episode_detail_model.dart';
import '../services/favorite_service.dart';
import '../controllers/settings_controller.dart';
import '../services/vip_service.dart';
import '../models/vip_model.dart';

class WatchEpisodeInfo extends StatefulWidget {
  final EpisodeDetailModel? episodeDetail;

  const WatchEpisodeInfo({super.key, this.episodeDetail});

  @override
  State<WatchEpisodeInfo> createState() => _WatchEpisodeInfoState();
}

bool _requiresVipFallback(String quality) {
  final q = quality.trim().toUpperCase();
  if (q == 'AUTO' || q == 'OFFLINE') return false;
  if (q.contains('2K') || q.contains('4K')) return true;
  final match = RegExp(r"(\d{3,4})P").firstMatch(q);
  if (match != null) {
    final num = int.tryParse(match.group(1) ?? '0') ?? 0;
    return num >= 1080;
  }
  return false;
}

class _WatchEpisodeInfoState extends State<WatchEpisodeInfo> {
  bool _isFavorited = false;
  int _favoriteCount = 0;
  bool _loadingFav = false;
  bool? _isVip; // null while loading

  @override
  void initState() {
    super.initState();
    _loadEpisodeFavoriteStats();
    _loadVipStatus();
  }

  Future<void> _loadEpisodeFavoriteStats() async {
    final epId = widget.episodeDetail?.id;
    if (epId == null || epId == 0) return;
    try {
      final stats = await FavoriteService.getEpisodeFavoriteStats(epId);
      if (!mounted) return;
      setState(() {
        _isFavorited = stats.isFavorited;
        _favoriteCount = stats.count;
      });
    } catch (_) {
      // ignore errors silently for UI
    }
  }

  String get _favoriteCountFormatted => _favoriteCount.toString();

  Future<void> _loadVipStatus() async {
    try {
      final VipResponseModel res = await VipService.getMyVip();
      if (!mounted) return;
      setState(() {
        _isVip = res.isActive;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isVip = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsController.instance;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.episodeDetail != null
                ? 'Episode ${widget.episodeDetail!.nomorEpisode} - ${widget.episodeDetail!.judulEpisode}'
                : 'Episode 8 - My Dress-Up Darling',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _iconText(
                LucideIcons.calendar,
                widget.episodeDetail?.formattedReleaseDate ?? 'April 2024',
              ),
              const SizedBox(width: 16),
              _iconText(
                Icons.access_time,
                widget.episodeDetail?.formattedDuration ?? '24 Menit',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _iconText(
                Icons.verified,
                widget.episodeDetail?.anime.statusAnime ?? 'Ongoing',
              ),
              const SizedBox(width: 16),
              _iconText(Icons.star, widget.episodeDetail?.anime.ratingAnime ?? '8.3'),
              const SizedBox(width: 16),
              _iconText(
                Icons.remove_red_eye,
                widget.episodeDetail?.anime.viewAnime ?? '1.2M Views',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _favoriteButton(context),
              const SizedBox(width: 12),
              if (settings.downloadsEnabled)
                _actionButton(Icons.download, 'Unduh', onPressed: () => _onDownloadPressed(context)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconText(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white70),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _actionButton(IconData icon, String label, {VoidCallback? onPressed}) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white, size: 20),
      label: Text(
        label,
        style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        backgroundColor: Colors.white10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _onDownloadPressed(BuildContext context) async {
    // Double-check downloads flag at action time
    if (!SettingsController.instance.downloadsEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fitur unduhan sedang dinonaktifkan')),
      );
      return;
    }
    final ep = widget.episodeDetail;
    if (ep == null || ep.qualities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kualitas video tidak tersedia')),
      );
      return;
    }

    // Pick quality
    final chosen = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        bool isLocked(String q) {
          final sc = SettingsController.instance;
          final hasServerPaid = (sc.settings?.paidQualities.isNotEmpty == true);
          final paid = hasServerPaid
              ? sc.isQualityPaid(q)
              : _requiresVipFallback(q);
          return paid && (_isVip != true);
        }
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Text(
                'Pilih Kualitas',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ...ep.availableQualityNames.map((q) {
                final locked = isLocked(q);
                return ListTile(
                  leading: Icon(locked ? Icons.lock : Icons.hd, color: Colors.white70),
                  title: Text(q, style: GoogleFonts.poppins(color: Colors.white)),
                  onTap: locked
                      ? () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Upgrade ke VIP untuk mengunduh kualitas $q')),
                          );
                        }
                      : () => Navigator.of(ctx).pop(q),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (chosen == null) return;

    // Jalankan di latar belakang: tidak memblok UI dengan dialog.
    // Beri tahu user untuk cek kemajuan/hasil di layar Unduhan.
    // Catatan: item baru akan muncul di `Unduhan` setelah selesai karena index diperbarui saat selesai.
    // Untuk progres realtime, bisa ditingkatkan dengan manager/stream terpusat di masa depan.
    // ignore: unawaited_futures
    DownloadService.downloadEpisode(
      episode: ep,
      qualityName: chosen,
    ).then((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unduhan selesai. Cek di menu Unduhan.')),
      );
    }).catchError((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengunduh. Coba lagi.')),
      );
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mengunduh di latar belakang... cek di menu Unduhan')),
    );
  }

  Future<void> _onFavoritePressed() async {
    final epId = widget.episodeDetail?.id;
    if (epId == null || epId == 0) return;
    setState(() => _loadingFav = true);
    bool ok = false;
    try {
      if (_isFavorited) {
        ok = await FavoriteService.deleteEpisodeFavorite(epId);
        if (ok) {
          setState(() {
            _isFavorited = false;
            _favoriteCount = (_favoriteCount - 1).clamp(0, 1 << 30);
          });
        }
      } else {
        ok = await FavoriteService.toggleEpisodeFavorite(epId);
        if (ok) {
          setState(() {
            _isFavorited = true;
            _favoriteCount = _favoriteCount + 1;
          });
        }
      }
      // Optionally refresh stats to stay consistent with server
      if (ok) {
        await _loadEpisodeFavoriteStats();
      }
    } catch (_) {
      // ignore errors silently
    } finally {
      if (mounted) setState(() => _loadingFav = false);
    }
  }

  Widget _favoriteButton(BuildContext context) {
    final activeColor = Colors.pinkAccent;
    final bool disabled = _loadingFav;
    final bool active = _isFavorited;

    final Color bg = active
        ? activeColor.withOpacity(0.15)
        : Colors.white10;
    final Color fg = active ? activeColor : Colors.white;
    final Color badgeBg = active
        ? activeColor.withOpacity(0.20)
        : Colors.white12;
    final Color badgeFg = active ? activeColor : Colors.white70;

    return TextButton(
      onPressed: disabled ? null : _onFavoritePressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        backgroundColor: bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(active ? Icons.favorite : Icons.favorite_border, color: fg, size: 20),
          const SizedBox(width: 8),
          Text(
            'Suka',
            style: GoogleFonts.poppins(color: fg, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              _favoriteCountFormatted,
              style: GoogleFonts.poppins(color: badgeFg, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
