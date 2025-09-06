import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/episode_detail_model.dart';
import '../services/episode_progress_service.dart';

class WatchProgressBar extends StatefulWidget {
  final EpisodeDetailModel? episodeDetail;

  const WatchProgressBar({super.key, this.episodeDetail});

  @override
  State<WatchProgressBar> createState() => _WatchProgressBarState();
}

class _WatchProgressBarState extends State<WatchProgressBar> {
  double _progress = 0.0; // 0..1
  bool _loading = false;

  String get _percentText => '${(_progress * 100).toStringAsFixed(0)}%';

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  @override
  void didUpdateWidget(covariant WatchProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.episodeDetail?.id != widget.episodeDetail?.id) {
      _loadProgress();
    }
  }

  Future<void> _loadProgress() async {
    final ep = widget.episodeDetail;
    if (ep == null || ep.id == 0) return;
    setState(() => _loading = true);
    try {
      final res = await EpisodeProgressService.getEpisodeProgress(ep.id);
      if (!mounted) return;
      if (res.isSuccess) {
        final data = res.data;
        final total = ep.durasiEpisode == 0 ? 1 : ep.durasiEpisode; // avoid div by zero
        final ratio = (data.progressWatching / total).clamp(0.0, 1.0);
        setState(() => _progress = ratio.toDouble());
      }
    } catch (_) {
      // ignore errors for UI
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  LucideIcons.activity,
                  color: Colors.pinkAccent,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  'Progress Menonton',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  widget.episodeDetail != null
                      ? 'Episode ${widget.episodeDetail!.nomorEpisode}'
                      : '8 / 12 Episode',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: widget.episodeDetail != null
                    ? (_loading ? null : _progress)
                    : 0.0,
                minHeight: 10,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation(Colors.pinkAccent),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Spacer(),
                Text(
                  _loading ? '...' : _percentText,
                  style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
