import 'package:mopidy_client/mopidy_client.dart';

main() async {
  Mopidy mp = Mopidy();

  mp.clientState$.listen((value) {
    print(" *** STATE: $value");
  });
  mp.optionsChanged$.listen((_) {
    print(" *** OPTIONS: ");
  });
  mp.playbackStateChanged$.listen((state) {
    print(" *** PLAYBACKSTATE: $state");
  });
  mp.volumeChanged$.listen((volume) {
    print(" *** VOLUME: $volume");
  });

  mp.on("state:online", null, (Event ev, Object? obj) async {
    print("ONLINE!");

    //print(await mp.describe());

    print("Stream title: ${await mp.playback.getStreamTitle()}");
    print("Volume ${await mp.mixer.getVolume()}");

    mp.mixer.setVolume(30);
    mp.mixer.setVolume(40);

    Track? tlt = await mp.playback.getCurrentTrack();
    print("Current track: $tlt");
    // print(await mp.playback.getState());

    print("Get version: ${await mp.tracklist.getVersion()}");
    print("Get tracks: ${await mp.tracklist.getTracks()}");
    print("Index: ${await mp.tracklist.index(null, 9)}");
    print("\n-------------------------------------------------\n");
    mp.tracklist.shuffle(null, null);
    print("Get tracks: ${await mp.tracklist.getTracks()}");
    print("Index: ${await mp.tracklist.index(null, 9)}");

    print("New Volume ${await mp.mixer.getVolume()}");
    List<TlTrack>? tl = await mp.tracklist.filter(FilterCriteria().name(['House On Fire']));

    print('Filter --------------------------------------');
    print(tl);

    print('Search --------------------------------------');
    List<SearchResult>? result = await mp.library.search(SearchCriteria().artist(['K*']), null, false);
    print("RESULT " + result.toString());

    print('Browse --------------------------------------');
    final x = await mp.library.browse("local:directory?type=artist");
    print("RESULT $x");

    print('All URIs --------------------------------------');
    final y = await mp.library.browse(null);
    print("RESULT $y");
  });

  mp.on("state:offline", null, (Event ev, Object? context) {
    print("OFFLINE!");
  });

  mp.on("event:trackPlaybackStarted", null, (Event ev, Object? context) {
    print("************* ${ev.eventName}");
    print(ev.eventData);
  });
  mp.on("event:trackPlaybackPaused", null, (Event ev, Object? context) {
    print("************* ${ev.eventName}");
    print(ev.eventData);
  });
  mp.on("event:playbackStateChanged", null, (Event ev, Object? context) {
    print("************* ${ev.eventName}");
    print(ev.eventData);
  });
  mp.on("event:volumeChanged", null, (Event ev, Object? context) {
    print("************* ${ev.eventName}");
    print(ev.eventData);
  });
  mp.on("event:tracklist_changed", null, (Event ev, Object? context) {
    print("************* ${ev.eventName}");
    print(ev.eventData.toString());
  });

  mp.on("event", null, (Event ev, Object? context) {
    print("event *************");
    print(ev.eventName);
    print(ev.eventData.toString());
  });

  mp.addVolumeChangedListener((volume) {
    print("VOLUME: $volume");
  });

  mp.addTrackPlaybackListener((TrackPlaybackInfo info) {
    print("######");
    print(info.state);
    print(info.tlTrack);
    print(info.timePosition);
  });

  mp.addStreamTitleChangedListener((String title) {
    print("TITLE: $title");
  });

  mp.addPlaybackStateChangedListener((PlaybackState state) {
    print("PlaybackState: $state");
  });

  await mp.connect(webSocketUrl: 'ws://localhost:6680/mopidy/ws');
}
