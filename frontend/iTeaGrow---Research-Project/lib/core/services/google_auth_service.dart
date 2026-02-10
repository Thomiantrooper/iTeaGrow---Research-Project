import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Service for handling Google Sign-In authentication
class GoogleAuthService {
  GoogleSignIn? _googleSignIn;
  bool _isInitialized = false;

  GoogleAuthService() {
    _initializeGoogleSignIn();
  }

  void _initializeGoogleSignIn() {
    // Initialize Google Sign-In with scopes
    // For web: Add client ID to web/index.html as meta tag or pass it here
    // For mobile: Configure in platform-specific files (AndroidManifest.xml, Info.plist)
    try {
      _googleSignIn = GoogleSignIn(
        scopes: [
          'email',
          'profile',
        ],
        // Uncomment and add your web client ID here if not using meta tag:
        // clientId: 'YOUR_CLIENT_ID.apps.googleusercontent.com',
      );
      _isInitialized = true;
      debugPrint('Google Sign-In initialized successfully');
    } catch (e) {
      debugPrint('Google Sign-In initialization failed: $e');
      debugPrint(
          'To enable Google Sign-In on web, add your OAuth Client ID to web/index.html');
      debugPrint('See google_signin_setup.md for detailed instructions');
      _isInitialized = false;
    }
  }

  /// Check if user is currently signed in with Google
  Future<bool> isSignedIn() async {
    if (!_isInitialized || _googleSignIn == null) return false;
    return await _googleSignIn!.isSignedIn();
  }

  /// Get currently signed in Google account
  GoogleSignInAccount? get currentUser => _googleSignIn?.currentUser;

  /// Sign in with Google
  /// Returns GoogleSignInAccount on success, null on failure
  Future<GoogleSignInAccount?> signIn() async {
    if (!_isInitialized || _googleSignIn == null) {
      debugPrint('Google Sign-In not initialized');
      return null;
    }

    try {
      debugPrint('Attempting Google Sign-In...');
      final account = await _googleSignIn!.signIn();

      if (account != null) {
        debugPrint('Google Sign-In successful: ${account.email}');
        return account;
      } else {
        debugPrint('Google Sign-In cancelled by user');
        return null;
      }
    } catch (error) {
      debugPrint('Error signing in with Google: $error');
      return null;
    }
  }

  /// Sign in silently (if user previously signed in)
  Future<GoogleSignInAccount?> signInSilently() async {
    if (!_isInitialized || _googleSignIn == null) {
      debugPrint('Google Sign-In not initialized');
      return null;
    }

    try {
      debugPrint('Attempting silent Google Sign-In...');
      final account = await _googleSignIn!.signInSilently();

      if (account != null) {
        debugPrint('Silent Google Sign-In successful: ${account.email}');
      } else {
        debugPrint('No previous Google Sign-In found');
      }

      return account;
    } catch (error) {
      debugPrint('Error in silent Google Sign-In: $error');
      return null;
    }
  }

  /// Sign out from Google
  Future<void> signOut() async {
    if (!_isInitialized || _googleSignIn == null) return;

    try {
      await _googleSignIn!.signOut();
      debugPrint('Google Sign-Out successful');
    } catch (error) {
      debugPrint('Error signing out from Google: $error');
    }
  }

  /// Disconnect Google account (revoke access)
  Future<void> disconnect() async {
    if (!_isInitialized || _googleSignIn == null) return;

    try {
      await _googleSignIn!.disconnect();
      debugPrint('Google account disconnected');
    } catch (error) {
      debugPrint('Error disconnecting Google account: $error');
    }
  }

  /// Get authentication token for backend verification
  Future<String?> getIdToken() async {
    if (!_isInitialized || _googleSignIn == null) return null;

    try {
      final account = _googleSignIn!.currentUser;
      if (account == null) {
        debugPrint('No Google account signed in');
        return null;
      }

      final auth = await account.authentication;
      return auth.idToken;
    } catch (error) {
      debugPrint('Error getting Google ID token: $error');
      return null;
    }
  }

  /// Get access token
  Future<String?> getAccessToken() async {
    if (!_isInitialized || _googleSignIn == null) return null;

    try {
      final account = _googleSignIn!.currentUser;
      if (account == null) {
        debugPrint('No Google account signed in');
        return null;
      }

      final auth = await account.authentication;
      return auth.accessToken;
    } catch (error) {
      debugPrint('Error getting Google access token: $error');
      return null;
    }
  }

  /// Extract user data from Google account
  Map<String, dynamic> extractUserData(GoogleSignInAccount account) {
    return {
      'email': account.email,
      'displayName': account.displayName ?? '',
      'photoUrl': account.photoUrl ?? '',
      'id': account.id,
    };
  }
}

/// Provider for GoogleAuthService
final googleAuthServiceProvider = Provider<GoogleAuthService>((ref) {
  return GoogleAuthService();
});
