import 'dart:async';
import 'dart:isolate';

/// Create a [SendPort] that accepts only one message.
///
/// When the first message is received, the [callback] function is
/// called with the message as argument,
/// and the [completer] is completed with the result of that call.
/// All further messages are ignored.
///
/// If `callback` is omitted, it defaults to an identity function.
/// The `callback` call may return a future, and the completer will
/// wait for that future to complete. If [callback] is omitted, the
/// message on the port must be an instance of [R].
///
/// If [timeout] is supplied, it is used as a limit on how
/// long it can take before the message is received. If a
/// message isn't received in time, the [onTimeout] is called,
/// and `completer` is completed with the result of that call
/// instead.
/// The [callback] function will not be interrupted by the time-out,
/// as long as the initial message is received in time.
/// If `onTimeout` is omitted, it defaults to completing the `completer` with
/// a [TimeoutException].
///
/// The [completer] may be a synchronous completer. It is only
/// completed in response to another event, either a port message or a timer.
///
/// Returns the `SendPort` expecting the single message.
SendPort singleCompletePort(Completer<dynamic> completer) {
  return _singleCallbackPort((response) {
    _castComplete(completer, response);
  });
}

/// Helper function for [singleCallbackPort].
///
/// Replace [singleCallbackPort] with this
/// when removing the deprecated parameters.
SendPort _singleCallbackPort(void Function(dynamic) callback) {
  var responsePort = RawReceivePort();
  var zone = Zone.current;
  callback = zone.registerUnaryCallback(callback);
  responsePort.handler = (response) {
    responsePort.close();
    zone.runUnary(callback, response);
  };
  return responsePort.sendPort;
}

// Helper function that casts an object to a type and completes a
// corresponding completer, or completes with the error if the cast fails.
void _castComplete(Completer<dynamic> completer, dynamic value) {
  try {
    completer.complete(value);
  } catch (error, stack) {
    completer.completeError(error, stack);
  }
}
