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

import 'package:format/format.dart';

/// Base class for Mopidy related exceptions.
abstract class MopidyException implements Exception {
  static const errorUnknown = 'ERROR_UNKNOWN';

  static const defaultMessage = 'Mopidy error: {}';

  /// Error code as a string.
  String errorCode;

  /// A message describing the error.
  String message;

  /// Arguments to be inserted into [message]
  Object? arguments;

  MopidyException({this.errorCode = errorUnknown, this.message = defaultMessage, this.arguments});

  factory MopidyException.connectionException(errorCode, message, [arguments]) {
    return ConnectionException(errorCode, message, arguments);
  }

  factory MopidyException.serverException(errorCode, message, [arguments]) {
    return ServerException(errorCode, message, arguments);
  }

  @override
  String toString() {
    try {
      if (arguments != null) {
        if (arguments is List) {
          return message.format([...(arguments as List)]);
        } else {
          return message.format(arguments.toString());
        }
      } else {
        return message.format(errorCode);
      }
    } catch (e) {
      return e.toString();
    }
  }
}

/// Exception indicating an exception related to the server connection.
class ConnectionException extends MopidyException {
  static const errorSocketClosed = 'ERROR_SOCKET_CLOSED';
  static const errorSocketClosing = 'ERROR_SOCKET_CLOSING';
  static const errorSocketConnecting = 'ERROR_SOCKET_CONNECTING';
  static const canceled = 'CANCELED';

  ConnectionException(errorCode, message, arguments) : super(errorCode: errorCode, message: message, arguments: arguments);
}

/// Exception thrown by the Mopidy server.
class ServerException extends MopidyException {
  static const errorUnexpectedResponse = 'ERROR_UNEXPECTED_RESPONSE';
  static const errorServerResponse = 'ERROR_SERVER_RESPONSE';

  ServerException(errorCode, message, arguments) : super(errorCode: errorCode, message: message, arguments: arguments);
}
