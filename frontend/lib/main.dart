import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

const Color color1 = Color.fromARGB(255, 12, 12, 12);
const Color color2 = Color.fromARGB(255, 12, 79, 28);
const Color color3 = Color.fromARGB(255, 183, 183, 183);
const Color color4 = Color.fromARGB(255, 66, 255, 41);
const Color color5 = Color.fromARGB(255, 255, 41, 41);
const Color color6 = Color.fromARGB(255, 23, 23, 23);

const Color textColor1 = Color.fromARGB(255, 125, 125, 125);
const Color textColor2 = Color.fromARGB(255, 105, 105, 105);

class Song {
  late String artist;
  late String name;
  late String albumCover;
  late String uri;
  late int votes;
  late bool isPlaying;
  late bool isLockedIn;
  late int status;

  Song(this.artist, this.name, this.albumCover, this.uri, this.votes,
      this.isPlaying, this.isLockedIn, this.status);

  factory Song.fromJson(dynamic json) {
    bool _isPlaying =
        json.containsKey("is_playing") ? json["is_playing"] as bool : false;
    bool _isLockedIn =
        json.containsKey("is_locked_in") ? json["is_locked_in"] as bool : false;

    return Song(
        json['artist'] as String,
        json['title'] as String,
        json['album_cover'] as String,
        json['uri'] as String,
        json['votes'] as int,
        _isPlaying,
        _isLockedIn,
        0);
  }

  Map<String, dynamic> toJson() => {
        "artist": artist,
        "title": name,
        "album_cover": albumCover,
        "uri": uri,
        "votes": votes,
        "duration": 0,
      };

  String getHash() {
    return name + albumCover + artist;
  }

  Widget getWidget(double size) {
    return Container(
        child: Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          height: 1.0 * size,
          width: 1.0 * size,
          child: Image.network(albumCover),
        ),
        Container(
          // width: 1.0 * size,
          padding: EdgeInsets.only(left: .15 * size),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                  width: 120,
                  child: Text(name,
                      style:
                          TextStyle(color: textColor1, fontSize: .2 * size))),
              Text(artist,
                  style: TextStyle(color: textColor2, fontSize: .15 * size))
            ],
          ),
        )
      ],
    ));
  }
}

void main() {
  runApp(const MyApp());
}

final url = "172.20.10.4";
final port = "8000";

class MainProvider extends ChangeNotifier {
  final port = 5004;

  Song? mainSong;

  late List<Song> _songs;
  List<String> _upHashMap = [];
  List<String> _downHashMap = [];

  late Socket socket;

  List<Song> get songs => _songs.map((song) {
        String hash = song.getHash();

        if (_upHashMap.contains(hash)) {
          song.status = 1;
        } else if (_downHashMap.contains(hash)) {
          song.status = -1;
        } else {
          song.status = 0;
        }
        return song;
      }).toList();

  MainProvider() {
    _songs = [];

    mainSong = null;

    Socket.connect(url, port).then((Socket sock) {
      socket = sock;
      socket.listen(_dataHandler,
          onError: _errorHandler, onDone: _doneHandler, cancelOnError: false);
    });

    _getExistingList();
  }

  Future<void> updateUpArrow(Song song) async {
    String hash = song.getHash();

    switch (song.status) {
      case -1:
        await _vote(song.uri, 2);
        break;
      case 0:
        await _vote(song.uri, 1);
        break;
      case 1:
        await _vote(song.uri, -1);
        break;
    }

    if (song.status == 1) {
      _upHashMap.removeWhere((String item) => item == hash);
    } else {
      _downHashMap.removeWhere((String item) => item == hash);
      _upHashMap.add(hash);
    }
    notifyListeners();
  }

  Future<void> updateDownArrow(Song song) async {
    String hash = song.getHash();

    switch (song.status) {
      case -1:
        await _vote(song.uri, 1);
        break;
      case 0:
        await _vote(song.uri, -1);
        break;
      case 1:
        await _vote(song.uri, -2);
        break;
    }

    if (song.status == -1) {
      _downHashMap.removeWhere((String item) => item == hash);
    } else {
      _upHashMap.removeWhere((String item) => item == hash);
      _downHashMap.add(hash);
    }
    notifyListeners();
  }

  Future<void> _getExistingList() async {
    String endpoint = "http://" + url + ":8000/auxing/getList/";

    var response = await http.get(Uri.parse(endpoint));
    var _songsJson = jsonDecode(response.body);
    _songs = List<Song>.from(_songsJson.map((song) => Song.fromJson(song)));

    if (_songs.length > 0) {
      mainSong = _songs[_songs.length - 1];
      _songs.removeAt(_songs.length - 1);
    }

    notifyListeners();
  }

  Future<void> _vote(String uri, int vote) async {
    String endpoint = "http://" + url + ":8000/auxing/vote/";

    await http
        .post(Uri.parse(endpoint), body: {"vote": vote.toString(), "uri": uri});
  }

  void _dataHandler(data) {
    var _songsJson = jsonDecode(String.fromCharCodes(data));
    _songs = List<Song>.from(_songsJson.map((song) => Song.fromJson(song)));

    if (_songs.length > 0) {
      mainSong = _songs[_songs.length - 1];
      _songs.removeAt(_songs.length - 1);
    }
    notifyListeners();
  }

  void _errorHandler(error, StackTrace trace) {
    print(error);
  }

  void _doneHandler() {
    socket.destroy();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: WelcomePage());
  }
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print("WelcomePage");
    return Scaffold(
        backgroundColor: color1,
        body: Container(
          padding: EdgeInsets.symmetric(vertical: 100),
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Center(
                  child: Text(
                    "AUX",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 128, color: color2),
                  ),
                ),
              ),
              Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                        child: _buttonWidget("Create Lobby", color3, color6),
                        onTap: () =>
                            _authenticate().then((value) => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const MainPage()),
                                ))),
                    GestureDetector(
                        child: _buttonWidget("Join Lobby", color2, color3),
                        onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const MainPage()),
                            ))
                  ]),
            ],
          ),
        ));
  }

  Widget _buttonWidget(String name, Color color, Color textColor) {
    return Container(
        margin: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        width: 280,
        height: 50,
        child: Center(
          child: Text(name, style: TextStyle(color: textColor, fontSize: 20)),
        ));
  }

  Future<void> _authenticate() async {
    String CLIENT_ID = 'c287f4b6bc874c2ab63169028d5aedc1';
    String CLIENT_SECRET = '81f3641081dc4e50bc950346f1c2562a';
    String SPOTIPY_REDIRECT_URI =
        "http://172.20.10.4:8000/auxing/authenticate/";
    String SCOPE =
        "user-modify-playback-state playlist-modify-public user-read-currently-playing";
    String CACHE = '.spotipyoauthcache';
    int PORT = 8000;

    String urlString =
        "https://accounts.spotify.com/authorize?response_type=code&client_id=${CLIENT_ID}&scope=${SCOPE}&redirect_uri=${SPOTIPY_REDIRECT_URI}&state=5";

    var url = Uri.parse(urlString);

    print(urlString);

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    print("MainPage");
    return MaterialApp(
        home: ChangeNotifierProvider(
            create: (context) => MainProvider(),
            child: Consumer<MainProvider>(
                builder: (context, provider, child) => Scaffold(
                        body: Container(
                      padding: EdgeInsets.only(top: 20, left: 20, right: 20),
                      color: color1,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Container(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                    padding: EdgeInsets.only(bottom: 10),
                                    alignment: Alignment.bottomCenter,
                                    height: 90,
                                    child: GestureDetector(
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => SearchPage()),
                                      ),
                                      child: const Icon(
                                        Icons.search,
                                        size: 48,
                                        color: color3,
                                      ),
                                    )),
                              ],
                            ),
                          ),
                          MainSongWidget(song: provider.mainSong),
                          SongListWidget(songs: provider.songs)
                        ],
                      ),
                    )))));
  }
}

class SearchPage extends StatefulWidget {
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List<Song> _songs = [];
  String _searchTerm = "";

  @override
  Widget build(BuildContext context) {
    print("SearchPage");
    return MaterialApp(
        home: Scaffold(
            body: Container(
      width: double.infinity,
      height: double.infinity,
      color: color1,
      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 40),
            // height: 100,
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.keyboard_double_arrow_left,
                          color: color3,
                          size: 48,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        child: TextField(
                          onChanged: ((value) => _searchTerm = value),
                          style: const TextStyle(color: color3),
                          decoration: const InputDecoration(
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: color2, width: 1.0),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(16)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: color3, width: 1.0),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(16)),
                            ),
                            border: OutlineInputBorder(),
                            hintText: 'Enter a search term',
                            hintStyle: TextStyle(color: textColor1),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => _search(),
                  child: Container(
                      decoration: BoxDecoration(
                          color: color3,
                          borderRadius: BorderRadius.all(Radius.circular(15))),
                      width: double.infinity,
                      height: 40,
                      margin: EdgeInsets.symmetric(vertical: 15),
                      child: Center(
                          child: Text("Search",
                              style:
                                  TextStyle(color: textColor2, fontSize: 24)))),
                )
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.only(top: 20),
              child: ListView.builder(
                  padding: EdgeInsets.only(top: 0),
                  itemCount: _songs.length,
                  itemBuilder: (BuildContext context, int index) {
                    return GestureDetector(
                      child: SongWidget(
                        song: _songs[index],
                        isSearch: true,
                      ),
                      onTap: () => _addToQueue(_songs[index]),
                    );
                  }),
            ),
          ),
        ],
      ),
    )));
  }

  Future<void> _search() async {
    // _songs = List<Song>.from(fakeData.map((song) => Song.fromJson(song)));
    String endpoint = "http://" + url + ":" + port + "/auxing/search/";
    var response =
        await http.post(Uri.parse(endpoint), body: {"thing": _searchTerm});
    var songJsons = json.decode(response.body);
    _songs = List<Song>.from(songJsons.map((song) => Song.fromJson(song)));
    setState(() {});
  }

  Future<void> _addToQueue(Song song) async {
    String endpoint = "http://" + url + ":" + port + "/auxing/addToList/";

    await http
        .post(Uri.parse(endpoint), body: {"json": json.encode(song.toJson())});
    Navigator.pop(context);
  }
}

class MainSongWidget extends StatelessWidget {
  late Song? song;

  MainSongWidget({required this.song});

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.only(left: 30),
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
            color: color2, borderRadius: BorderRadius.all(Radius.circular(20))),
        child: song != null ? song!.getWidget(120) : Container());
  }
}

class SongListWidget extends StatelessWidget {
  late List<Song> songs;

  SongListWidget({
    required this.songs,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.only(top: 10),
        child: Container(
          decoration: BoxDecoration(
              // color: color6,
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20), topRight: Radius.circular(20))),
          child: ListView.builder(
              padding: EdgeInsets.only(top: 0),
              itemCount: songs.length,
              itemBuilder: (BuildContext context, int index) {
                return SongWidget(song: songs[index]);
              }),
        ),
      ),
    );
  }
}

class SongWidget extends StatefulWidget {
  late Song song;
  late bool isSearch;

  SongWidget({required this.song, this.isSearch = false});

  @override
  State<SongWidget> createState() => _SongWidgetState();
}

class _SongWidgetState extends State<SongWidget> {
  @override
  void initState() {
    super.initState();
  }

  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: 10),
      child: Container(
          decoration: BoxDecoration(
              color: color6,
              border: Border.all(
                  color: widget.song.isLockedIn && !widget.isSearch
                      ? color2
                      : Colors.transparent,
                  width: 2),
              borderRadius: BorderRadius.all(Radius.circular(20))),
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          height: 100,
          width: double.infinity,
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            widget.song.getWidget(60),
            Container(
                width: 100,
                child: Center(
                    child: widget.isSearch
                        ? _addSongToQueue()
                        : widget.song.isLockedIn
                            ? _lockedInWidget()
                            : _voteWidget(widget.song)))
          ])),
    );
  }

  Widget _addSongToQueue() {
    return Container(
        width: 80,
        height: 35,
        decoration: BoxDecoration(
            color: color3, borderRadius: BorderRadius.all(Radius.circular(20))),
        child: Center(
            child: Text("Add",
                style: TextStyle(fontSize: 18, color: textColor2))));
  }

  Widget _lockedInWidget() {
    return Container(
      child: Text("Locked-In",
          style: const TextStyle(color: color2, fontSize: 16)),
    );
  }

  Widget _voteWidget(Song song) {
    MainProvider provider = Provider.of<MainProvider>(context, listen: false);

    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => provider.updateUpArrow(song),
            child: Icon(
              Icons.arrow_upward_outlined,
              color: (widget.song.status == 1) ? color4 : color3,
              size: 36,
            ),
          ),
          Container(
            width: 28,
            child: Center(
              child: Text(song.votes.toString(),
                  style: TextStyle(
                      color: (widget.song.status == 1)
                          ? color4
                          : ((widget.song.status == -1) ? color5 : color3),
                      fontSize: 24)),
            ),
          ),
          GestureDetector(
            onTap: () => provider.updateDownArrow(song),
            child: Icon(
              Icons.arrow_downward_outlined,
              color: (widget.song.status == -1) ? color5 : color3,
              size: 36,
            ),
          ),
        ],
      ),
    );
  }

  Widget _selectWidget(Song song) {
    return Container(child: Center(child: Text("Select")));
  }
}
