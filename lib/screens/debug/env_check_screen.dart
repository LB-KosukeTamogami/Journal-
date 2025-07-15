import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../config/supabase_config.dart';
import '../../services/supabase_service.dart';

class EnvCheckScreen extends StatelessWidget {
  const EnvCheckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
              'SUPABASE_URL',
              SupabaseConfig.supabaseUrl,
              SupabaseConfig.supabaseUrl.isNotEmpty,
            ),
            const SizedBox(height: 8),
            _buildEnvItem(
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
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning, color: Colors.amber.shade700),
                        const SizedBox(width: 8),
                        Text(
                          '環境変数が設定されていません',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade700,
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

  Widget _buildEnvItem(String name, String value, bool isSet) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(
              isSet ? Icons.check_circle : Icons.cancel,
              color: isSet ? Colors.green : Colors.red,
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
                      color: isSet ? Colors.green : Colors.red,
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