import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';

/// Project-owned wrapper around `FirebaseAuth` and `GoogleSignIn`. Lets the
/// repository depend on a mockable abstraction (CLAUDE.md / Dependencies).
abstract class FirebaseAuthDatasource {
  Stream<fb.User?> watchUser();
  fb.User? get currentUser;

  /// Returns the Firebase user after a successful Google flow. Throws on
  /// cancellation, network, etc. — the repository converts to Failures.
  Future<fb.User> signInWithGoogle();

  Future<void> signOut();
}

class FirebaseAuthDatasourceImpl implements FirebaseAuthDatasource {
  FirebaseAuthDatasourceImpl({
    required fb.FirebaseAuth firebaseAuth,
    required GoogleSignIn googleSignIn,
  })  : _firebaseAuth = firebaseAuth,
        _googleSignIn = googleSignIn;

  final fb.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  @override
  Stream<fb.User?> watchUser() => _firebaseAuth.authStateChanges();

  @override
  fb.User? get currentUser => _firebaseAuth.currentUser;

  @override
  Future<fb.User> signInWithGoogle() async {
    final account = await _googleSignIn.authenticate();
    final auth = account.authentication;
    final credential = fb.GoogleAuthProvider.credential(idToken: auth.idToken);
    final result = await _firebaseAuth.signInWithCredential(credential);
    final user = result.user;
    if (user == null) {
      throw StateError('FirebaseAuth returned a null user after sign-in.');
    }
    return user;
  }

  @override
  Future<void> signOut() async {
    await Future.wait([
      _googleSignIn.signOut(),
      _firebaseAuth.signOut(),
    ]);
  }
}
