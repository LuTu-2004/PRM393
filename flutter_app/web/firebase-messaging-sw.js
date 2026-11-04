importScripts('https://www.gstatic.com/firebasejs/9.22.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.22.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyB4PfawQsPfXgbVNpQecajWIM4pna8_nwE",
  authDomain: "exe-team-matching-70774.firebaseapp.com",
  projectId: "exe-team-matching-70774",
  storageBucket: "exe-team-matching-70774.firebasestorage.app",
  messagingSenderId: "959409386646",
  appId: "1:959409386646:web:c391fab6788676b2807eb7"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Nhận thông báo chạy nền:', payload);
  const notificationTitle = payload.notification ? payload.notification.title : 'EXE Team Matching';
  const notificationOptions = {
    body: payload.notification ? payload.notification.body : 'Bạn có thông báo mới từ hệ thống.',
    icon: '/icons/Icon-192.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});

