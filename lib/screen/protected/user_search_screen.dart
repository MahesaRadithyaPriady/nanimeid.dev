import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/profile_service.dart';
import '../../models/profile_model.dart';
import '../public/user_profile_mock.dart';

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';
  bool _loading = false;
  String? _error;
  List<PublicProfileAggregateModel> _items = [];
  Timer? _debounce;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('Cari Pengguna', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: Colors.white)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _controller,
              style: GoogleFonts.poppins(color: Colors.white),
              cursorColor: Colors.pinkAccent,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                hintText: 'Cari nama lengkap (full name)...',
                hintStyle: GoogleFonts.poppins(color: Colors.white54, fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF121212),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.pinkAccent),
                ),
              ),
              onChanged: (v) {
                final q = v.trim();
                setState(() => _query = q);
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 350), () {
                  _search();
                });
              },
              onSubmitted: (v) {
                setState(() => _query = v.trim());
                _search();
              },
            ),
          ),
          Expanded(
            child: _buildResults(),
          ),
        ],
      ),
    );
  }

  Future<void> _search() async {
    if (_query.isEmpty) {
      setState(() {
        _items = [];
        _loading = false;
        _error = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ProfileService.searchUsersPublic(query: _query, limit: 20);
      if (!mounted) return;
      setState(() {
        _items = res.items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal mencari pengguna';
        _loading = false;
      });
    }
  }

  Widget _buildResults() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Colors.pinkAccent));
    }
    if (_error != null) {
      return Center(
        child: Text(_error!, style: GoogleFonts.poppins(color: Colors.redAccent)),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Text('Tidak ada hasil', style: GoogleFonts.poppins(color: Colors.white54)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemBuilder: (ctx, i) {
        final item = _items[i];
        final name = item.profile.fullName;
        final username = item.username;
        final avatarUrl = item.profile.avatarUrl;
        final vipLevel = (item.vip?.vipLevel ?? item.level?.title ?? '').toString();
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: Colors.pinkAccent,
            backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty) ? NetworkImage(avatarUrl) : null,
            child: (avatarUrl == null || avatarUrl.isEmpty)
                ? Text(
                    (name.isNotEmpty ? name[0] : '?').toUpperCase(),
                    style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700),
                  )
                : null,
          ),
          title: Text(name, style: GoogleFonts.poppins(color: Colors.white)),
          subtitle: Text('@$username', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
          trailing: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pinkAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => UserProfileMockScreen(
                    userId: item.userId,
                    username: username,
                    avatarUrl: avatarUrl,
                    vipLevel: vipLevel,
                  ),
                ),
              );
            },
            child: Text('Lihat', style: GoogleFonts.poppins()),
          ),
        );
      },
      separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white12),
      itemCount: _items.length,
    );
  }
}
