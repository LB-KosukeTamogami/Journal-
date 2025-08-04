import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  
  // Current user state (for compatibility with other screens)
  static Map<String, dynamic>? _currentUser;
  static bool _isAuthenticated = false;
  static String? userName;
  static String? userAvatar;
  
  static Map<String, dynamic>? get currentUser => _currentUser;
  static bool get isAuthenticated => _isAuthenticated;
  
  // 現在は匿名ユーザーのみサポート
  static Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // 一時的に常にtrueを返す（匿名ユーザーとして扱う）
      return true;
    } catch (e) {
      print('[AuthService] Error checking login status: $e');
      return false;
    }
  }

  // ログイン（将来的に実装）
  static Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // TODO: Supabase認証の実装
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isLoggedInKey, true);
      await prefs.setString(_userIdKey, 'anonymous');
      await prefs.setString(_userEmailKey, email);
      return true;
    } catch (e) {
      print('[AuthService] Sign in error: $e');
      return false;
    }
  }

  // サインアップ（将来的に実装）
  static Future<bool> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // TODO: Supabase認証の実装
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isLoggedInKey, true);
      await prefs.setString(_userIdKey, 'anonymous');
      await prefs.setString(_userEmailKey, email);
      return true;
    } catch (e) {
      print('[AuthService] Sign up error: $e');
      return false;
    }
  }

  // ログアウト
  static Future<void> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isLoggedInKey, false);
      await prefs.remove(_userIdKey);
      await prefs.remove(_userEmailKey);
    } catch (e) {
      print('[AuthService] Sign out error: $e');
    }
  }

  // 現在のユーザーID取得
  static Future<String> getCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userIdKey) ?? 'anonymous';
    } catch (e) {
      print('[AuthService] Error getting user ID: $e');
      return 'anonymous';
    }
  }

  // 現在のユーザーメール取得
  static Future<String?> getCurrentUserEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userEmailKey);
    } catch (e) {
      print('[AuthService] Error getting user email: $e');
      return null;
    }
  }

  // パスワードリセット（将来的に実装）
  static Future<bool> resetPassword(String email) async {
    try {
      // TODO: Supabase認証の実装
      return true;
    } catch (e) {
      print('[AuthService] Password reset error: $e');
      return false;
    }
  }
  
  // Send password reset email (alias for forgot_password_screen compatibility)
  static Future<void> sendPasswordResetEmail(String email) async {
    await resetPassword(email);
  }
  
  // Check if email is already registered
  static Future<bool> isEmailRegistered(String email) async {
    // TODO: Implement actual email check
    // For now, always return false (email not registered)
    return false;
  }
  
  // Update user profile
  static Future<void> updateProfile({String? name, String? avatar}) async {
    // TODO: Implement profile update
    final prefs = await SharedPreferences.getInstance();
    if (name != null) {
      await prefs.setString('username', name);
      userName = name;
    }
    if (avatar != null) {
      await prefs.setString('avatar', avatar);
      userAvatar = avatar;
    }
  }

  // Googleサインイン（将来的に実装）
  static Future<bool> signInWithGoogle() async {
    try {
      // TODO: Google認証の実装
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isLoggedInKey, true);
      await prefs.setString(_userIdKey, 'google_anonymous');
      return true;
    } catch (e) {
      print('[AuthService] Google sign in error: $e');
      return false;
    }
  }

  // Appleサインイン（将来的に実装）
  static Future<bool> signInWithApple() async {
    try {
      // TODO: Apple認証の実装
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isLoggedInKey, true);
      await prefs.setString(_userIdKey, 'apple_anonymous');
      return true;
    } catch (e) {
      print('[AuthService] Apple sign in error: $e');
      return false;
    }
  }
}