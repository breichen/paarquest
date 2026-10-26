// Firebase-Konfiguration für Web-Push. Wird von push.js (Seite) und
// firebase-messaging-sw.js (Service Worker) gemeinsam verwendet.
//
// Werte aus der Firebase Console (Projekt "paarquest"):
//  * FIREBASE: Projekteinstellungen → Allgemein → Meine Apps → Web-App → SDK-Konfiguration
//  * VAPID:    Projekteinstellungen → Cloud Messaging → Web-Push-Zertifikate → Schlüsselpaar
self.PAARQUEST_FIREBASE = {
  apiKey: 'AIzaSyC-8cPz2pYiQHewP378nRS-WS2fQRdpIUY',
  appId: '1:115906227809:web:5631fdeaddd94a95970420',
  messagingSenderId: '115906227809',
  projectId: 'paarquest',
  authDomain: 'paarquest.firebaseapp.com',
  storageBucket: 'paarquest.firebasestorage.app'
};
self.PAARQUEST_VAPID = 'BKrF8So02xN67ggaDQO5DHD4kgUQZ7wDtY6Q9c9WrvCVe6Gtx0DX5hKTNuFAECxcggm9biUlHMylOff4fv8fRBs';
