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

/// Controls the playback of tracks from the tracklist. A track can be selected,
/// playback can be started, stopped paused and resumed. The time position
/// within the active track can be set.
///
/// In addtion, information about the currently active track can be queried.
class PlaybackController {
  final Mopidy _mopidy;

  PlaybackController._(this._mopidy);

  /// Plays the given track, or if [tlid] is `null`,
  /// play the currently active track.
  ///
  /// Note that the track *must* already be in the tracklist.
  Future<void> play(int? tlid) {
    Map<String, dynamic> data = {
      "method": "core.playback.play",
      "params": {"tlid": tlid}..removeWhere((key, value) => value == null)
    };
    return _mopidy._send(data);
  }

  /// Changes to the next track.
  ///
  /// The current playback state will be kept. If it was playing, playing will
  /// continue. If it was paused, it will still be paused, etc.
  Future<void> next() {
    return _mopidy._send({"method": "core.playback.next"});
  }

  /// Changes to the previous track.
  ///
  /// The current playback state will be kept. If it was playing, playing will
  /// continue. If it was paused, it will still be paused, etc.
  Future<void> previous() {
    return _mopidy._send({"method": "core.playback.previous"});
  }

  /// Stops playing.
  Future<void> stop() {
    return _mopidy._send({"method": "core.playback.stop"});
  }

  /// Pauses playback.
  Future<void> pause() {
    return _mopidy._send({"method": "core.playback.pause"});
  }

  /// If paused, resume playing the current track.
  Future<void> resume() {
    return _mopidy._send({"method": "core.playback.resume"});
  }

  /// Seeks to [timePosition] given in milliseconds.
  Future<bool> seek(int timePosition) async {
    var result = await _mopidy._send({
      "method": "core.playback.seek",
      "params": {"time_position": timePosition}
    });
    return result ?? false;
  }

// ----------------- CURRENT TRACK -----------------

  /// Gets the currently playing or selected track.
  Future<TlTrack?> getCurrentTlTrack() async {
    return await _mopidy._send({"method": "core.playback.get_current_tl_track"});
  }

  /// Gets the currently playing or selected track.
  Future<Track?> getCurrentTrack() async {
    return await _mopidy._send({"method": "core.playback.get_current_track"});
  }

  /// Gets time position in milliseconds.
  Future<int?> getTimePosition() async {
    return await _mopidy._send({"method": "core.playback.get_time_position"});
  }

  /// Gets the current stream title or `null`.
  Future<String?> getStreamTitle() async {
    return await _mopidy._send({"method": "core.playback.get_stream_title"});
  }

// ----------------- PLAYBACK STATES -----------------

  /// Gets The playback state.
  Future<String> getState() async {
    return await _mopidy._send({"method": "core.playback.get_state"});
  }

  /// Sets the playback [state]. See:
  /// https://docs.mopidy.com/en/latest/api/core/#mopidy.core.PlaybackController.set_state
  /// for possible states and transitions
  Future<void> setState(String state) {
    return _mopidy._send({
      "method": "core.playback.set_state",
      "params": {"new_state": state}
    });
  }
}
