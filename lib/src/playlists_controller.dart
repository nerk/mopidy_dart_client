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

class PlaylistsController {
  final Mopidy _mopidy;

  PlaylistsController._(this._mopidy);

  ///
  /// Get the list of URI schemes that support playlists.
  ///
  Future<List<String>> getUriSchemes() async {
    return (await _mopidy._send({"method": "core.playlists.get_uri_schemes"}))?.cast<String>();
  }

  // ----------------- FETCHING -----------------

  ///
  /// Get a list of the currently available playlists.
  ///
  /// Returns a list of Ref objects referring to the playlists. In other words,
  /// no information about the playlists’ content is given.
  ///
  Future<List<Ref>> asList() async {
    return (await _mopidy._send({"method": "core.playlists.as_list"})).cast<Ref>();
  }

  ///
  /// Get the items in a playlist specified by [uri].
  ///
  /// Returns a list of Ref objects referring to the playlist’s items.
  ///
  /// If a playlist with the given uri doesn’t exist, an empty list is returned.
  ///
  Future<List<Ref>> getItems(String uri) async {
    return (await _mopidy._send({
      "method": "core.playlists.get_items",
      "params": {"uri": uri}
    }))
        ?.cast<Ref>();
  }

  ///
  /// Lookup playlist with given [uri] in both the set of playlists and in any other
  /// playlist sources. Returns `null` if not found.
  ///
  Future<Playlist?> lookup(String uri) async {
    return (await _mopidy._send({
      "method": "core.playlists.lookup",
      "params": {"uri": uri}
    })) as Playlist;
  }

  ///
  /// Refresh the playlists in playlists.
  ///
  /// If [uriScheme] is `null`, all backends are asked to refresh. If [uriScheme] is an URI scheme
  /// handled by a backend, only that backend is asked to refresh. If [uriScheme] doesn’t
  /// match any current backend, nothing happens.
  ///
  Future<void> refresh(String? uriScheme) {
    Map<String, dynamic> data = {
      "method": "core.playlists.refresh",
      "params": {"uri_scheme": uriScheme}..removeWhere((key, value) => value == null)
    };
    return _mopidy._send(data);
  }

  // ----------------- MANIPULATING -----------------

  ///
  /// Create a new playlist called [name].
  ///
  /// If [uriScheme] matches an URI scheme handled by a current backend, that backend is
  /// asked to create the playlist. If [uriScheme] is `null` or doesn’t match a current backend,
  /// the first backend is asked to create the playlist.
  ///
  /// All new playlists must be created by calling this method, and not by creating new
  /// instances of [Playlist].
  ///
  Future<Playlist> create(
      //
      /// Name of the new playlist.
      ///
      String name,

      ///
      /// Use the backend matching the URI scheme.
      ///
      String? uriScheme) async {
    return (await _mopidy._send({
      "method": "core.playlists.create",
      "params": {"name": name, "uri_scheme": uriScheme}..removeWhere((key, value) => value == null)
    })) as Playlist;
  }

  /// Saves the playlist.
  ///
  /// For a [playlist] to be saveable, it must have the uri attribute set. You must not set
  /// the uri atribute yourself, but use playlist objects returned by create() or
  /// retrieved from playlists, which will always give you saveable playlists.
  ///
  /// The method returns the saved playlist. The return playlist may differ from the saved
  /// playlist. E.g. if the playlist name was changed, the returned playlist may have a
  /// different URI. The caller of this method must throw away the playlist sent to
  /// this method, and use the returned playlist instead.
  ///
  /// If the playlist’s URI isn’t set or doesn’t match the URI scheme of a current backend,
  /// nothing is done and None is returned.
  Future<Playlist?> save(
      //
      /// The playlist
      ///
      Playlist playlist) async {
    return (await _mopidy._send({
      "method": "core.playlists.save",
      "params": {"playlist": playlist.toMap()}
    })) as Playlist;
  }

  /// Delete playlist identified by [uri].
  ///
  /// If [uri] doesn’t match the URI schemes handled by the current backends, nothing happens.
  ///
  /// Returns `true` if deleted, `false` otherwise.
  Future<bool> delete(

      ///
      /// URI of the playlist to delete
      ///
      String uri) async {
    return await _mopidy._send({
      "method": "core.playlists.delete",
      "params": {"uri": uri}
    }) as bool;
  }
}
