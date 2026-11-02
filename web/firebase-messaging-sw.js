// Nạp thư viện Firebase cho Service Worker
importScripts(
  'https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js'
);
importScripts(
  'https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js'
);

// Cấu hình Firebase của UTH Todo
// Lấy các giá trị thực từ lib/firebase_options.dart
firebase.initializeApp({
  apiKey: 'AIzaSyBqu83L82LWPAXuSpMIv4BPvea1XWJTpkk',
  authDomain: 'uth-todo-42e95.firebaseapp.com',
  projectId: 'uth-todo-42e95',
  storageBucket: 'uth-todo-42e95.firebasestorage.app',
  messagingSenderId: '836902046180',
  appId: '1:836902046180:web:2bc1a21e12ec85ef015ff1',
  measurementId: 'G-T3CGFHYZWZ',
});

// Khởi tạo Firebase Cloud Messaging
const messaging = firebase.messaging();

// Firebase tự xử lý notification payload khi app ở background.
// Không gọi showNotification thêm với cùng một thông báo
// để tránh hiện thông báo trùng lặp.