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

/// Manages the list of tracks to be played. Tracks can be added to the list, removed,
/// reordered and filtered by certain criteria.
class TracklistController {
  final Mopidy _mopidy;

  TracklistController._(this._mopidy);

  /// Adds tracks to the tracklist.
  ///
  /// [uris] are looked up in the library
  /// and the resulting tracks are added to the tracklist.
  ///
  /// If [atPosition] is given, the tracks are inserted at the given position in
  /// the tracklist. If [atPosition] is not given, the tracks are appended to
  /// the end of the tracklist.
  ///
  /// Triggers the listeners [Mopidy.addTracklistChangedListener] and [Mopidy.tracklistChanged$].
  Future<List<TlTrack>> add(List<String> uris, int? atPosition) async {
    Map<String, dynamic> data = {
      "method": "core.tracklist.add",
      "params": {"at_position": atPosition, "uris": uris}..removeWhere((key, value) => value == null)
    };

    return (await _mopidy._send(data)).cast<TlTrack>();
  }

  /// Removes the tracks matching [criteria] from the tracklist. [criteria] can
  /// be constructed with the help of [FilterCriteria.toMap].
  ///
  /// Triggers the listeners [Mopidy.addTracklistChangedListener] and [Mopidy.tracklistChanged$].
  ///
  Future<List<TlTrack>> remove(Map<String, List<dynamic>> criteria) async {
    Map<String, dynamic> data = {
      "method": "core.tracklist.remove",
      "params": {
        // (dict, of (string, list) pairs) – one or more rules to match by
        "criteria": criteria
      }
    };
    return (await _mopidy._send(data)).cast<TlTrack>();
  }

  /// Clears the tracklist.
  ///
  /// Triggers the listeners [Mopidy.addTracklistChangedListener] and [Mopidy.tracklistChanged$].
  Future<void> clear() {
    return _mopidy._send({"method": "core.tracklist.clear"});
  }

  /// Moves the tracks in the slice from [start] to [end] to [toPosition].
  ///
  /// Triggers the listeners [Mopidy.addTracklistChangedListener] and [Mopidy.tracklistChanged$].
  Future<void> move(int start, int end, int toPosition) {
    Map<String, dynamic> data = {
      "method": "core.tracklist.move",
      "params": {
        // position of first track to move
        "start": start,
        // position after last track to move
        "end": end,
        // new position for the tracks
        "to_position": toPosition
      }
    };
    return _mopidy._send(data);
  }

  /// Shuffles the entire tracklist.
  ///
  /// If [start] and [end] are given
  /// only shuffles the slice form [start] to [end].
  ///
  /// Triggers the listeners [Mopidy.addTracklistChangedListener] and [Mopidy.tracklistChanged$].
  Future<void> shuffle(int? start, int? end) {
    Map<String, dynamic> data = {
      "method": "core.tracklist.shuffle",
      "params": {
        // position of first track to move
        "start": start,
        // position after last track to move
        "end": end
      }
    };
    return _mopidy._send(data);
  }

  /// Gets tracklist as list of `mopidy.models.TlTrack`
  Future<List<TlTrack>> getTlTracks() async {
    return (await _mopidy._send({"method": "core.tracklist.get_tl_tracks"}) as List).cast<TlTrack>();
  }

  /// The position of the given track in the tracklist.
  ///
  /// If neither [tlTrack] or [tlid] is given, returns the index of the
  /// currently playing track.
  Future<int?> index(TlTrack? tlTrack, int? tlid) async {
    Map<String, dynamic> data = {
      "method": "core.tracklist.index",
      "params": {
        // The track to find the index of
        "tl_track": tlTrack,
        // TLID of the track to find the index of
        "tlid": tlid
      }
    };
    return await _mopidy._send(data);
  }

  /// Gets the tracklist version.
  ///
  /// Integer which is increased every time the tracklist is changed.
  /// Is not reset before Mopidy is restarted.
  Future<int> getVersion() async {
    return await _mopidy._send({"method": "core.tracklist.get_version"});
  }

  /// Gets length of the tracklist
  Future<int> getLength() async {
    return await _mopidy._send({"method": "core.tracklist.get_length"});
  }

  /// Gets tracklist.
  Future<List<Track>> getTracks() async {
    return (await _mopidy._send({"method": "core.tracklist.get_tracks"})).cast<Track>();
  }

  /// Returns a slice of the tracklist, limited by the given [start] and [end]
  /// positions.
  Future<List<TlTrack>> slice(int start, int end) async {
    Map<String, dynamic> data = {
      "method": "core.tracklist.slice",
      "params": {
        // position of first track to include in slice
        "start": start,
        // position after last track to include in slice
        "end": end,
      }
    };
    return (await _mopidy._send(data)).cast<TlTrack>();
  }

  /// Filters the tracklist by the given criteria.
  ///
  /// Each rule in the [criteria] consists of a model field and a list of values to compare it against.
  /// If the model field matches any of the values, it is returned.
  /// ```
  /// List<TlTrack> tracks =
  ///   await this.filter(FilterCriteria().name(['Name of Track', 'Another Name']));
  /// ```
  ///
  /// Only tracks that match all the given criteria are returned.
  Future<List<TlTrack>> filter(FilterCriteria criteria) async {
    Map<String, dynamic> data = {
      "method": "core.tracklist.filter",
      "params": {
        // (dict, of (string, list) pairs) – one or more rules to match by
        "criteria": criteria.toMap()
      }
    };
    return (await _mopidy._send(data)).cast<TlTrack>();
  }

  // // ----------------- FUTURE STATE -----------------

  /// Returns the TLID of the track that will be played after the current track.
  ///
  /// Not necessarily the same TLID as returned by [getNextTlid].
  Future<int?> getEotTlid() async {
    return await _mopidy._send({"method": "core.tracklist.get_eot_tlid"});
  }

  /// return the tlid of the track that will be played if calling [PlaybackController.next]`.
  ///
  /// For normal playback this is the next track in the tracklist. If repeat is enabled the next
  /// track can loop around the tracklist. When random is enabled this should be a random track,
  /// all tracks should be played once before the tracklist repeats.
  Future<int?> getNextTlid() async {
    return await _mopidy._send({"method": "core.tracklist.get_next_tlid"});
  }

  /// Returns the TLID of the track that will be played if calling
  /// [PlaybackController.previous].
  ///
  /// For normal playback this is the previous track in the tracklist. If random and/or
  /// consume is enabled it should return the current track instead.
  Future<int?> getPreviousTlid() async {
    return await _mopidy._send({"method": "core.tracklist.get_previous_tlid"});
  }

  /// The track that will be played after the given track.
  ///
  /// Not necessarily the same track as [nextTrack].
  Future<TlTrack?> eotTrack(TlTrack? tlTrack) async {
    Map<String, dynamic> data = {
      "method": "core.tracklist.eot_track",
      "params": {
        // The reference track
        "tl_track": tlTrack
      }
    };
    return await _mopidy._send(data) as TlTrack;
  }

  // // ----------------- OPTIONS -----------------

  ///
  /// Returns the current consume mode.
  ///
  /// true - Tracks are removed from the tracklist when they have been played.
  /// false - Tracks are not removed from the tracklist.
  ///
  Future<bool> getConsume() async {
    return await _mopidy._send({"method": "core.tracklist.get_consume"});
  }

  /// Sets consume mode.
  ///
  /// true - Tracks are removed from the tracklist when they have been played.
  /// false - Tracks are not removed from the tracklist.
  ///
  Future<void> setConsume(bool value) {
    return _mopidy._send({
      "method": "core.tracklist.set_consume",
      "params": {"value": value}
    });
  }

  /// Returns the current random mode.
  Future<bool> getRandom() async {
    return await _mopidy._send({"method": "core.tracklist.get_random"});
  }

  /// Sets random mode.
  ///
  /// true - Tracks are selected at random from the tracklist.
  /// false - Tracks are played in the order of the tracklist.
  Future<void> setRandom(bool value) {
    return _mopidy._send({
      "method": "core.tracklist.set_random",
      "params": {"value": value}
    });
  }

  /// Returns the current repeat mode.
  Future<bool> getRepeat() async {
    return await _mopidy._send({"method": "core.tracklist.get_repeat"});
  }

  /// Set repeat mode.
  ///
  /// To repeat a single track, set both `repeat` and `single`.
  Future<void> setRepeat(bool value) {
    return _mopidy._send({
      "method": "core.tracklist.set_repeat",
      "params": {"value": value}
    });
  }

  /// Returns is single mode is active.
  Future<bool> getSingle() async {
    return await _mopidy._send({"method": "core.tracklist.get_single"});
  }

  /// Sets single mode.
  ///
  /// true - Playback is stopped after current song, unless in repeat mode.
  /// false - Playback continues after current song.
  Future<void> setSingle(bool value) {
    return _mopidy._send({
      "method": "core.tracklist.set_single",
      "params": {"value": value}
    });
  }
}

class FilterCriteria {
  final Map<String, List<dynamic>> _criteria = <String, List<dynamic>>{};

  FilterCriteria tlid(List<int> values) {
    _criteria['tlid'] = values;
    return this;
  }

  FilterCriteria uri(List<String> values) {
    _criteria['uri'] = values;
    return this;
  }

  FilterCriteria name(List<String> values) {
    _criteria['name'] = values;
    return this;
  }

  FilterCriteria genre(List<String> values) {
    _criteria['genre'] = values;
    return this;
  }

  FilterCriteria date(List<String> values) {
    _criteria['date'] = values;
    return this;
  }

  FilterCriteria comment(List<String> values) {
    _criteria['comment'] = values;
    return this;
  }

  FilterCriteria musicbrainzId(List<String> values) {
    _criteria['musicbrainz_id'] = values;
    return this;
  }

  Map<String, List<dynamic>> toMap() {
    return _criteria;
  }
}
