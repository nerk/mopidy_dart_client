// MIT License

// Copyright (c) 2023 Thomas Kern

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

import 'package:eventify/eventify.dart';
import 'model.dart';

/// The client's current connection state with the server,
enum ClientState {
  online,
  offline,
  reconnecting,
  reconnectionPending;
}

/// Information about the current connection state.
class ClientStateInfo {
  /// The current cconnection state.
  ClientState state;

  /// If reconnection is pending, the delay in milliseconds until the nect reconnection attempt is made.
  /// In all other cases, this is `0`.
  int currentDelay;

  ClientStateInfo(this.state, this.currentDelay);

  @override
  String toString() {
    return "$state:$currentDelay";
  }
}

/// The state of the current track.
enum TrackState {
  started,
  ended,
  paused,
  resumed;
}

class TrackPlaybackInfo {
  TrackState state;
  TlTrack tlTrack;
  int timePosition;

  TrackPlaybackInfo(this.state, this.tlTrack, this.timePosition);

  @override
  String toString() {
    return "$state:$tlTrack:$timePosition";
  }
}

// Handles subscriptions to events sent by the Mopidy server or the client API.
abstract class EventManager {
  final emitter = EventEmitter();

  /// Calls [listener] whenever the status of the client connection changes.
  EventCallback addClientStateListener(void Function(ClientStateInfo stateInfo) listener) {
    var clientState = {
      "state:online": ClientState.online,
      "state:offline": ClientState.offline,
      "reconnecting": ClientState.reconnecting,
      "reconnectionPending": ClientState.reconnectionPending
    };

    void callback(Event ev, Object? obj) {
      listener.call(ClientStateInfo(clientState[ev.eventName]!, ev.eventData != null ? ev.eventData as int : 0));
    }

    for (var key in clientState.keys) {
      emitter.on(key, null, callback);
    }
    return callback;
  }

  /// Calls [listener] whenever configuration options changed.
  EventCallback addOptionsChangedListener(void Function() listener) {
    return emitter.on("event:optionsChanged", null, (Event ev, Object? obj) {
      listener.call();
    }).callback;
  }

  /// Calls [listener] whenever the playlists where loaded.
  EventCallback addPlaylistsLoadedListener(void Function() listener) {
    return emitter.on("event:playlistsLoaded", null, (Event ev, Object? obj) {
      listener.call();
    }).callback;
  }

  /// Calls [listener] when the playlist changed.
  EventCallback addPlaylistChangedListener(void Function(Playlist) listener) {
    return emitter.on("event:playlistChanged", null, (Event ev, Object? obj) {
      Map<String, dynamic> data = ev.eventData as Map<String, dynamic>;
      var playlist = data['playlist'] as Map<String, dynamic>;
      listener.call(Playlist.fromMap(playlist));
    }).callback;
  }

  /// Calls [listener] whenever a playlist was deleted
  EventCallback addPlaylistDeletedListener(void Function(Uri uri) listener) {
    return emitter.on("event:playlistDeleted", null, (Event ev, Object? obj) {
      Map<String, dynamic> data = ev.eventData as Map<String, dynamic>;
      var uri = data['uri'] as String;
      listener.call(Uri.parse(uri));
    }).callback;
  }

  /// Calls [listener] whenever the tracklist changed.
  EventCallback addTracklistChangedListener(void Function() listener) {
    return emitter.on("event:tracklistChanged", null, (Event ev, Object? obj) {
      listener.call();
    }).callback;
  }

  /// Calls [listener] whenever playback of a track started, paused, resumed, or ends.
  EventCallback addTrackPlaybackListener(void Function(TrackPlaybackInfo playbackInfo) listener) {
    var trackState = {
      "event:trackPlaybackStarted": TrackState.started,
      "event:trackPlaybackPaused": TrackState.paused,
      "event:trackPlaybackResumed": TrackState.resumed,
      "event:trackPlaybackEnded": TrackState.ended
    };

    void callback(Event ev, Object? obj) {
      Map<String, dynamic> data = ev.eventData as Map<String, dynamic>;
      TlTrack tltrack = TlTrack.fromMap(data['tl_track']);
      var timePosition = data['time_position'];
      listener.call(TrackPlaybackInfo(trackState[ev.eventName]!, tltrack, timePosition != null ? timePosition as int : 0));
    }

    for (var key in trackState.keys) {
      emitter.on(key, null, callback);
    }
    return callback;
  }

  /// Calls [listener] whenever the time position within the currently active track
  /// changes by an unexpected amount, e.g. at seek to a new time position.
  ///
  /// [timePosition] passed to the listener function
  /// represents the new time position in milliseconds.
  EventCallback addSeekedListener(void Function(int timePosition) listener) {
    return emitter.on("event:seeked", null, (Event ev, Object? obj) {
      Map<String, dynamic> data = ev.eventData as Map<String, dynamic>;
      // the position that was seeked to in milliseconds
      var timePosition = data['time_position'] as int;
      listener.call(timePosition);
    }).callback;
  }

  /// Calls [listener] whenever the volume changed.
  ///
  /// [volume] represents the new volume.
  EventCallback addVolumeChangedListener(void Function(int volume) listener) {
    return emitter.on("event:volumeChanged", null, (Event ev, Object? obj) {
      Map<String, dynamic> data = ev.eventData as Map<String, dynamic>;
      var volume = data['volume'] as int;
      listener.call(volume);
    }).callback;
  }

  /// Calls [listener] whenever the mute state changed.
  ///
  /// [mute] is `true`, if audio has been muted,
  /// `false`otherwise.
  EventCallback addMuteChangedListener(void Function(bool mute) listener) {
    return emitter.on("event:muteChanged", null, (Event ev, Object? obj) {
      Map<String, dynamic> data = ev.eventData as Map<String, dynamic>;
      var mute = data['mute'] as bool;
      listener.call(mute);
    }).callback;
  }

  /// Calls [listener] whenever the currently playing stream title changes.
  EventCallback addStreamTitleChangedListener(void Function(String title) listener) {
    return emitter.on("event:streamTitleChanged", null, (Event ev, Object? obj) {
      Map<String, dynamic> data = ev.eventData as Map<String, dynamic>;
      var title = data['title'] as String;
      listener.call(title);
    }).callback;
  }

  /// Calls [listener] when the plaback state changed.
  EventCallback addPlaybackStateChangedListener(void Function(PlaybackState) listener) {
    return emitter.on("event:playbackStateChanged", null, (Event ev, Object? obj) {
      Map<String, dynamic> data = ev.eventData as Map<String, dynamic>;
      listener.call(PlaybackState.fromMap(data));
    }).callback;
  }

  /// Removes [eventCallback] from emitter. [eventCallback] is the value returned by the addXxxListener methods.
  void removeEventListener(EventCallback eventCallback) {
    // Since eventCallback is an internally created unique wrapper for the
    // passed listener functions, removeAllByCallback will always do the right thing and will not remove too many things.
    emitter.removeAllByCallback(eventCallback);
  }

  /// Registers an event callback for an event.
  /// [event] - String identifier of the event.
  /// [context] - additional arbitrary context object.
  /// [callback] - [EventCallback] to be registered.
  Listener on(String event, Object? context, EventCallback callback) {
    return emitter.on(event, context, callback);
  }

  /// Remove event listener from emitter.
  /// This will unsubscribe the caller from the emitter from any future events.
  /// Listener should be a valid instance.
  /// [listener] - [Listener] instance to be removed from the event subscription.
  void off(Listener? listener) {
    emitter.off(listener);
  }
}
