import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/home_header.dart';
import '../../models/favorite_model.dart';
import '../../services/favorite_service.dart';
import 'detail_anime_screen.dart';
import '../../widgets/exit_confirmation.dart';

class FavoriteScreen extends StatelessWidget {
  const FavoriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => showExitConfirmationDialog(context),
      child: DefaultTabController(
        length: 3, // Jumlah tab
        child: Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
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
                        'Favorit Saya',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

              // Tab menu
              TabBar(
                indicatorColor: Colors.pinkAccent,
                labelColor: Colors.pinkAccent,
                unselectedLabelColor: Colors.white70,
                labelStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                unselectedLabelStyle: GoogleFonts.poppins(fontSize: 14),
                tabs: const [
                  Tab(text: 'Ongoing'),
                  Tab(text: 'Completed'),
                  Tab(text: 'Hiatus'),
                ],
              ),

              Expanded(
                child: TabBarView(
                  children: [
                    // Tab Ongoing
                    _FavoriteTab(status: 'ongoing'),
                    // Tab Completed
                    _FavoriteTab(status: 'completed'),
                    // Tab Hiatus
                    _FavoriteTab(status: 'hiatus'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _FavoriteTab extends StatelessWidget {
  final String status; // ongoing | completed | hiatus
  const _FavoriteTab({required this.status});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FavoriteResponseModel>(
      future: FavoriteService.getMyFavoriteAnime(status: status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(color: Colors.pinkAccent, strokeWidth: 2),
            ),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Gagal memuat favorit',
              style: GoogleFonts.poppins(color: Colors.redAccent),
            ),
          );
        }
        final data = snapshot.data;
        final items = data?.items ?? const <FavoriteItemModel>[];
        if (items.isEmpty) {
          return Center(
            child: Text(
              'Tidak ada favorit',
              style: GoogleFonts.poppins(color: Colors.white60),
            ),
          );
        }
        return _buildGridView(items);
      },
    );
  }

  Widget _buildGridView(List<FavoriteItemModel> list) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.64,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        final anime = item.anime;
        final genres = anime.genreAnime.join(', ');
        final dateAdded = _formatDate(item.createdAt);

        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(
                builder: (_) => DetailAnimeScreen(
                  animeId: anime.id,
                  animeData: anime.toMap(),
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1F),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.network(
                    anime.gambarAnime,
                    height: 110,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          anime.namaAnime,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          genres,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: Colors.pinkAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Flexible(
                          child: Text(
                            anime.sinopsisAnime,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 12,
                              height: 1.3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Ditambahkan: $dateAdded',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: Colors.white60,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime? d) {
    if (d == null) return '-';
    // Simple yyyy-MM-dd
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
