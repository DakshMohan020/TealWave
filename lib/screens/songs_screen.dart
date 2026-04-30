import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../services/player_provider.dart';
import '../utils/theme.dart';
import '../widgets/common_widgets.dart';

class SongsScreen extends StatefulWidget {
  const SongsScreen({super.key});

  @override
  State<SongsScreen> createState() => _SongsScreenState();
}

class _SongsScreenState extends State<SongsScreen> {
  String _query = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, player, _) {
        final songs = _query.isEmpty
            ? player.allSongs
            : player.allSongs
                .where((s) =>
                    s.title.toLowerCase().contains(_query) ||
                    s.artist.toLowerCase().contains(_query))
                .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Songs',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${player.allSongs.length} songs',
                    style: const TextStyle(
                        color: AppTheme.tealPrimary, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    onChanged: (v) =>
                        setState(() => _query = v.toLowerCase()),
                    style:
                        const TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search songs, artists...',
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: AppTheme.textSecondary),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded,
                                  color: AppTheme.textSecondary),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: player.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.tealPrimary),
                    )
                  : player.allSongs.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.music_off_rounded,
                                  color: AppTheme.textHint, size: 64),
                              SizedBox(height: 12),
                              Text(
                                'No music found on device',
                                style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 16),
                              ),
                              SizedBox(height: 8),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 32),
                                child: Text(
                                  'Make sure your music files are in the Music or Downloads folder',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: AppTheme.textHint,
                                      fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        )
                      : songs.isEmpty
                          ? const Center(
                              child: Text(
                                'No songs match your search',
                                style: TextStyle(
                                    color: AppTheme.textSecondary),
                              ),
                            )
                          : ListView.builder(
                              itemCount: songs.length,
                              itemBuilder: (context, i) {
                                final song = songs[i];
                                final isActive =
                                    player.currentSong?.id == song.id;
                                return SongTile(
                                  song: song,
                                  songList: songs,
                                  index: i,
                                  isActive: isActive,
                                  onLongPress: () => _showOptions(
                                      context, song, player),
                                );
                              },
                            ),
            ),
          ],
        );
      },
    );
  }

  void _showOptions(
      BuildContext context, Song song, PlayerProvider player) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textHint,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.playlist_add_rounded,
                  color: AppTheme.tealPrimary),
              title: const Text('Add to Playlist',
                  style: TextStyle(color: AppTheme.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                _showAddToPlaylist(context, song, player);
              },
            ),
            ListTile(
              leading: const Icon(Icons.queue_music_rounded,
                  color: AppTheme.tealPrimary),
              title: const Text('Play Next',
                  style: TextStyle(color: AppTheme.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                final idx = player.currentIndex + 1;
                player.queue.insert(
                    idx.clamp(0, player.queue.length), song);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddToPlaylist(
      BuildContext context, Song song, PlayerProvider player) {
    if (player.playlists.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Create a playlist first in the Playlists tab')),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            const Text('Add to Playlist',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...player.playlists.map((p) => ListTile(
                  leading: const Icon(Icons.playlist_play_rounded,
                      color: AppTheme.tealPrimary),
                  title: Text(p.name,
                      style: const TextStyle(
                          color: AppTheme.textPrimary)),
                  subtitle: Text('${p.songCount} songs',
                      style: const TextStyle(
                          color: AppTheme.textSecondary)),
                  onTap: () {
                    player.addSongToPlaylist(p, song);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Added to ${p.name}')),
                    );
                  },
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
