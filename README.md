# 🎵 TealWave — Flutter Music Player

Dark teal offline music player for Android (Samsung J7 Duo and all Android 5+).

---

## ✨ Features
- 🎨 Dynamic album art colors on the player screen
- 📋 Playlists — create, edit, swipe-to-delete
- 🔁 Repeat: Off / All / One (like Spotify)
- 🔀 Shuffle
- 📜 Queue — see and tap any song
- 📝 Lyrics (reads embedded ID3 tags)
- 🔔 Lock screen & notification controls
- 🔉 Background playback

---

## 📲 Build APK With No PC — Using Codemagic (Free)

### Step 1: Upload code to GitHub
1. Go to **github.com** → sign up free if needed
2. Create a **New Repository** → name it `tealwave`
3. Upload all files from this ZIP (drag & drop the folder)

### Step 2: Connect to Codemagic
1. Go to **codemagic.io** → Sign in with GitHub
2. Click **Add application** → select your `tealwave` repo
3. Choose **Flutter App**
4. Codemagic will auto-detect `codemagic.yaml`
5. Click **Start your first build**

### Step 3: Download APK
1. Build takes ~5–10 minutes
2. You'll get an email with a download link
3. Download the APK on your phone
4. On your phone: **Settings → Install unknown apps → allow**
5. Open the APK to install TealWave ✅

---

## 🛠️ Build Locally (If You Have a PC)

```bash
# Install Flutter from flutter.dev
flutter pub get
flutter build apk --release
# APK at: build/app/outputs/flutter-apk/app-release.apk
```

---

## 📂 Project Structure

```
lib/
├── main.dart                  # App entry, permissions, navigation
├── models/song.dart           # Song, Playlist, RepeatMode
├── services/player_provider.dart  # All playback logic (Provider)
├── utils/theme.dart           # Dark teal theme
├── screens/
│   ├── songs_screen.dart      # Song list + search
│   ├── library_screen.dart    # Albums + Artists tabs
│   ├── playlists_screen.dart  # Playlists + detail screen
│   ├── now_playing_screen.dart # Immersive player + dynamic colors
│   └── queue_screen.dart      # Queue + Lyrics bottom sheets
└── widgets/
    └── common_widgets.dart    # AlbumArt, SongTile, MiniPlayer
```

---

## 🎨 Design
- Base: Dark `#0D1117` + Teal `#00BFA5`
- Now Playing: Album art color extracted with Palette API, animates to repaint the whole screen
- Style: Lark Player-inspired — immersive, bold, full-screen art

---

## 📦 Key Dependencies

| Package | Purpose |
|---|---|
| `just_audio` | Rock-solid audio playback |
| `audio_service` | Background + lock screen |
| `on_audio_query` | Scans device music library |
| `palette_generator` | Dynamic colors from album art |
| `provider` | State management |
| `permission_handler` | Storage permissions |

---

## 💡 Tips

- **Lyrics**: Add lyrics to MP3s using **Mp3tag** (Windows) or **Kid3** (Linux)
- **Album Art**: Embed cover art in MP3 using Mp3tag → select all songs → Tag → Cover Art
- **Swipe left** on a playlist to delete it
- **Long-press** a song to add it to a playlist or play next

---

*Built with Flutter & ❤️*
