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

/// Client API for mopidy servers.
///
/// ```
/// import 'package:mopidy_client/mopidy_client.dart';
///
/// main() async {
///   Mopidy mp = Mopidy(backoffDelayMin: 500, backoffDelayMax: 6000);
///
///   mp.addVolumeChangedListener((int volume) {
///     print("Volume: $volume");
///   });
///
///   mp.addTrackPlaybackListener((TlTrackState state, TlTrack tlt, int? timePosition) {
///     print("Track playing:");
///     print(state);
///     print(tlt);
///     print(timePosition);
///   });
///
///   mp.addStreamTitleChangedListener((String title) {
///     print("Stream title: $title");
///   });
///
///   mp.addPlaybackStateChangedListener((PlaybackState state) {
///     print("PlaybackState: $state");
///   });
///
///   bool success = await mp.connect('ws://localhost:6680/mopidy/ws');
///   if (success) {
///     PlaybackState playbackState = await mp.playback.getState();
///     TlTrack? tltrack = await mp.playback.getCurrentTlTrack();
///     if (tltrack != null) {
///        print(tltrack);
///     }
///   }
///
///   await mp.connect(webSocketUrl: 'ws://localhost:6680/mopidy/ws');
/// ```

library mopidy_client;

import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert' show json;
import 'package:recase/recase.dart';
import 'package:eventify/eventify.dart';
import 'package:logger/logger.dart';
export 'package:eventify/eventify.dart' show Event;
import 'package:rxdart/rxdart.dart';

import 'src/error.dart';
export 'src/error.dart' show MopidyException, ServerException, ConnectionException;

import 'src/model.dart';
export 'src/model.dart' show Artist, Album, Image, Track, TlTrack, Playlist, Ref, SearchResult, Volume, PlaybackState;

import 'src/eventmanager.dart';
export 'src/eventmanager.dart' show EventManager, TrackState, TrackPlaybackInfo, ClientState, ClientStateInfo;

part 'src/mopidy.dart';
part 'src/playback_controller.dart';
part 'src/history_controller.dart';
part 'src/library_controller.dart';
part 'src/mixer_controller.dart';
part 'src/playlists_controller.dart';
part 'src/tracklist_controller.dart';

// Alias which may be used to avoid conflicts with Image from flutter.
typedef MImage = Image;
