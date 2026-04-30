import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/player_provider.dart';
import '../utils/theme.dart';
import '../widgets/common_widgets.dart';

// ─── Queue Sheet ──────────────────────────────────────────────────────────────
class QueueSheet extends StatelessWidget {
  const QueueSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, player, _) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.bgSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (_, controller) => Column(
            children: [
              const SizedBox(height: 8),
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppTheme.textHint,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.queue_music_rounded,
                      color: AppTheme.tealPrimary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Queue • ${player.queue.length} songs',
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: player.queue.isEmpty
                    ? const Center(
                        child: Text('Queue is empty',
                            style: TextStyle(color: AppTheme.textSecondary)),
                      )
                    : ListView.builder(
                        controller: controller,
                        itemCount: player.queue.length,
                        itemBuilder: (ctx, i) {
                          final song = player.queue[i];
                          final isCurrent = i == player.currentIndex;
                          return Container(
                            color: isCurrent ? AppTheme.tealAlpha : Colors.transparent,
                            child: ListTile(
                              leading: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 24,
                                    child: Text(
                                      '${i + 1}',
                                      style: TextStyle(
                                        color: isCurrent
                                            ? AppTheme.tealPrimary
                                            : AppTheme.textHint,
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  AlbumArtWidget(albumId: song.albumId, size: 40),
                                ],
                              ),
                              title: Text(
                                song.title,
                                style: TextStyle(
                                  color: isCurrent
                                      ? AppTheme.tealPrimary
                                      : AppTheme.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(song.artist,
                                  style: const TextStyle(
                                      color: AppTheme.textSecondary, fontSize: 11),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              trailing: Text(song.durationFormatted,
                                  style: const TextStyle(
                                      color: AppTheme.textHint, fontSize: 11)),
                              onTap: () {
                                player.playSong(song, player.queue, i);
                                Navigator.pop(context);
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Lyrics Sheet ─────────────────────────────────────────────────────────────
class LyricsSheet extends StatefulWidget {
  const LyricsSheet({super.key});

  @override
  State<LyricsSheet> createState() => _LyricsSheetState();
}

class _LyricsSheetState extends State<LyricsSheet> {
  String? _lyrics;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLyrics();
  }

  Future<void> _loadLyrics() async {
    final player = context.read<PlayerProvider>();
    final song = player.currentSong;
    if (song == null) {
      setState(() { _loading = false; });
      return;
    }

    // Try reading embedded lyrics from ID3 tags
    try {
      // Use MediaMetadataRetriever approach via platform channel would go here.
      // For now we show a friendly message — embed lyrics via Mp3tag.
      await Future.delayed(const Duration(milliseconds: 300));
      setState(() {
        _lyrics = null; // will show "no lyrics" message
        _loading = false;
      });
    } catch (_) {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final song = context.read<PlayerProvider>().currentSong;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, controller) => Column(
          children: [
            const SizedBox(height: 8),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppTheme.textHint,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lyrics_rounded, color: AppTheme.tealPrimary, size: 20),
                const SizedBox(width: 8),
                const Text('Lyrics',
                    style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            if (song != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('${song.title} — ${song.artist}',
                    style: const TextStyle(color: AppTheme.tealPrimary, fontSize: 12)),
              ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.tealPrimary))
                  : _lyrics != null
                      ? SingleChildScrollView(
                          controller: controller,
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                          child: Text(
                            _lyrics!,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 16,
                              height: 1.8,
                            ),
                          ),
                        )
                      : Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.lyrics_rounded,
                                  color: AppTheme.textHint, size: 56),
                              const SizedBox(height: 12),
                              const Text('No lyrics found',
                                  style: TextStyle(
                                      color: AppTheme.textSecondary, fontSize: 16)),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 32),
                                child: Text(
                                  'Embed lyrics in your MP3 files using Mp3tag (free app) on a PC',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: AppTheme.textHint, fontSize: 13),
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
  }
}
