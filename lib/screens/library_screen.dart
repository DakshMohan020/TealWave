import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
            child: Text(
              'Library',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
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

class _AlbumsTab extends StatelessWidget {
  const _AlbumsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, player, _) {
        final albums = <String, List<Song>>{};
        for (final song in player.allSongs) {
          albums.putIfAbsent(song.album, () => []).add(song);
        }
        final albumList = albums.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));

        if (albumList.isEmpty) {
          return const Center(
            child: Text('No albums found',
                style: TextStyle(color: AppTheme.textSecondary)),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(10),
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.85,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: albumList.length,
          itemBuilder: (context, i) {
            final albumName = albumList[i].key;
            final songs = albumList[i].value;
            return GestureDetector(
              onTap: () => _showAlbumSongs(
                  context, albumName, songs),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.bgSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12)),
                      child: Container(
                        height: 130,
                        width: double.infinity,
                        color: AppTheme.bgElevated,
                        child: const Icon(Icons.album_rounded,
                            color: AppTheme.tealPrimary, size: 56),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            albumName,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            songs.first.artist,
                            style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${songs.length} songs',
                            style: const TextStyle(
                                color: AppTheme.tealPrimary,
                                fontSize: 11),
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
      },
    );
  }

  void _showAlbumSongs(
      BuildContext context, String albumName, List<Song> songs) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (_, controller) => Column(
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
            Text(
              albumName,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${songs.length} songs',
              style: const TextStyle(color: AppTheme.tealPrimary),
            ),
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

        if (artists.isEmpty) {
          return const Center(
            child: Text('No artists found',
                style: TextStyle(color: AppTheme.textSecondary)),
          );
        }

        return ListView.builder(
          itemCount: artists.length,
          itemBuilder: (context, i) {
            final name = artists[i].key;
            final songs = artists[i].value;
            final albums =
                songs.map((s) => s.album).toSet().length;
            return ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppTheme.tealAlpha,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_rounded,
                    color: AppTheme.tealPrimary),
              ),
              title: Text(
                name,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                '${songs.length} songs • $albums albums',
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12),
              ),
              onTap: () =>
                  _showArtistSongs(context, name, songs),
            );
          },
        );
      },
    );
  }

  void _showArtistSongs(
      BuildContext context, String artist, List<Song> songs) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (_, controller) => Column(
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
            Text(
              artist,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${songs.length} songs',
              style:
                  const TextStyle(color: AppTheme.tealPrimary),
            ),
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
