import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:on_audio_query/on_audio_query.dart';
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
  Color _topColor = const Color(0xFF0A2A2A);
  Color _bottomColor = AppTheme.bgPrimary;
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

  Future<void> _extractColors(int albumId) async {
    try {
      final artwork = await OnAudioQuery()
          .queryArtwork(albumId, ArtworkType.ALBUM);
      if (artwork == null || !mounted) return;
      final palette = await PaletteGenerator.fromImageProvider(
          MemoryImage(artwork));
      if (!mounted) return;
      setState(() {
        _topColor = _blend(
          palette.darkVibrantColor?.color ??
              palette.dominantColor?.color ??
              const Color(0xFF0A2A2A),
          Colors.black,
          0.55,
        );
        _bottomColor = _blend(
          palette.dominantColor?.color ?? AppTheme.bgPrimary,
          Colors.black,
          0.75,
        );
      });
    } catch (_) {}
  }

  Color _blend(Color a, Color b, double ratio) => Color.fromARGB(
        255,
        (a.red * (1 - ratio) + b.red * ratio).round(),
        (a.green * (1 - ratio) + b.green * ratio).round(),
        (a.blue * (1 - ratio) + b.blue * ratio).round(),
      );

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, player, _) {
        final song = player.currentSong;
        if (song != null && song != _lastSong) {
          _lastSong = song;
          _artController.forward(from: 0);
          _extractColors(song.albumId);
        }
        return Scaffold(
          body: AnimatedContainer(
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_topColor, _bottomColor, AppTheme.bgPrimary],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildTopBar(context),
                  const SizedBox(height: 16),
                  _buildAlbumArt(song),
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
                  color: AppTheme.bgElevated, shape: BoxShape.circle),
              child: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: AppTheme.textPrimary),
            ),
          ),
          const Expanded(
            child: Text('NOW PLAYING',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildAlbumArt(Song? song) {
    return ScaleTransition(
      scale: _artScale,
      child: Container(
        width: 270,
        height: 270,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _topColor.withOpacity(0.6),
              blurRadius: 40,
              spreadRadius: 5,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: song != null
              ? QueryArtworkWidget(
                  id: song.albumId,
                  type: ArtworkType.ALBUM,
                  artworkWidth: 270,
                  artworkHeight: 270,
                  artworkFit: BoxFit.cover,
                  artworkBorder: BorderRadius.zero,
                  nullArtworkWidget: _defaultArt(),
                )
              : _defaultArt(),
        ),
      ),
    );
  }

  Widget _defaultArt() => Container(
        color: AppTheme.bgElevated,
        child: const Icon(Icons.album_rounded,
            color: AppTheme.tealPrimary, size: 100),
      );

  Widget _buildSongInfo(Song? song) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(song?.title ?? 'No song selected',
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(song?.artist ?? '',
              style: const TextStyle(
                  color: AppTheme.tealPrimary, fontSize: 15),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(song?.album ?? '',
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
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
                Text(_fmt(player.position),
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12)),
                Text(_fmt(player.duration),
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12)),
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
            width: 52, height: 52,
            decoration: const BoxDecoration(
                color: AppTheme.bgElevated, shape: BoxShape.circle),
            child: const Icon(Icons.skip_previous_rounded,
                color: AppTheme.textPrimary, size: 28),
          ),
        ),
        const SizedBox(width: 12),
        PlayPauseButton(size: 70),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: player.playNext,
          child: Container(
            width: 52, height: 52,
            decoration: const BoxDecoration(
                color: AppTheme.bgElevated, shape: BoxShape.circle),
            child: const Icon(Icons.skip_next_rounded,
                color: AppTheme.textPrimary, size: 28),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: player.toggleRepeat,
          icon: Icon(player.repeatMode == RepeatMode.one
              ? Icons.repeat_one_rounded
              : Icons.repeat_rounded),
          color: AppTheme.tealPrimary,
          iconSize: 22,
          style: IconButton.styleFrom(
            backgroundColor: player.repeatMode != RepeatMode.none
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
              Text('Queue',
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 11)),
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
              Text('Lyrics',
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 11)),
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
