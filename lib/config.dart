import 'package:flutter/material.dart';

// Flag vor dem Kompilieren:
//   Benjamin: flutter build apk --dart-define=IS_BENJAMIN=true
//   Theresa:  flutter build apk --dart-define=IS_BENJAMIN=false
const bool isBenjamin = bool.fromEnvironment('IS_BENJAMIN', defaultValue: true);

const supabaseUrl = 'https://dcmyhjbhcifevisbhjav.supabase.co';
const supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRjbXloamJoY2lmZXZpc2JoamF2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTIwODExMTAsImV4cCI6MjEwNzY1NzExMH0.hud9OcwF2iCa6C8dKmSDenNrkOcg4NvYWoi4VXTPymA';

const String me = isBenjamin ? 'Benjamin' : 'Theresa';
const String partner = isBenjamin ? 'Theresa' : 'Benjamin';

String otherPerson(String name) => name == 'Benjamin' ? 'Theresa' : 'Benjamin';

// Jede Person hat ihre Farbe: Münzleiste, Aufgabenkarten und Übersicht nutzen sie gleich.
Color personColor(String name) =>
    name == 'Benjamin' ? const Color(0xFF1F7A8C) : const Color(0xFFC9457B);

Color personLight(String name) =>
    name == 'Benjamin' ? const Color(0xFFDDEFF3) : const Color(0xFFFAE0EB);
