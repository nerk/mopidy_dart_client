// MIT License

// Copyright (c) 2022 Thomas Kern

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import 'package:collection/collection.dart';

Function _eq = const ListEquality().equals;

class _JsonKeywords {
  //static const String title = "title";
  //static const String timePosition = "time_position";
  //static const String tlTrack = "tl_track";
  static const String tlId = "tlid";
  static const String track = "track";
  static const String tracks = "tracks";
  static const String numTracks = "num_tracks";
  static const String numDiscs = "num_discs";

  //static const String event = "event";
  //static const String mute = "mute";
  static const String volume = "volume";
  static const String oldState = "old_state";
  static const String newState = "new_state";

  //static const String playlist = "playlist";
  static const String uri = "uri";
  static String width = "width";
  static String height = "height";

  //static String method = "method";
  //static String jsonRpc = "jsonrpc";
  //static String params = "params";
  //static String id = "id";
  //static String result = "result";
  //static String error = "error";
  //static String code = "code";
  //static String message = "message";
  //static String data = "data";
  static String date = "date";

  //static String uris = "uris";
  static String name = "name";
  static String sortName = "sortname";
  static String artists = "artists";
  static String album = "album";
  static String albums = "albums";
  static String performers = "performers";
  static String composers = "composers";
  static String lastModified = "last_modified";
  static String musicbrainzId = "musicbrainz_id";
  static String genre = "genre";
  static String trackNo = "track_no";
  static String discNo = "disc_no";
  static String length = "length";
  static String bitrate = "bitrate";
  static String comment = "comment";
  static String type = "type";
}

/// Abstract base class for objects sent to and received from the Mopidy server.
abstract class Model {
  /// Extra data may be used by client to attach arbitrary data
  dynamic extraData;

  Model();

  /// Runtime type as a string
  String getTypeName() {
    return runtimeType.toString();
  }

  Map<String, dynamic> toMap() {
    return _finish({});
  }

  Map<String, dynamic> _finish(Map<String, dynamic> source) {
    Map<String, dynamic> result = {'__model__': getTypeName(), ...source};
    result.removeWhere((key, value) => value == null);
    return result;
  }

  @override
  String toString() {
    return "${getTypeName()}:${toMap()}";
  }

  factory Model.fromMap(Map<String, dynamic> data) {
    Map<String, Model Function(Map<String, dynamic>)> converter = {
      'Artist': Artist.fromMap,
      'Album': Album.fromMap,
      'Image': Image.fromMap,
      'Track': Track.fromMap,
      'TlTrack': TlTrack.fromMap,
      'Playlist': Playlist.fromMap,
      'PlaybackState': PlaybackState.fromMap,
      'SearchResult': SearchResult.fromMap,
      'Volume': Volume.fromMap,
      'Ref': Ref.fromMap
    };

    String typeName = data['__model__'];
    return converter[typeName]!.call(data);
  }

  static dynamic convert(Object? obj) {
    if (obj == null) {
      return null;
    }

    if (obj is Map && obj.containsKey('__model__')) {
      return Model.fromMap(obj as Map<String, dynamic>);
    } else if (obj is Map) {
      return _convertMap(obj);
    } else if (obj is List) {
      return _convertList(obj);
    }
    return obj;
  }

  static Map _convertMap(Map map) {
    for (var key in map.keys) {
      map[key] = convert(map[key]);
    }
    return map;
  }

  static List _convertList(List list) {
    return list.map((item) => convert(item)).toList();
  }
}

/// Model to represent URI references with a human friendly name and type attached.
/// This is intended for use a lightweight object “free” of metadata that can be passed around
/// instead of using full blown models.
class Ref extends Model {
  /// Constant used for comparison with the type field.
  static const String typeAlbum = "album";

  /// Constant used for comparison with the type field.
  static const String typeArtist = "artist";

  /// Constant used for comparison with the type field.
  static const String typePlaylist = "playlist";

  /// Constant used for comparison with the type field.
  static const String typeDirectory = "directory";

  /// Constant used for comparison with the type field.
  static const String typeTrack = "track";

  /// Object URI
  final String uri;

  /// Object name
  final String name;

  /// Object type
  final String type;

  Ref(this.uri, this.name, this.type);

  factory Ref.fromMap(Map<String, dynamic> jsonMap) {
    return Ref(jsonMap[_JsonKeywords.uri], jsonMap[_JsonKeywords.name],
        jsonMap[_JsonKeywords.type]);
  }

  @override
  Map<String, dynamic> toMap() {
    return _finish({
      _JsonKeywords.uri: uri,
      _JsonKeywords.name: name,
      _JsonKeywords.type: type
    });
  }

  @override
  bool operator ==(Object other) =>
      other is Ref &&
      other.runtimeType == runtimeType &&
      other.uri == uri &&
      other.name == name &&
      other.type == type;

  @override
  int get hashCode => Object.hash(uri, name, type);
}

/// Object representing an artist.
class Artist extends Model {
  /// Object URI. This might be absent in case of looking up
  /// a track when the 'file' extension is used.
  final String? uri;

  // Object name
  final String name;

  // artist name for sorting
  String? sortName;

  // MusicBrainz ID
  final String? musicbrainzId;

  Artist(this.uri, this.name, this.sortName, this.musicbrainzId);

  factory Artist.fromMap(Map<String, dynamic> jsonMap) {
    return Artist(jsonMap[_JsonKeywords.uri], jsonMap[_JsonKeywords.name],
        jsonMap[_JsonKeywords.sortName], jsonMap[_JsonKeywords.musicbrainzId]);
  }

  @override
  Map<String, dynamic> toMap() {
    return _finish({
      _JsonKeywords.uri: uri,
      _JsonKeywords.name: name,
      _JsonKeywords.sortName: sortName,
      _JsonKeywords.musicbrainzId: musicbrainzId
    });
  }

  @override
  bool operator ==(Object other) =>
      other is Artist &&
      other.runtimeType == runtimeType &&
      other.uri == uri &&
      other.name == name &&
      other.sortName == sortName &&
      other.musicbrainzId == musicbrainzId;

  @override
  int get hashCode => Object.hash(uri, name, sortName, musicbrainzId);
}

/// Object representing an album.
class Album extends Model {
  /// Object URI. This is not present in case of looking up
  /// a track when the 'file' extension is used.
  final String? uri;

  /// Object name
  final String name;

  /// Album artists
  final List<Artist> artists;

  /// Number of tracks in album or Null if unknown
  final int? numTracks;

  ///  Number of discs in album or Null if unknown
  final int? numDiscs;

  /// Album release date (YYYY or YYYY-MM-DD)
  final String? date;

  /// MusicBrainz ID
  final String? musicbrainzId;

  Album(this.uri, this.name, this.artists, this.numTracks, this.numDiscs,
      this.date, this.musicbrainzId);

  factory Album.fromMap(Map<String, dynamic> jsonMap) {
    return Album(
        jsonMap[_JsonKeywords.uri],
        jsonMap[_JsonKeywords.name],
        Model.convert(jsonMap[_JsonKeywords.artists])?.cast<Artist>() ??
            <Artist>[],
        jsonMap[_JsonKeywords.numTracks],
        jsonMap[_JsonKeywords.numDiscs],
        jsonMap[_JsonKeywords.date],
        jsonMap[_JsonKeywords.musicbrainzId]);
  }

  @override
  Map<String, dynamic> toMap() {
    return _finish({
      _JsonKeywords.uri: uri,
      _JsonKeywords.name: name,
      _JsonKeywords.artists: artists.isNotEmpty
          ? artists.map((artist) => artist.toMap()).toList()
          : null,
      _JsonKeywords.numTracks: numTracks,
      _JsonKeywords.numDiscs: numDiscs,
      _JsonKeywords.date: date,
      _JsonKeywords.musicbrainzId: musicbrainzId
    });
  }

  @override
  bool operator ==(Object other) =>
      other is Album &&
      other.runtimeType == runtimeType &&
      other.uri == uri &&
      other.name == name &&
      _eq(other.artists, artists) &&
      other.numTracks == numTracks &&
      other.numDiscs == numDiscs &&
      other.date == date &&
      other.musicbrainzId == musicbrainzId;

  @override
  int get hashCode =>
      Object.hash(uri, name, artists, numTracks, numDiscs, date, musicbrainzId);
}

/// Image representing an album cover.
class Image extends Model {
  /// URI of the image
  final String uri;

  /// Optional width of image or Null
  final int? width;

  /// Optional height of image or Null
  final int? height;

  Image(this.uri, this.width, this.height);

  factory Image.fromMap(Map<String, dynamic> jsonMap) {
    return Image(jsonMap[_JsonKeywords.uri], jsonMap[_JsonKeywords.width],
        jsonMap[_JsonKeywords.height]);
  }

  @override
  Map<String, dynamic> toMap() {
    return _finish({
      _JsonKeywords.uri: uri,
      _JsonKeywords.width: width,
      _JsonKeywords.height: height
    });
  }

  @override
  bool operator ==(Object other) =>
      other is Image &&
      other.runtimeType == runtimeType &&
      other.uri == uri &&
      other.width == width &&
      other.height == height;

  @override
  int get hashCode => Object.hash(uri, width, height);
}

/// Track from an album.
class Track extends Model {
  /// Object URI
  final String uri;

  /// Object name
  final String name;

  /// Track artists
  final List<Artist> artists;

  /// Track album
  final Album? album;

  /// Track composers
  final List<Artist> composers;

  /// Track performers
  final List<Artist> performers;

  /// Track genre
  final String? genre;

  /// Track number in album or Null if unknown
  final int? trackNo;

  /// Disc number in album ot Null if unknown
  final int? discNo;

  /// Track release date (YYYY or YYYY-MM-DD)
  final String? date;

  /// Track length in milliseconds or Null if there is no duration
  final int? length;

  /// Bitrate in kBit/s
  final int? bitrate;

  /// Track comment
  final String? comment;

  /// MusicBrainz ID
  final String? musicbrainzId;

  /// Represents last modification time
  final int? lastModified;

  Track(
      this.uri,
      this.name,
      this.artists,
      this.album,
      this.composers,
      this.performers,
      this.genre,
      this.trackNo,
      this.discNo,
      this.date,
      this.length,
      this.bitrate,
      this.comment,
      this.musicbrainzId,
      this.lastModified);

  factory Track.fromMap(Map<String, dynamic> jsonMap) {
    return Track(
        jsonMap[_JsonKeywords.uri] as String,
        // Server returns a response with no name for invalid streams, because
        // Mopidy server treats this as a warning, not as an error. Insert INVALID_STREAM as a workaround.
        jsonMap[_JsonKeywords.name] ?? 'INVALID_STREAM_ERROR',
        Model.convert(jsonMap[_JsonKeywords.artists])?.cast<Artist>() ??
            <Artist>[],
        Model.convert(jsonMap[_JsonKeywords.album]) as Album?,
        Model.convert(jsonMap[_JsonKeywords.composers])?.cast<Artist>() ??
            <Artist>[],
        Model.convert(jsonMap[_JsonKeywords.performers])?.cast<Artist>() ??
            <Artist>[],
        jsonMap[_JsonKeywords.genre] as String?,
        jsonMap[_JsonKeywords.trackNo] as int?,
        jsonMap[_JsonKeywords.discNo] as int?,
        jsonMap[_JsonKeywords.date] as String?,
        jsonMap[_JsonKeywords.length] as int?,
        jsonMap[_JsonKeywords.bitrate] as int?,
        jsonMap[_JsonKeywords.comment] as String?,
        jsonMap[_JsonKeywords.musicbrainzId] as String?,
        jsonMap[_JsonKeywords.lastModified] as int?);
  }

  @override
  Map<String, dynamic> toMap() {
    return _finish({
      _JsonKeywords.uri: uri,
      _JsonKeywords.name: name,
      _JsonKeywords.artists: artists.isNotEmpty
          ? artists.map((artist) => artist.toMap()).toList()
          : null,
      _JsonKeywords.album: album?.toMap(),
      _JsonKeywords.composers: composers.isNotEmpty
          ? composers.map((composer) => composer.toMap()).toList()
          : null,
      _JsonKeywords.performers: performers.isNotEmpty
          ? performers.map((performer) => performer.toMap()).toList()
          : null,
      _JsonKeywords.genre: genre,
      _JsonKeywords.trackNo: trackNo,
      _JsonKeywords.discNo: discNo,
      _JsonKeywords.date: date,
      _JsonKeywords.length: length,
      _JsonKeywords.bitrate: bitrate,
      _JsonKeywords.comment: comment,
      _JsonKeywords.musicbrainzId: musicbrainzId,
      _JsonKeywords.lastModified: lastModified
    });
  }

  @override
  bool operator ==(Object other) =>
      other is Track &&
      other.runtimeType == runtimeType &&
      other.uri == uri &&
      other.name == name &&
      _eq(other.artists, artists) &&
      other.album == album &&
      _eq(other.composers, composers) &&
      _eq(other.performers, performers) &&
      other.genre == genre &&
      other.trackNo == trackNo &&
      other.discNo == discNo &&
      other.date == date &&
      other.length == length &&
      other.bitrate == bitrate &&
      other.comment == comment &&
      other.musicbrainzId == musicbrainzId &&
      other.lastModified == lastModified;

  @override
  int get hashCode => Object.hash(
      uri,
      name,
      artists,
      album,
      composers,
      performers,
      genre,
      trackNo,
      discNo,
      date,
      length,
      bitrate,
      comment,
      musicbrainzId,
      lastModified);
}

/// A tracklistt track. Wraps a regular track and it's tracklist ID.
///
/// The use of [TlTrack] allows the same track to appear multiple times in the
/// tracklist.
class TlTrack extends Model {
  /// Tracklist ID
  final int tlid;

  /// Track
  final Track track;

  TlTrack(this.tlid, this.track);

  factory TlTrack.fromMap(Map<String, dynamic> jsonMap) {
    return TlTrack(jsonMap[_JsonKeywords.tlId] as int,
        Track.fromMap(jsonMap[_JsonKeywords.track]));
  }

  @override
  Map<String, dynamic> toMap() {
    return _finish({_JsonKeywords.tlId: tlid, _JsonKeywords.track: track});
  }

  @override
  bool operator ==(Object other) =>
      other is TlTrack &&
      other.runtimeType == runtimeType &&
      other.tlid == tlid &&
      other.track == track;

  @override
  int get hashCode => Object.hash(tlid, track);
}

/// A Playlist.
class Playlist extends Model {
  /// Object URI
  final String uri;

  /// Object name. Since playlists may be renamed,
  /// [name] is non-final.
  String name;

  /// Playlist's tracks
  List<Track> _tracks;

  /// Last playlist's modification time in milliseconds since Unix epoch or Null if unknown
  int? _lastModified;

  Playlist(this.uri, this.name, this._tracks, this._lastModified);

  factory Playlist.fromMap(Map<String, dynamic> jsonMap) {
    return Playlist(
        jsonMap[_JsonKeywords.uri] as String,
        jsonMap[_JsonKeywords.name],
        Model.convert(jsonMap[_JsonKeywords.tracks])?.cast<Track>() ??
            <Track>[],
        jsonMap[_JsonKeywords.lastModified]);
  }

  /// Playlist's tracks
  List<Track> get tracks => _tracks;

  /// Last playlist's modification time in milliseconds since Unix epoch or Null if unknown
  int? get lastModified => _lastModified;

  /// Add [track] to playlist
  void addTrack(Track track) {
    _tracks.add(track);
  }

  @override
  Map<String, dynamic> toMap() {
    return _finish({
      _JsonKeywords.uri: uri,
      _JsonKeywords.name: name,
      _JsonKeywords.tracks: tracks.isNotEmpty
          ? tracks.map((track) => track.toMap()).toList()
          : null,
      _JsonKeywords.lastModified: lastModified
    });
  }

  @override
  bool operator ==(Object other) =>
      other is Playlist &&
      other.runtimeType == runtimeType &&
      other.uri == uri &&
      other.name == name &&
      _eq(other._tracks, _tracks) &&
      other._lastModified == _lastModified;

  @override
  int get hashCode => Object.hash(uri, name, _tracks, _lastModified);
}

/// Result returned by a search.
class SearchResult extends Model {
  /// Search result URI
  final String? uri;

  /// Matching tracks
  final List<Track> tracks;

  /// Matching artists
  final List<Artist> artists;

  /// Matching albums
  final List<Album> albums;

  SearchResult(this.uri, this.tracks, this.artists, this.albums);

  factory SearchResult.fromMap(Map<String, dynamic> jsonMap) {
    return SearchResult(
        jsonMap[_JsonKeywords.uri] as String,
        Model.convert(jsonMap[_JsonKeywords.tracks])?.cast<Track>() ??
            <Track>[],
        Model.convert(jsonMap[_JsonKeywords.artists])?.cast<Artist>() ??
            <Artist>[],
        Model.convert(jsonMap[_JsonKeywords.albums])?.cast<Album>() ??
            <Album>[]);
  }

  @override
  Map<String, dynamic> toMap() {
    return _finish({
      _JsonKeywords.uri: uri,
      _JsonKeywords.tracks: tracks.isNotEmpty
          ? tracks.map((track) => track.toMap()).toList()
          : null,
      _JsonKeywords.artists: artists.isNotEmpty
          ? artists.map((artist) => artist.toMap()).toList()
          : null,
      _JsonKeywords.albums: albums.isNotEmpty
          ? albums.map((album) => album.toMap()).toList()
          : null
    });
  }

  @override
  bool operator ==(Object other) =>
      other is SearchResult &&
      other.runtimeType == runtimeType &&
      other.uri == uri &&
      _eq(other.tracks, tracks) &&
      _eq(other.artists, artists) &&
      _eq(other.albums, albums);

  @override
  int get hashCode => Object.hash(uri, tracks, artists, albums);
}

/// Volume
class Volume extends Model {
  /// Volume level
  int volume;

  Volume(this.volume);

  factory Volume.fromMap(Map<String, dynamic> jsonMap) {
    return Volume(jsonMap[_JsonKeywords.volume]);
  }

  @override
  Map<String, dynamic> toMap() {
    return _finish({_JsonKeywords.volume: volume});
  }

  @override
  bool operator ==(Object other) =>
      other is Volume &&
      other.runtimeType == runtimeType &&
      other.volume == volume;

  @override
  int get hashCode => volume.hashCode;
}

/// Represents the current state of playback.
class PlaybackState extends Model {
  static const String paused = 'paused';
  static const String playing = 'playing';
  static const String stopped = 'stopped';

  String oldState;
  String newState;

  PlaybackState(this.oldState, this.newState);

  factory PlaybackState.fromMap(Map<String, dynamic> jsonMap) {
    return PlaybackState(
        jsonMap[_JsonKeywords.oldState], jsonMap[_JsonKeywords.newState]);
  }

  @override
  Map<String, dynamic> toMap() {
    return _finish(
        {_JsonKeywords.oldState: oldState, _JsonKeywords.newState: newState});
  }

  @override
  bool operator ==(Object other) =>
      other is PlaybackState &&
      other.runtimeType == runtimeType &&
      other.oldState == oldState &&
      other.newState == newState;

  @override
  int get hashCode => Object.hash(oldState, newState);
}
