import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth;

  AuthService(this._auth);

  // -------------------------
  // Current user
  // -------------------------

  User? get currentUser => _auth.currentUser;

  String? get uid => _auth.currentUser?.uid;

  bool get isSignedIn => _auth.currentUser != null;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  bool get isAnonymous => _auth.currentUser?.isAnonymous ?? false;

  // -------------------------
  // Anonymous sign in
  // -------------------------

  Future<User> signInAnonymously() async {
    final credential = await _auth.signInAnonymously();
    return credential.user!;
  }

  Future<void> updateDisplayName(String name) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('No signed-in user.');
    }

    await user.updateDisplayName(name.trim());

    await user.reload();
  }
  // -------------------------
  // Email/password signup
  // -------------------------

  Future<User> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user!;

    await user.updateDisplayName(name.trim());
    await user.reload();

    return _auth.currentUser!;
  }

  // -------------------------
  // Email/password login
  // -------------------------

  Future<User> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user!;

    return user;
  }

  // -------------------------
  // Sign out
  // -------------------------

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> sendPasswordResetEmail({
    required String email,
  }) async {
    await _auth.sendPasswordResetEmail(
      email: email.trim(),
    );
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('No signed-in user.');
    }

    final email = user.email;

    if (email == null || email.isEmpty) {
      throw Exception('This account does not have an email address.');
    }

    final credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );

    await user.reauthenticateWithCredential(credential);

    await user.updatePassword(newPassword);

    await user.reload();
  }
}
