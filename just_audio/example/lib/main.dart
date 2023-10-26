import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

final audioPlayer = Player();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  audioPlayer.init();
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with WidgetsBindingObserver {
  final AudioPlayer _player = audioPlayer.player;
  List<String> _songs = [];
  List<String> _playingStatus = []; // stopped/loading/playing
  final _playingIcon = {
    'stopped': const Icon(Icons.play_arrow, size: 50),
    'loading': SizedBox(height: 50, child: CircularProgressIndicator()),
    'playing': const Icon(Icons.pause, size: 50),
  };
  String? _currentSong = null;

  Future<void> _init() async {
    //final session = await AudioSession.instance;
    //await session.configure(const AudioSessionConfiguration.speech());
    // Listen to errors during playback.
    _player.playbackEventStream.listen((event) {}, onError: (Object e, StackTrace stackTrace) {
      print('A stream error occurred: $e');
    });
  }

  @override
  void initState() {
    super.initState();
    _songs = [
      'https://www.andreymusic.com/misc/Andrey-Samode-Totally-Mature.mp3',
      'https://www.andreymusic.com/misc/Andrey-Samode-Benefactor.mp3',
      'https://www.andreymusic.com/misc/Andrey-Samode-Mana.mp3'
    ];
    for (var song in _songs) {
      _playingStatus.add('stopped');
    }
    _init();
  }

  @override
  void dispose() {
    super.dispose();
    _player.dispose();
  }

  Future<void> _playSong(int id) async {
    final song = _songs[id];
    if (song == _currentSong) {
      // current song - resume/pause
      if (_player.playing || _playingStatus[id] == 'loading') {
        _player.pause();
        setState(() {
          _playingStatus[id] = 'stopped';
        });
      } else {
        _player.play();
        //await _player.stop();
        setState(() {
          _playingStatus[id] = 'playing';
        });
      }
    } else {
      // new song - load & play
      _currentSong = song;
      setState(() {
        for (var i = 0; i < _playingStatus.length; i++) {
          _playingStatus[i] = 'stopped';
        }
        _playingStatus[id] = 'loading';
      });
      try {
        await _player.stop();
        await _player.setAudioSource(AudioSource.uri(
          Uri.parse(_currentSong!),
        ));
        _player.play();
        if (_player.playing) {
          setState(() {
            _playingStatus[id] = 'playing';
          });
        }
      } on PlayerException catch (e) {
        print("Error code: ${e.code}");
        print("Error message: ${e.message}");
      } on PlayerInterruptedException catch (e) {
        print("Connection aborted: ${e.message}");
      } catch (e) {
        print("Error loading audio source.");
        _currentSong = null;
        _player.stop();
        setState(() {
          _playingStatus[id] = 'stopped';
        });
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Error loading preview audio.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: ListView.builder(
            itemCount: _songs.length,
            itemBuilder: (ctx, index) {
              return ListTile(
                contentPadding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                horizontalTitleGap: 10,
                minLeadingWidth: 45,
                // !song - icon
                leading: _playingIcon[_playingStatus[index]],
                // !song - title
                title: Text('Song #${index + 1}'),
                // !song - action
                onTap: () => _playSong(index),
              );
            },
          ),
        ),
      ),
    );
  }
}

class Player {
  late AudioPlayer _player;
  init() async {
    _player = AudioPlayer(
      audioLoadConfiguration: AudioLoadConfiguration(
        androidLoadControl: AndroidLoadControl(prioritizeTimeOverSizeThresholds: true),
      ),
    );

    // catch playback errors
    _player.playbackEventStream.listen((event) {}, onError: (Object e, StackTrace st) {
      if (e is PlayerException) {
        print('Error code: ${e.code}');
        print('Error message: ${e.message}');
      } else {
        print('An error occurred: $e');
      }
    });
  }

  get player => _player;
}
