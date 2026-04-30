import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../models/song.dart';
import '../services/player_provider.dart';
import '../utils/theme.dart';
import '../widgets/common_widgets.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Library',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.bold)),
          ),
          const TabBar(
            tabs: [Tab(text: 'Albums'), Tab(text: 'Artists')],
            indicatorColor: AppTheme.tealPrimary,
            labelColor: AppTheme.tealPrimary,
            unselectedLabelColor: AppTheme.textSecondary,
            dividerColor: Colors.transparent,
          ),
          const Expanded(
            child: TabBarView(
              children: [_AlbumsTab(), _ArtistsTab()],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Albums ───────────────────────────────────────────────────────────────────
class _AlbumsTab extends StatelessWidget {
  const _AlbumsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, player, _) {
        final albums = <int, List<Song>>{};
        for (final song in player.allSongs) {
          albums.putIfAbsent(song.albumId, () => []).add(song);
        }
        final albumList = albums.entries.toList()
          ..sort((a, b) => a.value.first.album.compareTo(b.value.first.album));

        return GridView.builder(
          padding: const EdgeInsets.all(10),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.78,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: albumList.length,
          itemBuilder: (context, i) {
            final albumId = albumList[i].key;
            final songs = albumList[i].value;
            return _AlbumCard(
              albumId: albumId,
              albumName: songs.first.album,
              artistName: songs.first.artist,
              songCount: songs.length,
              songs: songs,
            );
          },
        );
      },
    );
  }
}

class _AlbumCard extends StatelessWidget {
  final int albumId;
  final String albumName;
  final String artistName;
  final int songCount;
  final List<Song> songs;

  const _AlbumCard({
    required this.albumId,
    required this.albumName,
    required this.artistName,
    required this.songCount,
    required this.songs,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showAlbumSongs(context),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.bgSurface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: QueryArtworkWidget(
                id: albumId,
                type: ArtworkType.ALBUM,
                artworkWidth: double.infinity,
                artworkHeight: 150,
                artworkFit: BoxFit.cover,
                artworkBorder: BorderRadius.zero,
                nullArtworkWidget: Container(
                  height: 150,
                  color: AppTheme.bgElevated,
                  child: const Icon(Icons.album_rounded, color: AppTheme.tealPrimary, size: 64),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(albumName,
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(artistName,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text('$songCount songs',
                      style: const TextStyle(color: AppTheme.tealPrimary, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAlbumSongs(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (_, controller) => Column(
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(
              color: AppTheme.textHint, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            Text(albumName,
                style: const TextStyle(
                    color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            Text('$songCount songs', style: const TextStyle(color: AppTheme.tealPrimary)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: songs.length,
                itemBuilder: (ctx, i) => SongTile(
                  song: songs[i],
                  songList: songs,
                  index: i,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Artists ──────────────────────────────────────────────────────────────────
class _ArtistsTab extends StatelessWidget {
  const _ArtistsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, player, _) {
        final artistMap = <String, List<Song>>{};
        for (final song in player.allSongs) {
          artistMap.putIfAbsent(song.artist, () => []).add(song);
        }
        final artists = artistMap.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));

        return ListView.builder(
          itemCount: artists.length,
          itemBuilder: (context, i) {
            final name = artists[i].key;
            final songs = artists[i].value;
            final albums = songs.map((s) => s.albumId).toSet().length;
            return ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppTheme.tealAlpha,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_rounded, color: AppTheme.tealPrimary),
              ),
              title: Text(name,
                  style: const TextStyle(
                      color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
              subtitle: Text('${songs.length} songs • $albums albums',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              onTap: () => _showArtistSongs(context, name, songs),
            );
          },
        );
      },
    );
  }

  void _showArtistSongs(BuildContext context, String artist, List<Song> songs) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (_, controller) => Column(
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(
              color: AppTheme.textHint, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            Text(artist,
                style: const TextStyle(
                    color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            Text('${songs.length} songs', style: const TextStyle(color: AppTheme.tealPrimary)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: songs.length,
                itemBuilder: (ctx, i) => SongTile(
                  song: songs[i],
                  songList: songs,
                  index: i,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
