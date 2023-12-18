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

/// MixerController is used to control volume and mute state.
class MixerController {
  final Mopidy _mopidy;

  MixerController._(this._mopidy);

  /// Gets the current mute state.
  ///
  /// `true` if muted, `false` if unmuted, `null` if unknown.
  Future<bool?> getMute() async {
    return await _mopidy._send({"method": "core.mixer.get_mute"});
  }

  /// Sets the mute state.
  ///
  /// If [mute] is `true`, sound is muted. If [mute] is `false`, sound is unmuted.
  ///
  /// Returns `true` if call was successful, `false` otherwise.
  Future<bool> setMute(bool mute) async {
    return await _mopidy._send({
      "method": "core.mixer.set_mute",
      "params": {"mute": mute}
    });
  }

  /// Gets the current voulume.
  ///
  /// The volume is an integer in range `0..100` or `null` if unknown.
  ///
  /// The volume scale is linear.
  Future<int?> getVolume() async {
    return await _mopidy._send({"method": "core.mixer.get_volume"});
  }

  /// Sets the volume.
  ///
  /// The [volume] is defined as an integer in range `0..100`.
  ///
  /// The volume scale is linear.
  Future<bool> setVolume(int volume) async {
    return await _mopidy._send({
      "method": "core.mixer.set_volume",
      "params": {"volume": volume}
    });
  }
}
