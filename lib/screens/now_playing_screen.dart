import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../services/player_provider.dart';
import '../utils/theme.dart';
import '../widgets/common_widgets.dart';
import 'queue_screen.dart';

class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _artController;
  late Animation<double> _artScale;
  Song? _lastSong;

  @override
  void initState() {
    super.initState();
    _artController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _artScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _artController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _artController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, player, _) {
        final song = player.currentSong;
        if (song != null && song != _lastSong) {
          _lastSong = song;
          _artController.forward(from: 0);
        }
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0A2A2A),
                  Color(0xFF0D1117),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildTopBar(context),
                  const SizedBox(height: 16),
                  _buildAlbumArt(),
                  const SizedBox(height: 28),
                  _buildSongInfo(song),
                  const SizedBox(height: 20),
                  _buildSeekBar(player),
                  const SizedBox(height: 16),
                  _buildControls(player),
                  const SizedBox(height: 24),
                  _buildSecondaryControls(context),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppTheme.bgElevated,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'NOW PLAYING',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildAlbumArt() {
    return ScaleTransition(
      scale: _artScale,
      child: Container(
        width: 270,
        height: 270,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: AppTheme.bgElevated,
          boxShadow: [
            BoxShadow(
              color: AppTheme.tealPrimary.withOpacity(0.3),
              blurRadius: 40,
              spreadRadius: 5,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: const Icon(
            Icons.music_note_rounded,
            color: AppTheme.tealPrimary,
            size: 100,
          ),
        ),
      ),
    );
  }

  Widget _buildSongInfo(Song? song) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            song?.title ?? 'No song selected',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            song?.artist ?? '',
            style: const TextStyle(
              color: AppTheme.tealPrimary,
              fontSize: 15,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            song?.album ?? '',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSeekBar(PlayerProvider player) {
    final total = player.duration.inMilliseconds.toDouble();
    final current = player.position.inMilliseconds
        .toDouble()
        .clamp(0.0, total > 0 ? total : 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Slider(
            value: current,
            min: 0,
            max: total > 0 ? total : 1,
            onChanged: (val) =>
                player.seekTo(Duration(milliseconds: val.toInt())),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _fmt(player.position),
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                Text(
                  _fmt(player.duration),
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(PlayerProvider player) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: player.toggleShuffle,
          icon: const Icon(Icons.shuffle_rounded),
          color: AppTheme.tealPrimary,
          iconSize: 22,
          style: IconButton.styleFrom(
            backgroundColor: player.isShuffle
                ? AppTheme.tealAlpha
                : Colors.transparent,
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: player.playPrevious,
          child: Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: AppTheme.bgElevated,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.skip_previous_rounded,
              color: AppTheme.textPrimary,
              size: 28,
            ),
          ),
        ),
        const SizedBox(width: 12),
        PlayPauseButton(size: 70),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: player.playNext,
          child: Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: AppTheme.bgElevated,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.skip_next_rounded,
              color: AppTheme.textPrimary,
              size: 28,
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: player.toggleRepeat,
          icon: Icon(
            player.repeatMode == PlayerRepeatMode.one
                ? Icons.repeat_one_rounded
                : Icons.repeat_rounded,
          ),
          color: AppTheme.tealPrimary,
          iconSize: 22,
          style: IconButton.styleFrom(
            backgroundColor: player.repeatMode != PlayerRepeatMode.none
                ? AppTheme.tealAlpha
                : Colors.transparent,
          ),
        ),
      ],
    );
  }

  Widget _buildSecondaryControls(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (_) => const QueueSheet(),
          ),
          child: const Column(
            children: [
              Icon(Icons.queue_music_rounded,
                  color: AppTheme.textSecondary, size: 26),
              SizedBox(height: 4),
              Text(
                'Queue',
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(width: 48),
        GestureDetector(
          onTap: () => showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (_) => const LyricsSheet(),
          ),
          child: const Column(
            children: [
              Icon(Icons.lyrics_rounded,
                  color: AppTheme.textSecondary, size: 26),
              SizedBox(height: 4),
              Text(
                'Lyrics',
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
