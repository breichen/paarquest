// Service Worker für Web-Push (Firebase Cloud Messaging).
// Zeigt Mitteilungen an, wenn die App geschlossen oder im Hintergrund ist.

const APP_URL = new URL('./', self.location.href).href;

// Antippen: offenes App-Fenster nach vorne holen, sonst die App öffnen.
// Muss vor dem Laden des Firebase-SDKs registriert werden.
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  event.stopImmediatePropagation();
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((windows) => {
      const app = windows.find((w) => w.url.startsWith(APP_URL) && 'focus' in w);
      return app ? app.focus() : clients.openWindow(APP_URL);
    })
  );
});

importScripts('push_config.js');
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-messaging-compat.js');

firebase.initializeApp(self.PAARQUEST_FIREBASE);

// Mitteilungen mit Titel/Text zeigt das SDK im Hintergrund selbst an.
firebase.messaging();
