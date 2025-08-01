import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../config/supabase_config.dart';
import '../../services/supabase_service.dart';

class EnvCheckScreen extends StatelessWidget {
  const EnvCheckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
<<<<<<< HEAD
      backgroundColor: Colors.white,
=======
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
>>>>>>> 34d9f1ef3b42adc5bf7751b9cab7c34f309f7afe
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
<<<<<<< HEAD
=======
              context,
>>>>>>> 34d9f1ef3b42adc5bf7751b9cab7c34f309f7afe
              'SUPABASE_URL',
              SupabaseConfig.supabaseUrl,
              SupabaseConfig.supabaseUrl.isNotEmpty,
            ),
            const SizedBox(height: 8),
            _buildEnvItem(
<<<<<<< HEAD
=======
              context,
>>>>>>> 34d9f1ef3b42adc5bf7751b9cab7c34f309f7afe
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
<<<<<<< HEAD
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber),
=======
                  color: Color(0xFFFFB74D).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Color(0xFFFFB74D)),
>>>>>>> 34d9f1ef3b42adc5bf7751b9cab7c34f309f7afe
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
<<<<<<< HEAD
                        Icon(Icons.warning, color: Colors.amber.shade700),
=======
                        Icon(Icons.warning, color: Color(0xFFFFB74D)),
>>>>>>> 34d9f1ef3b42adc5bf7751b9cab7c34f309f7afe
                        const SizedBox(width: 8),
                        Text(
                          '環境変数が設定されていません',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
<<<<<<< HEAD
                            color: Colors.amber.shade700,
=======
                            color: Color(0xFFFFB74D),
>>>>>>> 34d9f1ef3b42adc5bf7751b9cab7c34f309f7afe
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

<<<<<<< HEAD
  Widget _buildEnvItem(String name, String value, bool isSet) {
=======
  Widget _buildEnvItem(BuildContext context, String name, String value, bool isSet) {
>>>>>>> 34d9f1ef3b42adc5bf7751b9cab7c34f309f7afe
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(
              isSet ? Icons.check_circle : Icons.cancel,
<<<<<<< HEAD
              color: isSet ? Colors.green : Colors.red,
=======
              color: isSet ? Color(0xFF7CB342) : Theme.of(context).colorScheme.error,
>>>>>>> 34d9f1ef3b42adc5bf7751b9cab7c34f309f7afe
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
<<<<<<< HEAD
                      color: isSet ? Colors.green : Colors.red,
=======
                      color: isSet ? Color(0xFF7CB342) : Theme.of(context).colorScheme.error,
>>>>>>> 34d9f1ef3b42adc5bf7751b9cab7c34f309f7afe
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