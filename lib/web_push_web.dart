// Brücke zu window.paarquestPush (web/push.js).
import 'dart:js_interop';

import 'package:flutter/foundation.dart' show debugPrint;

extension type _PaarquestPush._(JSObject _) implements JSObject {
  external JSPromise<JSBoolean> supported();
  external JSString permission();
  external JSPromise<JSString> enable();
  external JSPromise<JSString> token();
}

@JS('paarquestPush')
external _PaarquestPush? get _push;

/// Kann dieser Browser Push? (iPhone: nur als installierte App.)
Future<bool> webPushSupported() async {
  try {
    final p = _push;
    return p != null && (await p.supported().toDart).toDart;
  } catch (e) {
    debugPrint('Web-Push nicht verfügbar: $e');
    return false;
  }
}

/// 'default', 'granted', 'denied' oder 'unsupported'.
String webPushPermission() {
  try {
    return _push?.permission().toDart ?? 'unsupported';
  } catch (_) {
    return 'unsupported';
  }
}

/// Erlaubnis erfragen (nur nach einem Tipp!) und Token liefern, sonst ''.
Future<String> webPushEnable() async {
  final p = _push;
  if (p == null) return '';
  return (await p.enable().toDart).toDart;
}

/// Token ohne Nachfrage (wenn die Erlaubnis schon besteht), sonst ''.
Future<String> webPushToken() async {
  try {
    final p = _push;
    return p == null ? '' : (await p.token().toDart).toDart;
  } catch (e) {
    debugPrint('Web-Push-Token fehlgeschlagen: $e');
    return '';
  }
}
