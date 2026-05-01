import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/song.dart';

class PlayerProvider extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  static const _channel = MethodChannel('com.tealwave.player/media');

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
  Uint8List? currentAlbumArt;

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
      final List<dynamic> result =
          await _channel.invokeMethod('getSongs');
      allSongs = result.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        return Song(
          id: (map['id'] as num).toInt(),
          title: map['title'] as String? ?? 'Unknown',
          artist: map['artist'] as String? ?? 'Unknown Artist',
          album: map['album'] as String? ?? 'Unknown Album',
          albumId: (map['albumId'] as num).toInt(),
          duration: (map['duration'] as num).toInt(),
          data: map['data'] as String? ?? '',
          contentUri: map['contentUri'] as String? ?? '',
        );
      }).where((s) => s.data.isNotEmpty).toList();
      debugPrint('Songs loaded: ${allSongs.length}');
    } catch (e) {
      debugPrint('MediaStore error: $e');
      allSongs = await _scanForMusic();
    }
    isLoading = false;
    notifyListeners();
  }
  
  Future<Uint8List?> getAlbumArt(int albumId, String filePath) async {
    try {
      final result = await _channel.invokeMethod(
        'getAlbumArt',
        {
          'albumId': albumId,
          'filePath': filePath,
        },
      );
      if (result != null) {
        return Uint8List.fromList(List<int>.from(result));
      }
    } catch (e) {
      debugPrint('Album art error: $e');
    }
    return null;
  }

  Future<void> playSong(
      Song song, List<Song> songList, int index) async {
    queue = List.from(songList);
    currentIndex = index;
    currentSong = song;
    currentAlbumArt = null;
    notifyListeners();

    // Load album art
    if (song.albumId > 0) {
      getAlbumArt(song.albumId, song.data).then((art) {
        currentAlbumArt = art;
        notifyListeners();
      });
    }

    try {
      // Try content URI first (works with SD card),
      // fall back to file path
      final uri = song.contentUri.isNotEmpty
          ? Uri.parse(song.contentUri)
          : Uri.file(song.data);

      await _player.setAudioSource(AudioSource.uri(uri));
      await _player.play();
    } catch (e) {
      debugPrint('Error playing with content URI: $e');
      // Try file path as fallback
      try {
        await _player.setAudioSource(
            AudioSource.uri(Uri.file(song.data)));
        await _player.play();
      } catch (e2) {
        debugPrint('Error playing with file path: $e2');
      }
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

  // Fallback file scanner
  Future<List<Song>> _scanForMusic() async {
    final List<Song> songs = [];
    final List<String> allDirs = [
      '/storage/emulated/0/Music',
      '/storage/emulated/0/Download',
      '/storage/emulated/0/Downloads',
      '/storage/emulated/0/Songs',
    ];
    try {
      final storageDir = Directory('/storage');
      if (await storageDir.exists()) {
        await for (final entity in storageDir.list()) {
          if (entity is Directory) {
            final name = entity.path.split('/').last;
            if (name != 'emulated' && name != 'self') {
              allDirs.add(entity.path);
              allDirs.add('${entity.path}/Songs');
              allDirs.add('${entity.path}/Music');
            }
          }
        }
      }
    } catch (_) {}

    int idCounter = 0;
    for (final path in allDirs) {
      final dir = Directory(path);
      if (!await dir.exists()) continue;
      try {
        await for (final entity
            in dir.list(recursive: true, followLinks: false)) {
          if (entity is File) {
            final fp = entity.path.toLowerCase();
            if (fp.endsWith('.mp3') || fp.endsWith('.m4a') ||
                fp.endsWith('.flac') || fp.endsWith('.wav') ||
                fp.endsWith('.aac') || fp.endsWith('.ogg')) {
              try {
                final stat = await entity.stat();
                if (stat.size < 100 * 1024) continue;
                final fileName = entity.path.split('/').last
                    .replaceAll(RegExp(
                      r'\.(mp3|m4a|flac|wav|aac|ogg)$',
                      caseSensitive: false), '');
                String title = fileName;
                String artist = 'Unknown Artist';
                if (fileName.contains(' - ')) {
                  final parts = fileName.split(' - ');
                  artist = parts[0].trim();
                  title = parts.sublist(1).join(' - ').trim();
                }
                if (!songs.any((s) => s.data == entity.path)) {
                  songs.add(Song(
                    id: idCounter++,
                    title: title,
                    artist: artist,
                    album: 'Unknown Album',
                    albumId: 0,
                    duration: 0,
                    data: entity.path,
                  ));
                }
              } catch (_) {}
            }
          }
        }
      } catch (_) {}
    }
    songs.sort((a, b) => a.title.compareTo(b.title));
    return songs;
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
