import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import './watch_offline_screen.dart';

import '../../services/download_service.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  late Future<List<DownloadEntry>> _future;
  List<DownloadTask> _tasks = [];
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _future = DownloadService.listDownloads();
    _loadTasks();
    _poll = Timer.periodic(const Duration(seconds: 1), (_) {
      _loadTasks();
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _future = DownloadService.listDownloads();
    });
    await _future;
    await _loadTasks();
  }

  Future<void> _remove(DownloadEntry e) async {
    await DownloadService.removeDownload(e);
    await _refresh();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unduhan dihapus')),
    );
  }

  Future<void> _loadTasks() async {
    final tasks = await DownloadService.listTasks();
    if (!mounted) return;
    setState(() {
      _tasks = tasks;
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
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
        title: Text('Unduhan', style: GoogleFonts.poppins(color: Colors.white)),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: Colors.pinkAccent,
        backgroundColor: Colors.black,
        child: FutureBuilder<List<DownloadEntry>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.pinkAccent));
            }
            final items = snapshot.data ?? [];
            final active = _tasks.where((t) => t.status == 'downloading' || (t.status == 'complete' && t.progress < 1.0)).toList();
            if (items.isEmpty && active.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 80),
                  Icon(Icons.download_done, color: Colors.white24, size: 48),
                  const SizedBox(height: 12),
                  Center(
                    child: Text('Belum ada unduhan', style: GoogleFonts.poppins(color: Colors.white)),
                  ),
                ],
              );
            }
            return ListView(
              children: [
                if (active.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text('Sedang diunduh', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                  ),
                  ...active.map((t) => ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: t.thumbnail.isNotEmpty
                              ? Image.network(t.thumbnail, width: 56, height: 56, fit: BoxFit.cover)
                              : Container(width: 56, height: 56, color: Colors.white10, child: const Icon(Icons.downloading, color: Colors.white54)),
                        ),
                        title: Text(t.title, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Episode ${t.episodeNumber} • ${t.quality}', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                            const SizedBox(height: 6),
                            LinearProgressIndicator(
                              value: (t.progress > 0 && t.progress <= 1) ? t.progress : null,
                              color: Colors.pinkAccent,
                              backgroundColor: Colors.white10,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              t.progress > 0 ? '${(t.progress * 100).toStringAsFixed(0)}%' : 'Menyiapkan...',
                              style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11),
                            ),
                          ],
                        ),
                        trailing: Icon(
                          t.status == 'complete' && t.progress >= 1.0 ? Icons.check_circle : Icons.downloading,
                          color: t.status == 'complete' && t.progress >= 1.0 ? Colors.greenAccent : Colors.white70,
                        ),
                      )),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(height: 24, color: Colors.white10),
                  ),
                ],
                if (items.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text('Selesai diunduh', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                  ),
                ...items.map((e) => Column(
                      children: [
                        ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: e.thumbnail.isNotEmpty
                                ? Image.network(e.thumbnail, width: 56, height: 56, fit: BoxFit.cover)
                                : Container(width: 56, height: 56, color: Colors.white10, child: const Icon(Icons.video_file, color: Colors.white54)),
                          ),
                          title: Text(e.title, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                          subtitle: Text('Episode ${e.episodeNumber} • ${e.quality} • ${(e.fileSize / (1024*1024)).toStringAsFixed(1)} MB', style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () async {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: const Color(0xFF1E1E1E),
                                  title: Text('Hapus unduhan?', style: GoogleFonts.poppins(color: Colors.white)),
                                  content: Text('File video dan metadata akan dihapus.', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), style: TextButton.styleFrom(foregroundColor: Colors.white), child: const Text('Batal')),
                                    ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white), child: const Text('Hapus')),
                                  ],
                                ),
                              );
                              if (ok == true) {
                                await _remove(e);
                              }
                            },
                          ),
                          onTap: () async {
                            if (!File(e.filePath).existsSync()) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('File tidak ditemukan')),
                              );
                              return;
                            }
                            await Navigator.of(context, rootNavigator: true).push(
                              MaterialPageRoute(
                                builder: (_) => WatchOfflineScreen(
                                  filePath: e.filePath,
                                  title: e.title,
                                  episodeNumber: e.episodeNumber,
                                  quality: e.quality,
                                  fileSizeBytes: e.fileSize,
                                ),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1, color: Colors.white10),
                      ],
                    )),
                const SizedBox(height: 24),
              ],
            );
          },
        ),
      ),
    );
  }
}

// (moved player implementation to watch_offline_screen.dart)
