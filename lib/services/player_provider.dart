import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
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
  RepeatMode repeatMode = RepeatMode.none;
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
      case RepeatMode.one:
        _player.seek(Duration.zero);
        _player.play();
        break;
      case RepeatMode.all:
        playNext();
        break;
      case RepeatMode.none:
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
    final List<Directory> searchDirs = [];

    // Common music directories on Android
    const musicPaths = [
      '/storage/emulated/0/Music',
      '/storage/emulated/0/Download',
      '/storage/emulated/0/Downloads',
      '/storage/emulated/0/DCIM',
      '/storage/emulated/0',
    ];

    for (final path in musicPaths) {
      final dir = Directory(path);
      if (await dir.exists()) {
        searchDirs.add(dir);
      }
    }

    // Also check external SD card
    final sdCard = Directory('/storage');
    if (await sdCard.exists()) {
      try {
        await for (final entity in sdCard.list(followLinks: false)) {
          if (entity is Directory) {
            final musicDir = Directory('${entity.path}/Music');
            if (await musicDir.exists()) {
              searchDirs.add(musicDir);
            }
          }
        }
      } catch (_) {}
    }

    int idCounter = 0;
    for (final dir in searchDirs) {
      try {
        await for (final entity in dir.list(recursive: true, followLinks: false)) {
          if (entity is File) {
            final path = entity.path.toLowerCase();
            if (path.endsWith('.mp3') ||
                path.endsWith('.m4a') ||
                path.endsWith('.flac') ||
                path.endsWith('.wav') ||
                path.endsWith('.aac') ||
                path.endsWith('.ogg')) {
              final file = entity;
              final stat = await file.stat();
              // Skip files smaller than 1MB (likely not real songs)
              if (stat.size < 1024 * 1024) continue;

              final fileName = file.path
                  .split('/')
                  .last
                  .replaceAll(RegExp(r'\.(mp3|m4a|flac|wav|aac|ogg)$',
                      caseSensitive: false), '');

              // Try to parse "Artist - Title" format
              String title = fileName;
              String artist = 'Unknown Artist';
              if (fileName.contains(' - ')) {
                final parts = fileName.split(' - ');
                artist = parts[0].trim();
                title = parts.sublist(1).join(' - ').trim();
              }

              // Avoid duplicates
              if (!songs.any((s) => s.data == file.path)) {
                songs.add(Song(
                  id: idCounter++,
                  title: title,
                  artist: artist,
                  album: 'Unknown Album',
                  albumId: 0,
                  duration: 0,
                  data: file.path,
                ));
              }
            }
          }
        }
      } catch (_) {}
    }

    songs.sort((a, b) => a.title.compareTo(b.title));
    return songs;
  }

  Future<void> playSong(Song song, List<Song> songList, int index) async {
    queue = List.from(songList);
    currentIndex = index;
    currentSong = song;
    try {
      await _player.setAudioSource(
        AudioSource.uri(Uri.file(song.data)),
      );
      await _player.play();
    } catch (e) {
      debugPrint('Error playing song: $e');
    }
    notifyListeners();
  }

  Future<void> playNext() async {
    if (queue.isEmpty) return;
    if (isShuffle) {
      final randomIndex =
          (queue.length * (DateTime.now().millisecondsSinceEpoch % 100) ~/ 100)
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

  RepeatMode toggleRepeat() {
    repeatMode = switch (repeatMode) {
      RepeatMode.none => RepeatMode.all,
      RepeatMode.all => RepeatMode.one,
      RepeatMode.one => RepeatMode.none,
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
        id: DateTime.now().millisecondsSinceEpoch, name: name));
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
    repeatMode = RepeatMode.values.firstWhere(
        (e) => e.name == rm,
        orElse: () => RepeatMode.none);
    isShuffle = prefs.getBool('shuffle') ?? false;
    await _loadPlaylists();
    notifyListeners();
  }

  Future<void> _savePlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final data = playlists.map((p) => jsonEncode(p.toJson())).toList();
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
