import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../services/player_provider.dart';
import '../utils/theme.dart';
import '../widgets/common_widgets.dart';

class PlaylistsScreen extends StatelessWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, player, _) => Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text('Playlists',
                    style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: player.playlists.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.queue_music_rounded,
                                color: AppTheme.textHint, size: 72),
                            const SizedBox(height: 12),
                            const Text('No playlists yet',
                                style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
                            const SizedBox(height: 6),
                            Text('Tap + to create one',
                                style: TextStyle(color: AppTheme.textHint, fontSize: 13)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: player.playlists.length,
                        itemBuilder: (context, i) {
                          final playlist = player.playlists[i];
                          return Dismissible(
                            key: Key(playlist.id.toString()),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              color: Colors.red.withOpacity(0.2),
                              child: const Icon(Icons.delete_rounded, color: Colors.redAccent),
                            ),
                            onDismissed: (_) => player.deletePlaylist(playlist),
                            child: ListTile(
                              leading: Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: AppTheme.bgElevated,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: playlist.songs.isNotEmpty
                                    ? AlbumArtWidget(
                                        albumId: playlist.songs.first.albumId,
                                        size: 52,
                                        borderRadius: 10,
                                      )
                                    : const Icon(Icons.playlist_play_rounded,
                                        color: AppTheme.tealPrimary, size: 28),
                              ),
                              title: Text(playlist.name,
                                  style: const TextStyle(
                                      color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                              subtitle: Text('${playlist.songCount} songs',
                                  style: const TextStyle(
                                      color: AppTheme.textSecondary, fontSize: 12)),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PlaylistDetailScreen(playlist: playlist),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          // FAB
          Positioned(
            bottom: 12,
            right: 16,
            child: FloatingActionButton(
              onPressed: () => _showCreateDialog(context, player),
              backgroundColor: AppTheme.tealPrimary,
              foregroundColor: AppTheme.bgPrimary,
              child: const Icon(Icons.add_rounded),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context, PlayerProvider player) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New Playlist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(hintText: 'Playlist name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                player.createPlaylist(name);
                Navigator.pop(context);
              }
            },
            child: const Text('Create', style: TextStyle(color: AppTheme.tealPrimary)),
          ),
        ],
      ),
    );
  }
}

// ─── Playlist Detail ──────────────────────────────────────────────────────────
class PlaylistDetailScreen extends StatelessWidget {
  final Playlist playlist;
  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, player, _) => Scaffold(
        appBar: AppBar(
          title: Text(playlist.name),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_rounded, color: AppTheme.tealPrimary),
              onPressed: () => _showAddSongs(context, player),
            ),
          ],
        ),
        body: Column(
          children: [
            // Play all button
            if (playlist.songs.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      player.playSong(playlist.songs.first, playlist.songs, 0);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Play All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.tealPrimary,
                      foregroundColor: AppTheme.bgPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: playlist.songs.isEmpty
                  ? const Center(
                      child: Text('No songs — tap + to add',
                          style: TextStyle(color: AppTheme.textSecondary)),
                    )
                  : ListView.builder(
                      itemCount: playlist.songs.length,
                      itemBuilder: (context, i) {
                        final song = playlist.songs[i];
                        return Dismissible(
                          key: Key('${playlist.id}_${song.id}'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            color: Colors.red.withOpacity(0.2),
                            child: const Icon(Icons.remove_circle_rounded,
                                color: Colors.redAccent),
                          ),
                          onDismissed: (_) => player.removeSongFromPlaylist(playlist, song),
                          child: SongTile(
                            song: song,
                            songList: playlist.songs,
                            index: i,
                            isActive: player.currentSong?.id == song.id,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSongs(BuildContext context, PlayerProvider player) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (_, controller) => Column(
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(
              color: AppTheme.textHint, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            const Text('Add Songs',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: player.allSongs.length,
                itemBuilder: (ctx, i) {
                  final song = player.allSongs[i];
                  final inPlaylist = playlist.songs.contains(song);
                  return ListTile(
                    leading: AlbumArtWidget(albumId: song.albumId, size: 44),
                    title: Text(song.title,
                        style: TextStyle(
                            color: inPlaylist
                                ? AppTheme.tealPrimary
                                : AppTheme.textPrimary,
                            fontSize: 14)),
                    subtitle: Text(song.artist,
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    trailing: Icon(
                      inPlaylist ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                      color: inPlaylist ? AppTheme.tealPrimary : AppTheme.textHint,
                    ),
                    onTap: () {
                      if (inPlaylist) {
                        player.removeSongFromPlaylist(playlist, song);
                      } else {
                        player.addSongToPlaylist(playlist, song);
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
