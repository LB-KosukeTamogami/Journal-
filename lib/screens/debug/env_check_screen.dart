import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../config/supabase_config.dart';
import '../../services/supabase_service.dart';

class EnvCheckScreen extends StatelessWidget {
  const EnvCheckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('環境変数チェック'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '環境変数の設定状況',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _buildEnvItem(
              context,
              'SUPABASE_URL',
              SupabaseConfig.supabaseUrl,
              SupabaseConfig.supabaseUrl.isNotEmpty,
            ),
            const SizedBox(height: 8),
            _buildEnvItem(
              context,
              'SUPABASE_ANON_KEY',
              SupabaseConfig.supabaseAnonKey,
              SupabaseConfig.supabaseAnonKey.isNotEmpty,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Supabase初期化状態',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text('設定完了: ${SupabaseConfig.isConfigured ? "✅" : "❌"}'),
                    Text('クライアント: ${SupabaseService.client != null ? "✅ 初期化済み" : "❌ 未初期化"}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (!SupabaseConfig.isConfigured)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFFFFB74D).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Color(0xFFFFB74D)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning, color: Color(0xFFFFB74D)),
                        const SizedBox(width: 8),
                        Text(
                          '環境変数が設定されていません',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFB74D),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Vercelの環境変数に以下を設定してください：\n'
                      '• SUPABASE_URL\n'
                      '• SUPABASE_ANON_KEY',
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnvItem(BuildContext context, String name, String value, bool isSet) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(
              isSet ? Icons.check_circle : Icons.cancel,
              color: isSet ? Color(0xFF7CB342) : Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    isSet ? '設定済み (${value.length}文字)' : '未設定',
                    style: TextStyle(
                      color: isSet ? Color(0xFF7CB342) : Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}