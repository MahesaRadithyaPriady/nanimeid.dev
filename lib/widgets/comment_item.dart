import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/comment_model.dart';
import 'vip_badge.dart';

class CommentItem extends StatefulWidget {
  final CommentModel comment;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onLike;
  final VoidCallback? onUserTap;
  final bool canModerate;

  const CommentItem({
    super.key,
    required this.comment,
    required this.index,
    required this.onEdit,
    required this.onDelete,
    required this.onLike,
    this.onUserTap,
    this.canModerate = false,
  });

  @override
  State<CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends State<CommentItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _vipCtrl;

  @override
  void initState() {
    super.initState();
    _vipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _vipCtrl.dispose();
    super.dispose();
  }

  Color? _borderColor(String level) {
    switch (level) {
      case 'bronze':
        return const Color(0xFF8B4513);
      case 'silver':
        return const Color(0xFFC0C0C0);
      case 'gold':
        return Colors.amber;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final comment = widget.comment;
    final index = widget.index;

    final avatarUrl = comment.user?.profile?.avatarUrl;
    final bool isTemp = comment.id == 0;
    final rawFullName = comment.user?.profile?.fullName ?? '';
    final fallbackUsername = comment.user?.username ?? '';
    final displayName = isTemp
        ? 'Mengirim…'
        : (rawFullName.isNotEmpty ? rawFullName : fallbackUsername);
    final likes = comment.count?.likes ?? 0;
    final liked = comment.likedByMe;

    final level = (comment.user?.vip?.vipLevel ?? '').toLowerCase();
    final bool animatedVip = level == 'diamond' || level == 'master';
    final borderColor = _borderColor(level);

    // Inner content for all items
    final inner = Container(
      margin: animatedVip ? EdgeInsets.zero : const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: animatedVip ? const Color(0xFF121212) : Colors.white10,
        borderRadius: BorderRadius.circular(12),
        border: animatedVip
            ? Border.all(color: Colors.transparent)
            : borderColor != null
                ? Border.all(color: borderColor.withOpacity(0.6))
                : Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: widget.onUserTap,
            borderRadius: BorderRadius.circular(999),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.pinkAccent,
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null
                  ? Text(
                      (displayName.isNotEmpty ? displayName[0] : '?').toUpperCase(),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: InkWell(
                        onTap: widget.onUserTap,
                        borderRadius: BorderRadius.circular(6),
                        child: Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: animatedVip ? Colors.white : Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (level.isNotEmpty) VipBadge(level: level),
                    const Spacer(),
                    if (!isTemp && widget.canModerate)
                      PopupMenuButton<String>(
                        tooltip: kReleaseMode ? null : 'Aksi',
                        color: const Color(0xFF2A2A2A),
                        elevation: 6,
                        splashRadius: 18,
                        position: PopupMenuPosition.under,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Colors.white10),
                        ),
                        onSelected: (value) {
                          if (value == 'edit') {
                            widget.onEdit();
                          } else if (value == 'delete') {
                            widget.onDelete();
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                const Icon(LucideIcons.pencil, size: 16, color: Colors.white70),
                                const SizedBox(width: 8),
                                Text(
                                  'Edit',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(height: 4),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(LucideIcons.trash2, size: 16, color: Colors.white70),
                                const SizedBox(width: 8),
                                Text(
                                  'Hapus',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        icon: const Icon(
                          LucideIcons.moreVertical,
                          color: Colors.white70,
                          size: 18,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.content,
                  style: GoogleFonts.poppins(
                    color: animatedVip ? Colors.white : Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                if (comment.isEdited)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Diedit',
                      style: GoogleFonts.poppins(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    InkWell(
                      onTap: widget.onLike,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              liked ? LucideIcons.heart : LucideIcons.heart,
                              size: 16,
                              color: liked
                                  ? Colors.pinkAccent
                                  : (animatedVip ? Colors.white : Colors.white70),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              likes.toString(),
                              style: GoogleFonts.poppins(
                                color: liked
                                    ? Colors.pinkAccent
                                    : (animatedVip ? Colors.white : Colors.white70),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (level == 'diamond') {
      return AnimatedBuilder(
        animation: _vipCtrl,
        builder: (context, _) {
          final angle = _vipCtrl.value * 2 * math.pi;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
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
            padding: const EdgeInsets.all(2),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: inner,
            ),
          );
        },
      );
    }

    if (level == 'master') {
      return AnimatedBuilder(
        animation: _vipCtrl,
        builder: (context, _) {
          final angle = _vipCtrl.value * 2 * math.pi;
          final glow = 8 + 6 * (0.5 + 0.5 * math.sin(angle));
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: SweepGradient(
                colors: const [
                  Color(0xFFE53935),
                  Color(0xFFFF7043),
                  Color(0xFFD81B60),
                  Color(0xFFE53935),
                ],
                transform: GradientRotation(angle),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.redAccent.withOpacity(0.35),
                  blurRadius: glow,
                  spreadRadius: 1.2,
                ),
              ],
            ),
            padding: const EdgeInsets.all(2),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: inner,
            ),
          );
        },
      );
    }

    return inner;
  }
}
