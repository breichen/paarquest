# PaarQuest

Aufgaben und Münzen für Benjamin und Theresa.

## Einrichtung

1. **Flutter-Projekt anlegen** (einmalig, erzeugt android/ios-Ordner):
   ```
   flutter create paarquest
   ```
   Dann `pubspec.yaml` und `lib/main.dart` aus diesem Ordner hineinkopieren und `flutter pub get` ausführen.

2. **Supabase**: Gratis-Projekt anlegen, im *SQL Editor* den Inhalt von `supabase_schema.sql` ausführen.

3. **Zugangsdaten**: In `lib/main.dart` `supabaseUrl` und `supabaseAnonKey` eintragen
   (Supabase → Project Settings → API).

4. **Flag setzen und kompilieren**:
   ```
   flutter build apk --dart-define=IS_BENJAMIN=true     # Benjamins App
   flutter build apk --dart-define=IS_BENJAMIN=false    # Theresas App
   ```
   Zum Testen: `flutter run --dart-define=IS_BENJAMIN=false`

## Ablauf der Aufgaben

- Senden: Aufgabe aus der Liste wählen (Felder lassen sich anpassen) oder selbst eingeben.
- Empfänger: Annehmen, Ablehnen oder Gegenvorschlag (Münzen und/oder Zeit).
- Bei Gegenvorschlag entscheidet der Absender: Akzeptieren oder Verwerfen.
- Die Frist läuft ab dem Moment der Annahme.
- Erledigung: Der Empfänger fragt die Erledigung an, der Absender bestätigt (dann gibt es die Münzen) oder schickt sie mit „Noch nicht" zurück.
- Abbrechen: Der Empfänger kann eine angenommene Aufgabe jederzeit abbrechen. Ist die Frist abgelaufen, können beide abbrechen.
- Shop: Münzen gegen Belohnungen einlösen, der/die andere bestätigt mit „Erfüllt".

## Hinweise

- Es gibt keinen Login. Der anon-Key liegt in der App, jeder mit der APK könnte die Daten lesen und ändern. Für ein privates Projekt zu zweit ist das okay, die APK also nicht weitergeben.
- Aufgaben, Belohnungen und Preise stehen oben in `main.dart` (`templates`, `rewards`) und lassen sich leicht ändern.
- Münzstand = erledigte Aufgaben minus Einlösungen, er wird live berechnet.

## Push-Nachrichten einrichten (Firebase)

1. **SQL**: `supabase_update_push.sql` im Supabase SQL Editor ausführen.
2. **Firebase**: Auf console.firebase.google.com ein Projekt anlegen (Spark-Tarif, kostenlos).
3. **App verbinden**: im Projektordner
   ```
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   Das erzeugt `lib/firebase_options.dart` und richtet Android ein.
4. **Android-Feinheiten** (`android/app/build.gradle`):
   - `minSdkVersion` auf mindestens 23 setzen.
   - Für flutter_local_notifications in `compileOptions` `coreLibraryDesugaringEnabled true` setzen und bei `dependencies` `coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.0.4'` ergänzen.
5. **Service-Account**: Firebase → Projekteinstellungen → Dienstkonten → „Neuen privaten Schlüssel generieren". Den Inhalt der JSON-Datei als Secret speichern:
   ```
   supabase secrets set FIREBASE_SERVICE_ACCOUNT='<JSON-Inhalt in einer Zeile>'
   ```
6. **Funktion deployen** (Supabase CLI, einmal `supabase link` im Projektordner):
   ```
   supabase functions deploy notify
   ```
7. **Webhooks**: Supabase Dashboard → Database → Webhooks → zwei Webhooks anlegen, jeweils Typ *Supabase Edge Functions* und Funktion `notify`:
   - Tabelle `tasks`, Events Insert und Update
   - Tabelle `purchases`, Events Insert und Update
8. Beide Apps einmal öffnen und die Benachrichtigungs-Erlaubnis bestätigen. Dadurch wird das Gerät in `device_tokens` registriert.

Hinweise: Pro Person wird ein Gerät gespeichert, das zuletzt gestartete.

## iPhone (ohne Apple Developer Program)

- Install: `flutter run --release --dart-define=IS_BENJAMIN=true` mit angeschlossenem iPhone. Mit kostenloser Apple-ID läuft die Signatur nach 7 Tagen ab, dann einfach erneut installieren.
- Auf iOS wird Firebase nicht benutzt. Bei `flutterfire configure` reicht daher die Plattform Android.
- Benachrichtigungen kommen dort nur, solange die App läuft und mit Supabase verbunden ist (meist wenige Sekunden bis Minuten nach dem Verlassen). Was bei geschlossener App passiert, siehst du beim nächsten Öffnen.
- Auf dem iPhone beim ersten Start die Benachrichtigungen erlauben.

## Update 2 (Beschreibungen, Kategorien, Icon, Name, Schrift)

1. `supabase_update_v2.sql` im SQL Editor ausführen.
2. Funktion neu deployen (neue Meldungen für die Erledigung): `supabase functions deploy notify`
3. `flutter pub get`, danach einmal `./tool/apply_branding.sh` im Projektordner. Das setzt den App-Namen „PaarQuest" (Android und iOS) und erzeugt die Icons aus `assets/icon/`.
4. Die Schrift Lato lädt `google_fonts` beim ersten Start aus dem Netz und speichert sie danach. Wer sie fest einbauen will, legt die Lato-Dateien unter `assets/google_fonts/` ab und trägt den Ordner unter `flutter: assets:` ein.

Gut zu wissen:
- Tippe oben auf die Münzleiste, dann siehst du pro Person erledigte, laufende und noch offene Aufgaben.
- Karten und Münzleiste nutzen dieselben Farben: Benjamin Petrol, Theresa Rosé. Die Karte zeigt die Farbe der Person, für die die Aufgabe ist. Die Liste enthält Aufgaben in beide Richtungen.
- Gespeicherte Aufgaben sind in der Auswahl mit einem Lesezeichen markiert und lassen sich durch langes Drücken löschen.
- Bestehende Aufgaben aus der Kategorie „Überraschung" bleiben in der Datenbank und werden weiter angezeigt.

## Löschen und Ändern (nur auf dem eigenen Gerät)

- Erledigte, abgelehnte, verworfene und abgebrochene Aufgaben haben im Reiter „Erledigt" einen Löschen-Knopf. Die Aufgabe verschwindet nur auf diesem Gerät (Merkliste in shared_preferences). In Supabase bleibt sie, der Partner sieht sie weiter, Münzen und Übersicht zählen sie mit. Laufende Aufgaben werden erst abgebrochen oder abgelehnt und können dann gelöscht werden.
- In der Aufgabenauswahl öffnet langes Drücken ein Menü mit Ändern und Löschen, auch bei eingebauten Aufgaben. Oben erscheint ein Knopf, der gelöschte Standard-Aufgaben wiederherstellt.
- Bereits abgeschickte Aufgaben lassen sich nicht nachträglich ändern. Dafür gibt es den Gegenvorschlag bei Münzen und Zeit.
