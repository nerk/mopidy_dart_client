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

part of '../mopidy_client.dart';

/// Browse music libraries, search for tracks, albums, and artists.
class LibraryController {
  final Mopidy _mopidy;

  LibraryController._(this._mopidy);

  /// Browse directories and tracks at the given uri.
  ///
  /// [uri] is a string representing some directory belonging to a backend.
  /// To get the intial root directories for backends pass `null` as [uri].
  ///
  /// Returns a list of [Ref] objects for the directories and
  /// tracks at the given uri.
  ///
  /// The [Ref] objects representing tracks keep the track's original URI. A
  /// matching pair of objects can look like this:
  ///
  ///   Track(uri='dummy:/foo.mp3', name='foo', artists=..., album=...)
  ///    Ref.track(uri='dummy:/foo.mp3', name='foo')
  ///
  /// The Ref objects representing directories have backend specific URIs.
  /// These are opaque values, so no one but the backend that created them
  /// should try and derive any meaning from them. The only valid exception to
  /// this is checking the scheme, as it is used to route browse requests to
  /// the correct backend.
  ///
  /// For example, the dummy library's /bar directory could be returned like
  /// this:
  ///
  ///    `Ref.directory(uri='dummy:directory:/bar', name='bar')`
  Future<List<Ref>> browse(String? uri) async {
    return (await _mopidy._send({
      "method": "core.library.browse",
      "params": {"uri": uri}
    }))
        .cast<Ref>();
  }

  /// Search libraries for tracks according to search criteria.
  ///
  /// [criteria] contains the matching criteria for tracks.
  /// `SearchCriteria` is used to construct a list of `field/value list` pairs
  /// to be used in the search.
  ///
  ///
  /// Returns results matching 'a' in any backend:
  /// ```
  /// search(SearchCriteria().any(['a']));
  /// ```
  ///
  /// Returns results matching artist 'xyz' in any backend:
  /// ```
  /// search(SearchCriteria().artist(['xyz']));
  /// ```
  ///
  /// Returns results matching 'a' and 'b' and artist 'xyz' in any backend:
  /// ```
  /// search(SearchCriteria().any(['a', 'b'].artist(['xyz']));
  /// ```
  ///
  /// Returns results matching artist 'xyz' and 'abc' in any backend:
  /// ```
  /// search(SearchCriteria().artist(['xyz', 'abc']));
  /// ```
  ///
  /// If [uris] is given, the search is limited to results from within the URI
  /// roots. For example passing `['file:']` will limit the search to the
  /// file backend.
  ///
  /// Returns results matching 'a' if within the given URI roots
  /// "file:///media/music" and "spotify:"
  /// ```
  /// search(SearchCriteria().any(['a']), ['file:///media/music', 'spotify:']);
  /// ```
  ///
  /// If [exact] is `true` (the default), values specified as search criteria must
  /// match exactly. If [exact] is `false`, a `*` can be appended to the *end* of
  /// a search value representing zero or more additional arbitrary characters to
  /// match.
  ///
  /// Returns results matching any artist starting with 'x' in any backend:
  /// ```
  /// search(SearchCriteria().artist(['x*']), null, false));
  /// ```

  Future<List<SearchResult>> search(

      /// One or more queries to search for.
      SearchCriteria criteria,

      /// Zero or more URI roots to limit the search to.
      List<String>? uris,

      /// If the search should use exact matching.
      bool? exact) async {
    Map<String, dynamic> data = {
      "method": "core.library.search",
      "params": {"query": criteria.toMap(), "uris": uris, "exact": exact}..removeWhere((key, value) => value == null)
    };
    return (await _mopidy._send(data)).cast<SearchResult>();
  }

  /// Lookup the given URIs.
  ///
  /// If the URI expands to multiple tracks, the returned list will contain them all.
  Future<Map<String, List<Track>>> lookup(

      /// A list of URI's.
      List<String> uris) async {
    Map<String, dynamic> data = {
      "method": "core.library.lookup",
      "params": {"uris": uris}
    };
    var r = await _mopidy._send(data);
    Map<String, List<Track>> result = <String, List<Track>>{};
    for (var key in r.keys) {
      result[key] = (r[key] as List).map((e) => e as Track).toList();
    }
    return result;
  }

  /// Refresh library. Limit to [uri] and below if not `null`.
  Future<void> refresh(String? uri) async {
    uri = uri ?? _mopidy.url;
    Map<String, dynamic> data = {
      "method": "core.library.refresh",
      "params": {"uri": uri}
    };
    return _mopidy._send(data);
  }

  /// Lookup the images for the given URIs
  ///
  /// Backends can use this to return image URIs for any URI they know about be
  /// it tracks, albums, playlists. The lookup result is a dictionary mapping
  /// the provided URIs to lists of images.
  ///
  /// Unknown URIs or URIs the corresponding backend couldn't find anything for
  /// will simply return an empty list for that URI.
  Future<Map<String, List<Image>>> getImages(List<String> uris) async {
    Map<String, dynamic> data = {
      "method": "core.library.get_images",
      "params": {"uris": uris}
    };
    var r = await _mopidy._send(data);
    Map<String, List<Image>> result = <String, List<Image>>{};
    for (var key in r.keys) {
      result[key] = (r[key] as List).map((e) => e as Image).toList();
    }
    return result;
  }
}

/// Constructs a search query.
class SearchCriteria {
  final Map<String, List<String>> _criteria = <String, List<String>>{};

  SearchCriteria uri(List<String> values) {
    _criteria['uri'] = values;
    return this;
  }

  SearchCriteria trackName(List<String> values) {
    _criteria['track_name'] = values;
    return this;
  }

  SearchCriteria album(List<String> values) {
    _criteria['album'] = values;
    return this;
  }

  SearchCriteria artist(List<String> values) {
    _criteria['artist'] = values;
    return this;
  }

  SearchCriteria albumArtist(List<String> values) {
    _criteria['albumartist'] = values;
    return this;
  }

  SearchCriteria composer(List<String> values) {
    _criteria['composer'] = values;
    return this;
  }

  SearchCriteria performer(List<String> values) {
    _criteria['performer'] = values;
    return this;
  }

  SearchCriteria trackNo(List<String> values) {
    _criteria['track_no'] = values;
    return this;
  }

  SearchCriteria genre(List<String> values) {
    _criteria['genre'] = values;
    return this;
  }

  SearchCriteria date(List<String> values) {
    _criteria['date'] = values;
    return this;
  }

  SearchCriteria comment(List<String> values) {
    _criteria['comment'] = values;
    return this;
  }

  SearchCriteria any(List<String> values) {
    _criteria['any'] = values;
    return this;
  }

  Map<String, dynamic> toMap() {
    return _criteria;
  }
}
