import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../services/player_provider.dart';
import '../utils/theme.dart';
import '../screens/now_playing_screen.dart';

class AlbumArtWidget extends StatelessWidget {
  final int albumId;
  final double size;
  final double borderRadius;
  final Uint8List? artOverride;

  const AlbumArtWidget({
    super.key,
    this.albumId = 0,
    this.size = 48,
    this.borderRadius = 8,
    this.artOverride,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, player, _) {
        final art = artOverride ?? player.currentAlbumArt;
        return ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: SizedBox(
            width: size,
            height: size,
            child: art != null
                ? Image.memory(
                    art,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _defaultIcon(),
                  )
                : _defaultIcon(),
          ),
        );
      },
    );
  }

  Widget _defaultIcon() => Container(
        color: AppTheme.bgElevated,
        child: Icon(
          Icons.music_note_rounded,
          color: AppTheme.tealPrimary,
          size: size * 0.5,
        ),
      );
}

class SongTile extends StatelessWidget {
  final Song song;
  final List<Song> songList;
  final int index;
  final bool isActive;
  final VoidCallback? onLongPress;

  const SongTile({
    super.key,
    required this.song,
    required this.songList,
    required this.index,
    this.isActive = false,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        context.read<PlayerProvider>().playSong(
            song, songList, index);
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const NowPlayingScreen()),
        );
      },
      onLongPress: onLongPress,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 4),
        color: isActive
            ? AppTheme.tealAlpha
            : Colors.transparent,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 48,
                height: 48,
                child: isActive
                    ? Consumer<PlayerProvider>(
                        builder: (context, player, _) {
                          final art = player.currentAlbumArt;
                          return art != null
                              ? Image.memory(art,
                                  fit: BoxFit.cover)
                              : _defaultTileIcon();
                        },
                      )
                    : _defaultTileIcon(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    song.title,
                    style: TextStyle(
                      color: isActive
                          ? AppTheme.tealPrimary
                          : AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    song.artist,
                    style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              song.durationFormatted,
              style: const TextStyle(
                  color: AppTheme.textHint, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _defaultTileIcon() => Container(
        color: AppTheme.bgElevated,
        child: const Icon(
          Icons.music_note_rounded,
          color: AppTheme.tealPrimary,
          size: 24,
        ),
      );
}

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, player, _) {
        if (player.currentSong == null) {
          return const SizedBox.shrink();
        }
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const NowPlayingScreen()),
          ),
          child: Container(
            margin: const EdgeInsets.fromLTRB(8, 0, 8, 4),
            decoration: BoxDecoration(
              color: AppTheme.bgSurface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Progress bar
                LinearProgressIndicator(
                  value: player.duration.inMilliseconds > 0
                      ? player.position.inMilliseconds /
                          player.duration.inMilliseconds
                      : 0,
                  backgroundColor: AppTheme.textHint,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(
                          AppTheme.tealPrimary),
                  minHeight: 2,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      // Album art
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: player.currentAlbumArt != null
                              ? Image.memory(
                                  player.currentAlbumArt!,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (_, __, ___) =>
                                          _miniDefaultIcon(),
                                )
                              : _miniDefaultIcon(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Song info
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              player.currentSong!.title,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              player.currentSong!.artist,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Controls
                      IconButton(
                        onPressed: player.playPrevious,
                        icon: const Icon(
                            Icons.skip_previous_rounded),
                        color: AppTheme.textSecondary,
                        iconSize: 26,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                            minWidth: 36, minHeight: 36),
                      ),
                      PlayPauseButton(size: 40),
                      IconButton(
                        onPressed: player.playNext,
                        icon:
                            const Icon(Icons.skip_next_rounded),
                        color: AppTheme.textSecondary,
                        iconSize: 26,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                            minWidth: 36, minHeight: 36),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _miniDefaultIcon() => Container(
        color: AppTheme.bgElevated,
        child: const Icon(
          Icons.music_note_rounded,
          color: AppTheme.tealPrimary,
          size: 22,
        ),
      );
}

class PlayPauseButton extends StatelessWidget {
  final double size;
  const PlayPauseButton({super.key, this.size = 56});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, player, _) => GestureDetector(
        onTap: player.togglePlayPause,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: AppTheme.tealPrimary,
            shape: BoxShape.circle,
          ),
          child: Icon(
            player.isPlaying
                ? Icons.pause_rounded
                : Icons.play_arrow_rounded,
            color: AppTheme.bgPrimary,
            size: size * 0.55,
          ),
        ),
      ),
    );
  }
}
