import 'package:firebase_core/firebase_core.dart';

class FirebaseConfig {
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: "AIzaSyDKHy1BBdLfA4MiD5JTkwboHTf8QidSUEo",
          authDomain: "task-management-46e89.firebaseapp.com",
          projectId: "task-management-46e89",
          messagingSenderId: "615141242258",
          appId: "1:615141242258:web:a95f9a150b1b8b893bfd4b",
        ),
      );
    } catch (e) {
      print("Error initializing Firebase: $e");
      // Handle the error appropriately (e.g., show an error message).
    }
  }
}
