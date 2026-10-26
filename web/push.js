// Web-Push für PaarQuest (Firebase Cloud Messaging).
// Stellt window.paarquestPush bereit, das lib/web_push_web.dart aufruft.
// Der Service Worker wird unter seinem echten Pfad neben index.html
// angemeldet, damit das auch in einem Unterordner (/paarquest-benjamin/) klappt.
(function () {
  'use strict';

  var SDK = 'https://www.gstatic.com/firebasejs/10.14.1/';
  var SW_PATH = 'firebase-messaging-sw.js';
  var SW_SCOPE = 'firebase-cloud-messaging-push-scope';
  var ready = null;

  function configured() {
    var c = window.PAARQUEST_FIREBASE || {};
    return !!(c.apiKey && c.apiKey !== 'HIER_EINTRAGEN' && window.PAARQUEST_VAPID &&
      window.PAARQUEST_VAPID !== 'HIER_EINTRAGEN');
  }

  function load() {
    if (!ready) {
      ready = Promise.all([
        import(SDK + 'firebase-app.js'),
        import(SDK + 'firebase-messaging.js')
      ]).then(function (mods) {
        var app = mods[0].initializeApp(window.PAARQUEST_FIREBASE);
        var m = mods[1];
        var messaging = m.getMessaging(app);
        // App ist offen: Die App meldet Änderungen schon selbst (Live-Daten),
        // daher hier nichts anzeigen, um doppelte Meldungen zu vermeiden.
        m.onMessage(messaging, function () {});
        return { m: m, messaging: messaging };
      });
      ready.catch(function () { ready = null; });
    }
    return ready;
  }

  function waitActive(reg) {
    if (reg.active) return Promise.resolve(reg);
    var sw = reg.installing || reg.waiting;
    return new Promise(function (resolve) {
      if (!sw) return resolve(reg);
      sw.addEventListener('statechange', function () {
        if (sw.state === 'activated') resolve(reg);
      });
    });
  }

  function getToken() {
    return navigator.serviceWorker
      .register(SW_PATH, { scope: SW_SCOPE })
      .then(waitActive)
      .then(function (reg) {
        return load().then(function (fb) {
          return fb.m.getToken(fb.messaging, {
            vapidKey: window.PAARQUEST_VAPID,
            serviceWorkerRegistration: reg
          });
        });
      });
  }

  window.paarquestPush = {
    // true, wenn dieser Browser Push kann. iPhone: erst als installierte App
    // („Zum Home-Bildschirm“).
    supported: function () {
      if (!configured() || !('serviceWorker' in navigator) ||
          !('Notification' in window) || !('PushManager' in window)) {
        return Promise.resolve(false);
      }
      return import(SDK + 'firebase-messaging.js')
        .then(function (m) { return m.isSupported(); })
        .catch(function () { return false; });
    },

    // 'default', 'granted', 'denied' oder 'unsupported'
    permission: function () {
      return 'Notification' in window ? Notification.permission : 'unsupported';
    },

    // Fragt nach der Erlaubnis (nur nach einem Tipp aufrufen) und liefert
    // den Token, oder '' wenn abgelehnt.
    enable: function () {
      return Notification.requestPermission().then(function (p) {
        return p === 'granted' ? getToken() : '';
      });
    },

    // Token ohne Nachfrage, wenn die Erlaubnis schon besteht.
    token: function () {
      if (!configured() || !('Notification' in window) ||
          Notification.permission !== 'granted') {
        return Promise.resolve('');
      }
      return getToken().catch(function () { return ''; });
    }
  };
})();
