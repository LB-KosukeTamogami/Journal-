import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  String _currentPlan = 'ライトプラン';
  bool _notificationEnabled = true;
  String _notificationTime = '21:00';
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundSecondary,
      appBar: AppBar(
        title: Text('My Page', style: AppTheme.headline3),
        backgroundColor: AppTheme.backgroundPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // プロフィールセクション
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 400),
              child: AppCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ユーザー名',
                      style: AppTheme.headline2,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'user@example.com',
                      style: AppTheme.body2.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.primaryBlue.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '学習レベル: 中級',
                        style: AppTheme.body2.copyWith(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // プラン情報
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.star,
                      color: Colors.amber[700],
                    ),
                    title: const Text('現在のプラン'),
                    subtitle: Text(_currentPlan),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      _showPlanDialog();
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.book,
                      color: Colors.green,
                    ),
                    title: const Text('製本申込履歴'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: 製本申込履歴画面への遷移
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            // 設定セクション
            Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      '通知設定',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  SwitchListTile(
                    title: const Text('通知を有効にする'),
                    value: _notificationEnabled,
                    onChanged: (value) {
                      setState(() {
                        _notificationEnabled = value;
                      });
                    },
                  ),
                  ListTile(
                    title: const Text('通知時刻'),
                    subtitle: Text(_notificationTime),
                    trailing: const Icon(Icons.chevron_right),
                    enabled: _notificationEnabled,
                    onTap: _notificationEnabled ? () {
                      _showTimePickerDialog();
                    } : null,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            // その他
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: const Text('ヘルプ'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: const Text('プライバシーポリシー'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: const Text('利用規約'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text(
                      'ログアウト',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () {
                      _showLogoutDialog();
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // バージョン情報
            Text(
              'Version 1.0.0',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
  
  void _showPlanDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'プランを選択',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _PlanOption(
              title: '無料プラン',
              price: '¥0',
              features: const ['日記記録', '翻訳機能', '広告あり'],
              isSelected: _currentPlan == '無料プラン',
              onTap: () {
                setState(() {
                  _currentPlan = '無料プラン';
                });
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 12),
            _PlanOption(
              title: 'ライトプラン',
              price: '¥980/月',
              features: const ['AI添削', '暗記カード', '広告なし'],
              isSelected: _currentPlan == 'ライトプラン',
              isRecommended: true,
              onTap: () {
                setState(() {
                  _currentPlan = 'ライトプラン';
                });
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 12),
            _PlanOption(
              title: 'プレミアムプラン',
              price: '¥2,980/月',
              features: const ['TTS機能', 'シャドウイング', '製本申込可能', '全機能利用可能'],
              isSelected: _currentPlan == 'プレミアムプラン',
              onTap: () {
                setState(() {
                  _currentPlan = 'プレミアムプラン';
                });
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  void _showTimePickerDialog() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(_notificationTime.split(':')[0]),
        minute: int.parse(_notificationTime.split(':')[1]),
      ),
    );
    if (picked != null) {
      setState(() {
        _notificationTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }
  
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ログアウト'),
        content: const Text('本当にログアウトしますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: ログアウト処理
            },
            child: const Text(
              'ログアウト',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanOption extends StatelessWidget {
  final String title;
  final String price;
  final List<String> features;
  final bool isSelected;
  final bool isRecommended;
  final VoidCallback onTap;

  const _PlanOption({
    required this.title,
    required this.price,
    required this.features,
    required this.isSelected,
    this.isRecommended = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected 
              ? Theme.of(context).primaryColor 
              : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          color: isSelected 
            ? Theme.of(context).primaryColor.withOpacity(0.05)
            : Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isRecommended)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'おすすめ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              price,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            ...features.map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.check,
                    size: 16,
                    color: Colors.green[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    feature,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.backgroundPrimary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: AppTheme.borderColor,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}