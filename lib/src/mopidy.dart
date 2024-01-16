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
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THES
// SOFTWARE.

part of '../mopidy_client.dart';

/// Mopidy client API main class.
class Mopidy extends EventManager {
  /// Default URL used when creating new WebSocket objects.
  ///
  /// In a browser environment, it defaults to
  /// ws://${document.location.host}/mopidy/ws. If the current page is served
  /// over HTTPS, it defaults to using wss:// instead of ws://.
  ///
  /// In a non-browser environment, where document.location isn't available, it
  /// defaults to ws://localhost/mopidy/ws.
  static const defaultWebSocketUrl = 'ws://localhost:6680/mopidy/ws';

  String _webSocketUrl = defaultWebSocketUrl;

  /// Logger to be used for logging. If [logger] is null,
  /// a default console logger is used.
  Logger? logger;

  /// The minimum number of milliseconds to wait after a connection error before
  /// we try to reconnect. For every failed attempt, the backoff delay is doubled
  /// until it reaches backoffDelayMax. Defaults to 1000.
  int backoffDelayMin;

  /// The maximum number of milliseconds to wait after a connection error before
  /// we try to reconnect. Defaults to 64000.
  int backoffDelayMax;

  late int _currentDelay;

  int _lastUsedRequestId = -1;
  Map<int, Completer<dynamic>> _pendingRequests = {};
  WebSocketChannel? _webSocketChannel;
  StreamSubscription? _webSocketChannelSubscription;

  late PlaybackController _playback;
  late MixerController _mixer;
  late TracklistController _tracklist;
  late LibraryController _library;
  late HistoryController _history;
  late PlaylistsController _playlists;

  final _clientState$ = PublishSubject<ClientStateInfo>();
  final _optionsChanged$ = PublishSubject<void>();
  final _playlistsLoaded$ = PublishSubject<void>();
  final _playlistChanged$ = PublishSubject<Playlist>();
  final _playlistDeleted$ = PublishSubject<Uri>();
  final _tracklistChanged$ = PublishSubject<void>();
  final _trackPlayback$ = PublishSubject<TrackPlaybackInfo>();
  final _playbackStateChanged$ = PublishSubject<PlaybackState>();
  final _volumeChanged$ = PublishSubject<int>();
  final _muteChanged$ = PublishSubject<bool>();
  final _seeked$ = PublishSubject<int>();
  final _streamTitleChanged$ = PublishSubject<String>();

  Stream<ClientStateInfo> get clientState$ => _clientState$.stream;

  Stream<void> get optionsChanged$ => _optionsChanged$.stream;

  Stream<void> get playlistsLoaded$ => _playlistsLoaded$.stream;

  Stream<Playlist> get playlistChanged$ => _playlistChanged$.stream;

  Stream<Uri> get playlistDeleted$ => _playlistDeleted$.stream;

  Stream<void> get tracklistChanged$ => _tracklistChanged$.stream;

  Stream<TrackPlaybackInfo> get trackPlayback$ => _trackPlayback$.stream;

  Stream<PlaybackState> get playbackStateChanged$ => _playbackStateChanged$.stream;

  Stream<int> get volumeChanged$ => _volumeChanged$.stream;

  Stream<bool> get muteChanged$ => _muteChanged$.stream;

  Stream<int> get seeked$ => _seeked$.stream;

  Stream<String> get streamTitleChanged$ => _streamTitleChanged$.stream;

  get url => _webSocketUrl;

  bool _stopped = false;

  /// Creates a new Modiy client API object.
  Mopidy({this.logger, this.backoffDelayMin = 1000, this.backoffDelayMax = 64000}) {
    logger = logger ?? Logger();

    _playback = PlaybackController._(this);
    _mixer = MixerController._(this);
    _tracklist = TracklistController._(this);
    _library = LibraryController._(this);
    _history = HistoryController._(this);
    _playlists = PlaylistsController._(this);

    _currentDelay = backoffDelayMin;
    _webSocketChannel = null;
    _webSocketChannelSubscription = null;

    // Register basic set of event handlers
    emitter.on("websocket:close", null, _cleanup);
    emitter.on("websocket:incomingMessage", null, _handleMessage);
    emitter.on("websocket:open", null, _online);
    emitter.on("state:offline", null, _reconnect);

    addClientStateListener((clientStateInfo) {
      _clientState$.add(clientStateInfo);
    });

    addOptionsChangedListener(() {
      _optionsChanged$.add(null);
    });

    addPlaylistsLoadedListener(() {
      _playlistsLoaded$.add(null);
    });

    addPlaylistChangedListener((playlist) {
      _playlistChanged$.add(playlist);
    });

    addPlaylistDeletedListener((uri) {
      _playlistDeleted$.add(uri);
    });

    addTracklistChangedListener(() {
      _tracklistChanged$.add(null);
    });

    addTrackPlaybackListener((trackPlaybackInfo) {
      _trackPlayback$.add(trackPlaybackInfo);
    });

    addPlaybackStateChangedListener((state) {
      _playbackStateChanged$.add(state);
    });

    addVolumeChangedListener((volume) {
      _volumeChanged$.add(volume);
    });

    addMuteChangedListener((muted) {
      _muteChanged$.add(muted);
    });

    addSeekedListener((timePosition) {
      _seeked$.add(timePosition);
    });

    addStreamTitleChangedListener((title) {
      _streamTitleChanged$.add(title);
    });
  }

  /// Return the [PlaybackController] interface.
  PlaybackController get playback {
    return _playback;
  }

  /// Controls volume and mute state.
  MixerController get mixer {
    return _mixer;
  }

  /// Manages everything related to the list of tracks we will play. See
  /// [TracklistController]. Undefined before Mopidy connects.
  TracklistController get tracklist {
    return _tracklist;
  }

  /// Methods to browse and search media libraries.
  /// See [LibraryController].
  LibraryController get library {
    return _library;
  }

  /// Management of playlists.
  /// See [PlaylistsController].
  PlaylistsController get playlists {
    return _playlists;
  }

  /// Access to the history of played tracks. See [HistoryController].
  HistoryController get history {
    return _history;
  }

  Future<bool> _connect() async {
    if (_webSocketChannel != null) {
      _webSocketChannelSubscription?.cancel();
    }

    final wsUrl = Uri.parse(_webSocketUrl);
    var channel = WebSocketChannel.connect(wsUrl);
    await channel.ready;
    _webSocketChannelSubscription = channel.stream.listen((message) {
      _event("websocket:incomingMessage", message);
    }, onError: (err) => _event("websocket:error", err), onDone: () => _event("websocket:close"), cancelOnError: false);
    _webSocketChannel = channel;
    _event("websocket:open");
    return Future.value(true);
  }

  /// Connects to the Mopidy server at [webSocketUrl], e.g. `ws://localhost:6680/mopidy/ws`.
  /// Optional parameter [maxRetries] specifies maximum number of retry attempts.
  Future<bool> connect({webSocketUrl, int? maxRetries}) async {
    _webSocketUrl = webSocketUrl ?? _webSocketUrl ?? defaultWebSocketUrl;

    bool connected = false;
    _stopped = false;
    while (!connected) {
      try {
        if (_stopped) {
          break;
        }
        connected = await _connect();
      } catch (e) {
        logger!.log(Level.error, e.toString());
        if (maxRetries != null) {
          maxRetries--;
          if (maxRetries < 0) {
            break;
          }
        }
        _event("state", {"reconnectionPending": _currentDelay});
        _event("reconnectionPending", _currentDelay);

        await Future.delayed(Duration(milliseconds: _currentDelay), () {});

        _event("state", "reconnecting");
        _event("reconnecting");
        _currentDelay *= 2;
        if (_currentDelay > backoffDelayMax) {
          _currentDelay = backoffDelayMax;
        }
      }
    }

    return Future.value(connected);
  }

  /// Disconnects from Mopidy server.
  void disconnect() {
    _stopped = true;
    _event("state", "state:offline");
    _event("state:offline");
    _webSocketChannel?.sink.close();
    _currentDelay = backoffDelayMin;
  }

  void _cleanup(Event ev, Object? obj) {
    // detach pending requests queue to
    // avoid potential concurrency issues
    // with incoming responses.
    Map<int, Completer<dynamic>> pendingRequests = _pendingRequests;
    _pendingRequests = {};

    pendingRequests.forEach((key, value) {
      Completer<dynamic>? cmp = pendingRequests[key];

      if (!cmp!.isCompleted) {
        cmp.completeError(
            MopidyException.connectionException(ConnectionException.errorSocketClosed, "WebSocket closed"));
      }
    });

    _event("state", "state:offline");
    _event("state:offline");
  }

  void _reconnect([Event? ev, Object? obj]) {
    if (!_stopped) {
      connect();
    }
  }

  /// Dispose this object and all of its associated resources. After invoking this method,
  /// this object must not be used anymore.
  void dispose() {
    // remove all listeners
    emitter.clear();

    _clientState$.close();
    _optionsChanged$.close();
    _playlistsLoaded$.close();
    _playlistChanged$.close();
    _playlistDeleted$.close();
    _tracklistChanged$.close();
    _trackPlayback$.close();
    _playbackStateChanged$.close();
    _muteChanged$.close();
    _volumeChanged$.close();
    _seeked$.close();
    _streamTitleChanged$.close();

    _webSocketChannel?.sink.close();
  }

  Future<dynamic> _send(Map<String, dynamic> message) {
    return Future<dynamic>(() {
      int id = _nextRequestId();
      Map<String, dynamic> jsonRpcMessage = {
        ...message,
        "jsonrpc": "2.0",
        "id": id,
      };
      _pendingRequests[id] = Completer();
      _webSocketChannel!.sink.add(json.encode(jsonRpcMessage));
      _event("websocket:outgoingMessage", jsonRpcMessage);
      return _pendingRequests[id]!.future;
    });
  }

  int _nextRequestId() {
    _lastUsedRequestId++;
    return _lastUsedRequestId;
  }

  void _handleMessage(Event ev, Object? obj) {
    try {
      Map<String, dynamic> data = Map<String, dynamic>.from(json.decode(ev.eventData.toString()));
      if (data.containsKey('id')) {
        _handleResponse(data);
      } else if (data.containsKey('event')) {
        _handleEvent(data);
      } else {
        logger!.e("Unknown message type received. Message was: ${ev.eventData.toString()}");
      }
    } on FormatException {
      logger!.e("WebSocket message parsing failed. Message was: ${ev.eventData.toString()}");
    }
  }

  void _handleResponse(Map<String, dynamic> responseMessage) {
    final id = responseMessage['id'];
    if (id == null || !_pendingRequests.containsKey(id)) {
      logger!.e("Unexpected response $responseMessage");
      return;
    }

    Completer<dynamic> cmp = _pendingRequests[id]!;

    _pendingRequests.remove(id);

    if (cmp.isCompleted) {
      return;
    }

    if (responseMessage.containsKey('result')) {
      try {
        cmp.complete(Model.convert(responseMessage['result']));
      } catch (e, s) {
        cmp.completeError(MopidyException.serverException(ServerException.errorServerResponse, "$e $s", []));
      }
    } else if (responseMessage.containsKey('error')) {
      cmp.completeError(MopidyException.serverException(
          ServerException.errorServerResponse, "Server response error: {}", [responseMessage['error']]));
    } else {
      cmp.completeError(MopidyException.serverException(ServerException.errorUnexpectedResponse,
          'Response without "result" or "error" received. Message was: {}', responseMessage));
    }
  }

  void _handleEvent(Map<String, dynamic> eventMessage) {
    try {
      Map<String, dynamic> data = {...eventMessage};
      data.remove('event');
      String eventName = "event:${eventMessage['event'].toString().camelCase}";
      _event('event', {'eventName': eventName, 'data': data});
      _event(eventName, data);
    } catch (e, s) {
      logger!.e('Error receiving event message', error: e, stackTrace: s);
    }
  }

  void _online(Event ev, Object? obj) {
    _currentDelay = backoffDelayMin;
    _event("state", "state:online");
    _event("state:online");
  }

  void _event(name, [data]) {
    emitter.emit(name, null, data);
  }

  /// Returns a description of the Mopidy server API.
  Future<Map<String, dynamic>> describe() async {
    return await _send({"method": "core.describe"});
  }

  /// Returns the list of URI schemes we can handle.
  Future<List<String>> getUriSchemes() async {
    return (await _send({"method": "core.get_uri_schemes"}))?.cast<String>();
  }

  /// Returns the version of the Mopidy core API.
  Future<String> getVersion() async {
    return await _send({"method": "core.get_version"});
  }
}
