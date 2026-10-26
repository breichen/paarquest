// Web-Push nur im Browser; auf Android/iOS leere Platzhalter.
export 'web_push_stub.dart' if (dart.library.js_interop) 'web_push_web.dart';
