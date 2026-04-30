import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/song.dart';

class PlayerProvider extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  final OnAudioQuery _audioQuery = OnAudioQuery();

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
    final songs = await _audioQuery.querySongs(
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );
    allSongs = songs
        .where((s) => s.duration != null && s.duration! > 30000 && s.isMusic == true)
        .map((s) => Song(
              id: s.id,
              title: s.title,
              artist: s.artist ?? 'Unknown Artist',
              album: s.album ?? 'Unknown Album',
              albumId: s.albumId ?? 0,
              duration: s.duration ?? 0,
              data: s.data,
            ))
        .toList();
    notifyListeners();
  }

  Future<void> playSong(Song song, List<Song> songList, int index) async {
    queue = List.from(songList);
    currentIndex = index;
    currentSong = song;
    try {
      await _player.setAudioSource(AudioSource.uri(
        Uri.parse(song.data ?? ''),
      ));
      await _player.play();
    } catch (e) {
      debugPrint('Error playing song: $e');
    }
    notifyListeners();
  }

  Future<void> playNext() async {
    if (queue.isEmpty) return;
    currentIndex = (currentIndex + 1) % queue.length;
    await playSong(queue[currentIndex], queue, currentIndex);
  }

  Future<void> playPrevious() async {
    if (queue.isEmpty) return;
    if (position.inSeconds > 3) {
      await _player.seek(Duration.zero);
      return;
    }
    currentIndex = currentIndex <= 0 ? queue.length - 1 : currentIndex - 1;
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
