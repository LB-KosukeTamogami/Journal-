import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('プライバシーポリシー'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Journal Language Learning\nプライバシーポリシー',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
            ).animate().fadeIn(),
            const SizedBox(height: 8),
            Text(
              '最終更新日: ${DateTime.now().year}年${DateTime.now().month}月${DateTime.now().day}日',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 24),
            _buildSection(
              context,
              '1. はじめに',
              'Journal Language Learning（以下「当社」といいます）は、お客様の個人情報の保護を重要な責務と考え、本プライバシーポリシーに基づき、個人情報を適切に取り扱います。',
            ).animate().slideX(begin: -0.1, duration: 300.ms, delay: 200.ms),
            _buildSection(
              context,
              '2. 収集する情報',
              '当社は、以下の情報を収集することがあります：\n'
              '・アカウント情報（ユーザー名、メールアドレス、パスワード）\n'
              '・プロフィール情報（プロフィール画像など）\n'
              '・学習データ（日記エントリー、学習した単語、学習進捗）\n'
              '・利用状況データ（ログイン履歴、機能の使用頻度）\n'
              '・デバイス情報（OSバージョン、アプリバージョン）',
            ).animate().slideX(begin: -0.1, duration: 300.ms, delay: 300.ms),
            _buildSection(
              context,
              '3. 情報の利用目的',
              '収集した情報は以下の目的で利用します：\n'
              '・サービスの提供および運営\n'
              '・ユーザーサポートの提供\n'
              '・サービスの改善および新機能の開発\n'
              '・学習効果の分析および個別最適化\n'
              '・重要なお知らせやアップデート情報の通知\n'
              '・利用規約違反や不正行為の防止',
            ).animate().slideX(begin: -0.1, duration: 300.ms, delay: 400.ms),
            _buildSection(
              context,
              '4. 情報の共有と開示',
              '当社は、以下の場合を除き、お客様の個人情報を第三者に開示または共有することはありません：\n'
              '・お客様の同意がある場合\n'
              '・法令に基づく開示請求がある場合\n'
              '・サービス提供のために必要な業務委託先への提供（機密保持契約を締結）\n'
              '・統計的な情報として個人を識別できない形での利用',
            ).animate().slideX(begin: -0.1, duration: 300.ms, delay: 500.ms),
            _buildSection(
              context,
              '5. データの保護',
              '当社は、お客様の個人情報を保護するために、以下のような対策を実施しています：\n'
              '・SSL/TLS暗号化通信の使用\n'
              '・アクセス権限の厳格な管理\n'
              '・定期的なセキュリティ監査\n'
              '・従業員への個人情報保護教育',
            ).animate().slideX(begin: -0.1, duration: 300.ms, delay: 600.ms),
            _buildSection(
              context,
              '6. Cookie（クッキー）の使用',
              '当社のウェブサービスでは、サービスの利便性向上のためにCookieを使用することがあります。Cookieは、お客様のブラウザ設定により無効にすることができますが、一部のサービスが正常に動作しない場合があります。',
            ).animate().slideX(begin: -0.1, duration: 300.ms, delay: 700.ms),
            _buildSection(
              context,
              '7. 第三者サービスとの連携',
              '当社のサービスは、以下の第三者サービスと連携することがあります：\n'
              '・Google Gemini API（AI翻訳・添削機能）\n'
              '・Supabase（データベースおよび認証サービス）\n'
              'これらのサービスには、それぞれのプライバシーポリシーが適用されます。',
            ).animate().slideX(begin: -0.1, duration: 300.ms, delay: 800.ms),
            _buildSection(
              context,
              '8. お客様の権利',
              'お客様は、ご自身の個人情報について以下の権利を有します：\n'
              '・個人情報の開示請求\n'
              '・個人情報の訂正・更新\n'
              '・個人情報の削除請求\n'
              '・個人情報の利用停止請求\n'
              'これらの請求は、アプリ内の設定画面またはお問い合わせフォームから行うことができます。',
            ).animate().slideX(begin: -0.1, duration: 300.ms, delay: 900.ms),
            _buildSection(
              context,
              '9. 子どものプライバシー',
              '当社のサービスは13歳以上の方を対象としています。13歳未満のお子様が保護者の同意なくサービスを利用することはできません。13歳未満のお子様の個人情報が誤って収集された場合は、速やかに削除いたします。',
            ).animate().slideX(begin: -0.1, duration: 300.ms, delay: 1000.ms),
            _buildSection(
              context,
              '10. データの保存期間',
              '当社は、サービス提供に必要な期間、お客様の個人情報を保存します。アカウントを削除された場合、関連するデータは30日以内に削除されます。ただし、法令により保存が義務付けられている情報については、定められた期間保存します。',
            ).animate().slideX(begin: -0.1, duration: 300.ms, delay: 1100.ms),
            _buildSection(
              context,
              '11. プライバシーポリシーの変更',
              '当社は、法令の改正やサービスの変更に伴い、本プライバシーポリシーを変更することがあります。重要な変更がある場合は、アプリ内通知やメールでお知らせします。',
            ).animate().slideX(begin: -0.1, duration: 300.ms, delay: 1200.ms),
            _buildSection(
              context,
              '12. お問い合わせ',
              '本プライバシーポリシーに関するご質問やご意見は、以下の連絡先までお問い合わせください：\n'
              'メール: privacy@journal-learning.com\n'
              '（※実際のサービス運営時は適切な連絡先に変更してください）',
            ).animate().slideX(begin: -0.1, duration: 300.ms, delay: 1300.ms),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.6,
                ),
          ),
        ],
      ),
    );
  }
}