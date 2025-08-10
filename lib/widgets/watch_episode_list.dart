import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class WatchEpisodeList extends StatefulWidget {
  final List<String> episodes;
  final int currentEpisodeIndex;

  const WatchEpisodeList({
    super.key,
    required this.episodes,
    this.currentEpisodeIndex = 7,
  });

  @override
  State<WatchEpisodeList> createState() => _WatchEpisodeListState();
}

class _WatchEpisodeListState extends State<WatchEpisodeList> {
  bool _isAscending = true;

  @override
  Widget build(BuildContext context) {
    List<String> displayedEpisodes = [...widget.episodes];
    if (!_isAscending) {
      displayedEpisodes = displayedEpisodes.reversed.toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: displayedEpisodes.length,
            itemBuilder: (context, index) {
              // Karena urutan bisa terbalik, kita sesuaikan indeks aktif
              final actualIndex = _isAscending
                  ? index
                  : displayedEpisodes.length - 1 - index;
              final isActive = actualIndex == widget.currentEpisodeIndex;

              return Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isActive ? Colors.pinkAccent : Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isActive
                        ? Colors.pinkAccent
                        : Colors.pinkAccent.withOpacity(0.3),
                  ),
                ),
                child: Center(
                  child: Text(
                    displayedEpisodes[index],
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(LucideIcons.listVideo, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            'Daftar Episode',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              setState(() {
                _isAscending = !_isAscending;
              });
            },
            icon: Icon(
              _isAscending
                  ? LucideIcons.arrowDownWideNarrow
                  : LucideIcons.arrowUpNarrowWide,
              color: Colors.pinkAccent,
              size: 20,
            ),
            tooltip: _isAscending ? 'Urutkan Terbaru' : 'Urutkan Terlama',
          ),
        ],
      ),
    );
  }
}
