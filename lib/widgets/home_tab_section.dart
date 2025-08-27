import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/profile_service.dart';
import '../models/profile_model.dart';

class HomeTabSection extends StatelessWidget {
  const HomeTabSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TabBar(
          indicatorColor: Colors.pinkAccent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(text: 'Pengumuman'),
            Tab(text: 'Profile'),
          ],
        ),
        SizedBox(
          height: 180,
          child: TabBarView(
            children: [
              // Pengumuman
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Selamat datang di NanimeID! 🎉 Anime terbaru akan update setiap minggu.',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ),
              // Profile
              FutureBuilder<ProfileResponseModel>(
                future: ProfileService.getMyProfile(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.pinkAccent,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Memuat profil...',
                            style: GoogleFonts.poppins(color: Colors.white70),
                          ),
                        ],
                      ),
                    );
                  }
                  if (snapshot.hasError || snapshot.data?.profile == null) {
                    return Center(
                      child: Text(
                        'Profil tidak tersedia',
                        style: GoogleFonts.poppins(color: Colors.white60),
                      ),
                    );
                  }

                  final profile = snapshot.data!.profile!;
                  final avatarUrl = profile.avatarUrl;
                  final birthdate = profile.birthdate;
                  final gender = profile.gender;

                  String formatDate(DateTime? d) {
                    if (d == null) return '-';
                    final y = d.year.toString().padLeft(4, '0');
                    final m = d.month.toString().padLeft(2, '0');
                    final day = d.day.toString().padLeft(2, '0');
                    return '$day-$m-$y';
                  }

                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: avatarUrl != null && avatarUrl.isNotEmpty
                              ? Image.network(
                                  avatarUrl,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.white12,
                                  child: const Icon(
                                    Icons.person_outline,
                                    color: Colors.white54,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Nama: ${profile.fullName}',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'UserID: ${profile.userId}',
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                'Tanggal lahir: ${formatDate(birthdate)}',
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                'Gender: ${gender ?? '-'}',
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
