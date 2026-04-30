class Song {
  final int id;
  final String title;
  final String artist;
  final String album;
  final int albumId;
  final int duration;
  final String? data;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.albumId,
    required this.duration,
    this.data,
  });

  String get durationFormatted {
    final seconds = duration ~/ 1000;
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  bool operator ==(Object other) => other is Song && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class Playlist {
  final int id;
  String name;
  List<Song> songs;

  Playlist({
    required this.id,
    required this.name,
    List<Song>? songs,
  }) : songs = songs ?? [];

  int get songCount => songs.length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'songIds': songs.map((s) => s.id).toList(),
      };
}

enum RepeatMode { none, all, one }
