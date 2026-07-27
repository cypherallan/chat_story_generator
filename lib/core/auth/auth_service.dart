import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth;

  AuthService(this._auth);

  Future<User> signInAnonymously() async {
    final credential = await _auth.signInAnonymously();
    return credential.user!;
  }

  User? get currentUser => _auth.currentUser;

  String? get uid => _auth.currentUser?.uid;

  bool get isSignedIn => _auth.currentUser != null;

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
