import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class AuthService {
  static SupabaseClient? get _supabaseOrNull => SupabaseService.client;
  
  static SupabaseClient get _supabase {
    final client = _supabaseOrNull;
    if (client == null) {
      throw Exception('Supabase not initialized');
    }
    return client;
  }
  
  // Get current user
  static User? get currentUser {
    try {
      final client = _supabaseOrNull;
      if (client == null) {
        print('[AuthService] Supabase not initialized, returning null user');
        return null;
      }
      return client.auth.currentUser;
    } catch (e) {
      print('[AuthService] Error getting current user: $e');
      return null;
    }
  }
  
  // Get current user ID
  static String? get currentUserId {
    try {
      return currentUser?.id;
    } catch (e) {
      print('[AuthService] Error getting current user ID: $e');
      return null;
    }
  }
  
  // Auth state changes stream
  static Stream<AuthState> get authStateChanges {
    try {
      return _supabase.auth.onAuthStateChange;
    } catch (e) {
      print('[AuthService] Error getting auth state changes: $e');
      return const Stream.empty();
    }
  }
  
  // Sign up with email and password
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'username': username},
      );
      
      // Create user profile in users table
      if (response.user != null) {
        await _supabase.from('users').insert({
          'id': response.user!.id,
          'email': email,
          'name': username,
        });
      }
      
      return response;
    } catch (e) {
      throw Exception('登録に失敗しました: $e');
    }
  }
  
  // Sign in with email and password
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      throw Exception('ログインに失敗しました: $e');
    }
  }
  
  // Sign out
  static Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('ログアウトに失敗しました: $e');
    }
  }
  
  // Send password reset email
  static Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw Exception('パスワードリセットメールの送信に失敗しました: $e');
    }
  }
  
  // Update password
  static Future<UserResponse> updatePassword(String newPassword) async {
    try {
      final response = await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      return response;
    } catch (e) {
      throw Exception('パスワードの更新に失敗しました: $e');
    }
  }
  
  // Update user profile
  static Future<void> updateProfile({
    required String username,
  }) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('ユーザーが見つかりません');
      
      await _supabase.from('users').update({
        'name': username,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
      
      // Also update auth metadata
      await _supabase.auth.updateUser(
        UserAttributes(data: {'username': username}),
      );
    } catch (e) {
      throw Exception('プロファイルの更新に失敗しました: $e');
    }
  }
  
  // Get user profile
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final userId = currentUserId;
      if (userId == null) return null;
      
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();
          
      return response;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }
  
  // Check if email is already registered
  static Future<bool> isEmailRegistered(String email) async {
    try {
      final response = await _supabase
          .from('users')
          .select('id')
          .eq('email', email)
          .maybeSingle();
          
      return response != null;
    } catch (e) {
      return false;
    }
  }
}