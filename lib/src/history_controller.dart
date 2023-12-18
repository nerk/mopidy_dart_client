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

/// Get information about previously played tracks.
class HistoryController {
  final Mopidy _mopidy;

  HistoryController._(this._mopidy);

  /// Gets the history of played tracks.
  ///
  /// The keys of the resulting map are timestamps as milliseconds since epoch.
  Future<Map<String, List<Ref>>> getHistory() async {
    var r = await _mopidy._send({"method": "core.history.get_history"});
    Map<String, List<Ref>> result = <String, List<Ref>>{};
    for (var key in r.keys) {
      result[key] = (r[key] as List).map((e) => e as Ref).toList();
    }
    return result;
  }

  /// Gets the number of tracks in the history.
  Future<int> getLength() async {
    return await _mopidy._send({"method": "core.history.get_length"});
  }
}
