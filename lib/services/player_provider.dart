import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/song.dart';

class PlayerProvider extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();

  List<Song> allSongs = [];
  List<Song> queue = [];
  List<Playlist> playlists = [];

  Song? currentSong;
  int currentIndex = -1;
  bool isPlaying = false;
  bool isShuffle = false;
  PlayerRepeatMode repeatMode = PlayerRepeatMode.none;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  bool isLoading = false;

  PlayerProvider() {
    _initPlayer();
    _loadPrefs();
  }

  void _initPlayer() {
    _player.positionStream.listen((pos) {
      position = pos;
      notifyListeners();
    });
    _player.durationStream.listen((dur) {
      if (dur != null) duration = dur;
      notifyListeners();
    });
    _player.playingStream.listen((playing) {
      isPlaying = playing;
      notifyListeners();
    });
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _onSongComplete();
      }
    });
  }

  void _onSongComplete() {
    switch (repeatMode) {
      case PlayerRepeatMode.one:
        _player.seek(Duration.zero);
        _player.play();
        break;
      case PlayerRepeatMode.all:
        playNext();
        break;
      case PlayerRepeatMode.none:
        if (currentIndex < queue.length - 1) {
          playNext();
        } else {
          isPlaying = false;
          notifyListeners();
        }
        break;
    }
  }

  Future<void> loadSongs() async {
    isLoading = true;
    notifyListeners();
    try {
      final songs = await _scanForMusic();
      allSongs = songs;
    } catch (e) {
      debugPrint('Error loading songs: $e');
    }
    isLoading = false;
    notifyListeners();
  }

  Future<List<Song>> _scanForMusic() async {
    final List<Song> songs = [];
    final List<String> allDirs = [];

    // Internal storage paths
    allDirs.addAll([
      '/storage/emulated/0',
      '/sdcard',
      '/mnt/sdcard',
    ]);

    // SD card - Samsung specific and generic paths
    final sdCardDirs = <String>[];
    try {
      // Numbered variants
      for (int i = 0; i <= 9; i++) {
        sdCardDirs.add('/storage/sdcard$i');
        sdCardDirs.add('/mnt/sdcard$i');
        sdCardDirs.add('/mnt/extsd$i');
      }

      // Common Samsung SD card mount points
      sdCardDirs.addAll([
        '/mnt/extsd',
        '/mnt/external_sd',
        '/mnt/ext_sd',
        '/storage/external_SD',
        '/storage/ext_sd',
        '/storage/removable/sdcard1',
        '/mnt/media_rw/sdcard1',
      ]);

      // Dynamic detection from /storage
      final storageDir = Directory('/storage');
      if (await storageDir.exists()) {
        await for (final entity in storageDir.list()) {
          if (entity is Directory) {
            final name = entity.path.split('/').last;
            if (name != 'emulated' && name != 'self') {
              sdCardDirs.add(entity.path);
              debugPrint('Found storage: ${entity.path}');
            }
          }
        }
      }

      // Dynamic detection from /mnt
      final mntDir = Directory('/mnt');
      if (await mntDir.exists()) {
        await for (final entity in mntDir.list()) {
          if (entity is Directory) {
            final name = entity.path.split('/').last;
            if (!['sdcard', 'asec', 'obb', 'user',
                  'shell', 'media_rw', 'secure',
                  'runtime'].contains(name)) {
              sdCardDirs.add(entity.path);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('SD detection error: $e');
    }

    allDirs.addAll(sdCardDirs);

    int idCounter = 0;
    for (final basePath in allDirs) {
      final dir = Directory(basePath);
      if (!await dir.exists()) continue;
      debugPrint('Scanning: $basePath');

      try {
        await for (final entity in dir.list(
            recursive: true, followLinks: false)) {
          if (entity is File) {
            final filePath = entity.path.toLowerCase();
            if (filePath.endsWith('.mp3') ||
                filePath.endsWith('.m4a') ||
                filePath.endsWith('.flac') ||
                filePath.endsWith('.wav') ||
                filePath.endsWith('.aac') ||
                filePath.endsWith('.ogg')) {
              try {
                final stat = await entity.stat();
                // 100KB minimum to filter junk files
                if (stat.size < 100 * 1024) continue;

                final fileName = entity.path
                    .split('/').last
                    .replaceAll(
                      RegExp(
                        r'\.(mp3|m4a|flac|wav|aac|ogg)$',
                        caseSensitive: false,
                      ),
                      '',
                    );

                String title = fileName;
                String artist = 'Unknown Artist';
                if (fileName.contains(' - ')) {
                  final parts = fileName.split(' - ');
                  artist = parts[0].trim();
                  title =
                      parts.sublist(1).join(' - ').trim();
                }

                // Avoid duplicates
                if (!songs.any(
                    (s) => s.data == entity.path)) {
                  songs.add(Song(
                    id: idCounter++,
                    title: title,
                    artist: artist,
                    album: 'Unknown Album',
                    albumId: 0,
                    duration: 0,
                    data: entity.path,
                  ));
                  debugPrint('Found: ${entity.path}');
                }
              } catch (_) {}
            }
          }
        }
      } catch (e) {
        debugPrint('Scan error $basePath: $e');
      }
    }

    songs.sort((a, b) => a.title.compareTo(b.title));
    debugPrint('Total songs: ${songs.length}');
    return songs;
  }

  Future<void> playSong(
      Song song, List<Song> songList, int index) async {
    queue = List.from(songList);
    currentIndex = index;
    currentSong = song;
    try {
      await _player.setAudioSource(
        AudioSource.uri(Uri.file(song.data)),
      );
      await _player.play();
    } catch (e) {
      debugPrint('Error playing: $e');
    }
    notifyListeners();
  }

  Future<void> playNext() async {
    if (queue.isEmpty) return;
    if (isShuffle) {
      final randomIndex = (queue.length *
              (DateTime.now().millisecondsSinceEpoch % 100) ~/
              100)
          .clamp(0, queue.length - 1);
      currentIndex = randomIndex;
    } else {
      currentIndex = (currentIndex + 1) % queue.length;
    }
    await playSong(queue[currentIndex], queue, currentIndex);
  }

  Future<void> playPrevious() async {
    if (queue.isEmpty) return;
    if (position.inSeconds > 3) {
      await _player.seek(Duration.zero);
      return;
    }
    currentIndex =
        currentIndex <= 0 ? queue.length - 1 : currentIndex - 1;
    await playSong(queue[currentIndex], queue, currentIndex);
  }

  Future<void> togglePlayPause() async {
    if (isPlaying) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> seekTo(Duration position) async {
    await _player.seek(position);
  }

  PlayerRepeatMode toggleRepeat() {
    repeatMode = switch (repeatMode) {
      PlayerRepeatMode.none => PlayerRepeatMode.all,
      PlayerRepeatMode.all => PlayerRepeatMode.one,
      PlayerRepeatMode.one => PlayerRepeatMode.none,
    };
    _savePrefs();
    notifyListeners();
    return repeatMode;
  }

  bool toggleShuffle() {
    isShuffle = !isShuffle;
    _savePrefs();
    notifyListeners();
    return isShuffle;
  }

  void createPlaylist(String name) {
    playlists.add(Playlist(
        id: DateTime.now().millisecondsSinceEpoch,
        name: name));
    _savePlaylists();
    notifyListeners();
  }

  void deletePlaylist(Playlist playlist) {
    playlists.remove(playlist);
    _savePlaylists();
    notifyListeners();
  }

  void addSongToPlaylist(Playlist playlist, Song song) {
    if (!playlist.songs.contains(song)) {
      playlist.songs.add(song);
      _savePlaylists();
      notifyListeners();
    }
  }

  void removeSongFromPlaylist(Playlist playlist, Song song) {
    playlist.songs.remove(song);
    _savePlaylists();
    notifyListeners();
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('repeat_mode', repeatMode.name);
    prefs.setBool('shuffle', isShuffle);
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final rm = prefs.getString('repeat_mode') ?? 'none';
    repeatMode = PlayerRepeatMode.values.firstWhere(
        (e) => e.name == rm,
        orElse: () => PlayerRepeatMode.none);
    isShuffle = prefs.getBool('shuffle') ?? false;
    await _loadPlaylists();
    notifyListeners();
  }

  Future<void> _savePlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final data =
        playlists.map((p) => jsonEncode(p.toJson())).toList();
    prefs.setStringList('playlists', data);
  }

  Future<void> _loadPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('playlists') ?? [];
    playlists = data.map((s) {
      final map = jsonDecode(s) as Map<String, dynamic>;
      return Playlist(
        id: map['id'] as int,
        name: map['name'] as String,
      );
    }).toList();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
