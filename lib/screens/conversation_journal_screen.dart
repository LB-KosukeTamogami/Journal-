import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../services/gemini_service.dart';
import '../models/conversation_message.dart';
import '../services/storage_service.dart';
import 'conversation_summary_screen.dart';

class ConversationJournalScreen extends StatefulWidget {
  const ConversationJournalScreen({super.key});

  @override
  State<ConversationJournalScreen> createState() => _ConversationJournalScreenState();
}

class _ConversationJournalScreenState extends State<ConversationJournalScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  
  List<ConversationMessage> _messages = [];
  bool _isLoading = false;
  String? _conversationTopic;
  int _messageCount = 0; // Acoとユーザーのメッセージ数をカウント
  Map<int, bool> _expandedMessages = {}; // メッセージごとの展開状態を管理
  
  @override
  void initState() {
    super.initState();
    _initializeConversation();
  }
  
  void _initializeConversation() {
    // 初期メッセージを追加
    _messages.add(
      ConversationMessage(
        text: "Hello! I'm Aco! Let's have a short conversation (5 exchanges) to find topics for your journal! Don't worry about making mistakes - just relax and chat with me. If you're not sure how to say something in English, feel free to write in Japanese!\n\nこんにちは！Acoです！短い会話（5ラリー）で日記の話題を見つけましょう！間違いを気にせず、リラックスして話してくださいね。英語でなんと言えばいいかわからない時は、日本語で書いてもOKです！",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
    
    // トピック提案を追加
    _messages.add(
      ConversationMessage(
        text: "What shall we talk about today?\n\nFor example:\n• Daily activities\n• Hobbies\n• Food and cooking\n• Travel and experiences\n• Work or study\n\nFeel free to talk about anything you'd like!\n\n今日は何について話しましょうか？\n\n例）\n• 日常の活動\n• 趣味\n• 食べ物と料理\n• 旅行と経験\n• 仕事や勉強\n\nあなたが話したいことをなんでも話してください！",
        isUser: false,
        timestamp: DateTime.now(),
        suggestions: [
          "Let's talk about hobbies",
          "I want to discuss food",
          "Tell me about travel",
          "Free conversation",
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
  
  void _scrollToBottom() {
    if (_scrollController.hasClients && mounted) {
      try {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } catch (e) {
        // スクロールエラーは静かに処理
      }
    }
  }
  
  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;
    
    // ユーザーメッセージを追加
    setState(() {
      _messages.add(
        ConversationMessage(
          text: text,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _isLoading = true;
      _messageCount++;
    });
    
    _messageController.clear();
    _scrollToBottom();
    
    try {
      // Gemini APIを使用して応答を生成
      final response = await GeminiService.generateConversationResponse(
        userMessage: text,
        conversationHistory: _messages,
        topic: _conversationTopic,
      );
      
      if (mounted) {
        setState(() {
          // 5ラリー目の場合は、応答と締めくくりを統合
          if (_messageCount >= 5) {
            final combinedText = "${response.reply}\n\nGreat job practicing today! You're making wonderful progress. Let's chat again tomorrow!\n\n今日はよく頑張りましたね！素晴らしい進歩です。また明日お話ししましょう！";
            _messages.add(
              ConversationMessage(
                text: combinedText,
                isUser: false,
                timestamp: DateTime.now(),
                corrections: response.corrections,
                suggestions: response.suggestions,
              ),
            );
          } else {
            // 通常のGeminiレスポンスを追加
            _messages.add(
              ConversationMessage(
                text: response.reply,
                isUser: false,
                timestamp: DateTime.now(),
                corrections: response.corrections,
                suggestions: response.suggestions,
              ),
            );
          }
          
          _isLoading = false;
        });
        
        // 少し遅延を入れてからスクロール
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) _scrollToBottom();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(
            ConversationMessage(
              text: "Sorry, I couldn't process your message. Please try again.\n申し訳ありません。メッセージを処理できませんでした。もう一度お試しください。",
              isUser: false,
              timestamp: DateTime.now(),
              isError: true,
            ),
          );
          _isLoading = false;
        });
      }
    }
  }
  
  void _handleSuggestion(String suggestion) {
    _messageController.text = suggestion;
    // フォーカスを入力フィールドに移動
    _focusNode.requestFocus();
  }
  
  void _endConversation() {
    if (_messages.length <= 2) return; // 初期メッセージのみの場合は何もしない
    
    // 会話履歴から初期メッセージを除外
    final conversationMessages = _messages.skip(2).toList();
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConversationSummaryScreen(
          messages: conversationMessages,
          topic: _conversationTopic,
        ),
      ),
    ).then((_) {
      // 振り返り画面から戻ってきた時に会話をリセット
      setState(() {
        _messages.clear();
        _conversationTopic = null;
        _initializeConversation();
      });
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
<<<<<<< HEAD
      backgroundColor: AppTheme.backgroundSecondary,
      appBar: AppBar(
        title: Text('会話ジャーナル', style: AppTheme.headline3),
        backgroundColor: AppTheme.backgroundPrimary,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.textPrimary),
=======
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Aco', style: AppTheme.headline3),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.lightColors.onPrimary),
>>>>>>> 34d9f1ef3b42adc5bf7751b9cab7c34f309f7afe
        actions: [
          // 会話を終了ボタン（初期メッセージ以外がある場合、または5ラリー完了時）
          if (_messages.length > 2 || _messageCount >= 5) // 初期メッセージ以外がある場合のみ表示
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: OutlinedButton.icon(
                icon: Icon(Icons.check_circle_outline, size: 20),
                label: Text('会話を終了'),
                onPressed: _endConversation,
<<<<<<< HEAD
                style: AppButtonStyles.smallButton.copyWith(
=======
                style: AppButtonStyles.smallButton(context).copyWith(
>>>>>>> 34d9f1ef3b42adc5bf7751b9cab7c34f309f7afe
                  backgroundColor: MaterialStateProperty.all(Colors.transparent),
                  foregroundColor: MaterialStateProperty.all(AppTheme.primaryColor),
                  side: MaterialStateProperty.all(
                    BorderSide(color: AppTheme.primaryColor, width: 2),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // メッセージリスト
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return _buildLoadingIndicator();
                }
                
                final message = _messages[index];
                return _buildMessageBubble(message, index);
              },
            ),
          ),
          
          // 入力フィールド（5ラリー完了時は会話終了ボタンを表示）
          if (_messageCount >= 5)
            _buildConversationEndCard()
          else
            _buildInputField(),
        ],
      ),
    );
  }
  
  Widget _buildMessageBubble(ConversationMessage message, int index) {
    final isUser = message.isUser;
    
    return Padding(
      padding: EdgeInsets.only(
        bottom: 16,
        left: isUser ? 48 : 0,
        right: isUser ? 0 : 48,
      ),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
<<<<<<< HEAD
          // LINE風のレイアウト実装
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Acoの場合、左側にアイコン
              if (!isUser) ...[
=======
          // Acoの場合、アイコンのみを表示（LINE風）
          if (!isUser) ...[
            Row(
              children: [
>>>>>>> 34d9f1ef3b42adc5bf7751b9cab7c34f309f7afe
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
<<<<<<< HEAD
                        const Color(0xFFF5F5F5),
                        const Color(0xFFE8E8E8),
=======
                        Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.darkColors.surface
                          : AppTheme.lightColors.surface,
                        Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.darkColors.surfaceVariant
                          : AppTheme.lightColors.surfaceVariant,
>>>>>>> 34d9f1ef3b42adc5bf7751b9cab7c34f309f7afe
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '🐿',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
<<<<<<< HEAD
                const SizedBox(width: 8),
              ],
              // メッセージバブル
              Flexible(
                child: Column(
                  crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    // Acoの名前表示
                    if (!isUser) ...[  
                      Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 4),
                        child: Text(
                          'Aco',
                          style: AppTheme.body2.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isUser ? AppTheme.primaryColor : AppTheme.backgroundPrimary,
                        borderRadius: BorderRadius.circular(16).copyWith(
                          topLeft: !isUser ? const Radius.circular(4) : const Radius.circular(16),
                          topRight: !isUser ? const Radius.circular(16) : const Radius.circular(4),
                        ),
                        boxShadow: AppTheme.cardShadow,
                      ),
=======
              ],
            ),
            const SizedBox(height: 8),
          ],
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isUser ? AppTheme.primaryColor : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16).copyWith(
                bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
                bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
              ),
              boxShadow: AppTheme.cardShadow,
            ),
>>>>>>> 34d9f1ef3b42adc5bf7751b9cab7c34f309f7afe
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Acoのメッセージの場合、英語のみ表示（タップで日本語表示）
                          if (!isUser && message.text.contains('\n\n')) ...[
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _expandedMessages[index] = !(_expandedMessages[index] ?? false);
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 英語部分
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _getEnglishPart(message.text),
                                          style: AppTheme.body1.copyWith(
<<<<<<< HEAD
                                            color: AppTheme.textPrimary,
=======
                                            color: Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.textPrimary,
>>>>>>> 34d9f1ef3b42adc5bf7751b9cab7c34f309f7afe
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        _expandedMessages[index] ?? false
                                          ? Icons.expand_less
                                          : Icons.expand_more,
                                        size: 20,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ],
                                  ),
                                  // 日本語部分（アコーディオン）
                                  AnimatedCrossFade(
                                    firstChild: const SizedBox.shrink(),
                                    secondChild: Container(
                                      margin: const EdgeInsets.only(top: 8),
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
<<<<<<< HEAD
                                        color: AppTheme.backgroundSecondary,
=======
                                        color: Theme.of(context).colorScheme.surface,
>>>>>>> 34d9f1ef3b42adc5bf7751b9cab7c34f309f7afe
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppTheme.borderColor,
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.translate,
                                            size: 16,
                                            color: AppTheme.textSecondary,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _getJapanesePart(message.text),
                                              style: AppTheme.body2.copyWith(
                                                color: AppTheme.textSecondary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    crossFadeState: _expandedMessages[index] ?? false
                                      ? CrossFadeState.showSecond
                                      : CrossFadeState.showFirst,
                                    duration: const Duration(milliseconds: 200),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            // ユーザーのメッセージまたは通常のメッセージ
                            Text(
                              message.text,
                              style: AppTheme.body1.copyWith(
<<<<<<< HEAD
                                color: isUser ? Colors.white : AppTheme.textPrimary,
=======
                                color: isUser ? Colors.white : (Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.textPrimary),
>>>>>>> 34d9f1ef3b42adc5bf7751b9cab7c34f309f7afe
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                
                // 修正提案
                if (message.corrections != null && message.corrections!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              size: 16,
                              color: AppTheme.warning,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '修正提案',
                              style: AppTheme.caption.copyWith(
                                color: AppTheme.warning,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...message.corrections!.map((correction) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '• $correction',
                            style: AppTheme.body2.copyWith(
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        )),
                      ],
                    ),
                  ),
                ],
              ],
            ),
<<<<<<< HEAD
                    ).animate().fadeIn(duration: 300.ms).slideX(
                      begin: isUser ? 0.1 : -0.1,
                      end: 0,
                    ),
                  ],
                ),
              ),
              // ユーザーの場合、右側に余白
              if (isUser) const SizedBox(width: 40),
            ],
=======
          ).animate().fadeIn(duration: 300.ms).slideX(
            begin: isUser ? 0.1 : -0.1,
            end: 0,
>>>>>>> 34d9f1ef3b42adc5bf7751b9cab7c34f309f7afe
          ),
          
          // 提案ボタン
          if (message.suggestions != null && message.suggestions!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              alignment: isUser ? WrapAlignment.end : WrapAlignment.start,
              spacing: 8,
              runSpacing: 8,
              children: message.suggestions!.map((suggestion) {
                return InkWell(
                  onTap: () => _handleSuggestion(suggestion),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
<<<<<<< HEAD
                      color: AppTheme.backgroundPrimary,
=======
                      color: Theme.of(context).cardColor,
>>>>>>> 34d9f1ef3b42adc5bf7751b9cab7c34f309f7afe
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      suggestion,
                      style: AppTheme.caption.copyWith(
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ).animate().fadeIn(delay: 300.ms, duration: 300.ms),
          ],
        ],
      ),
    );
  }
  
  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
<<<<<<< HEAD
              color: AppTheme.backgroundPrimary,
=======
              color: Theme.of(context).cardColor,
>>>>>>> 34d9f1ef3b42adc5bf7751b9cab7c34f309f7afe
              borderRadius: BorderRadius.circular(16).copyWith(
                bottomLeft: const Radius.circular(4),
              ),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Thinking...',
                  style: AppTheme.body2.copyWith(color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.1, end: 0);
  }
  
  Widget _buildInputField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
<<<<<<< HEAD
        color: AppTheme.backgroundPrimary,
=======
        color: Theme.of(context).cardColor,
>>>>>>> 34d9f1ef3b42adc5bf7751b9cab7c34f309f7afe
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                style: AppTheme.body1,
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: _sendMessage,
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  hintStyle: AppTheme.body1.copyWith(color: AppTheme.textTertiary),
                  filled: true,
<<<<<<< HEAD
                  fillColor: AppTheme.backgroundSecondary,
=======
                  fillColor: Theme.of(context).colorScheme.surface,
>>>>>>> 34d9f1ef3b42adc5bf7751b9cab7c34f309f7afe
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
<<<<<<< HEAD
                boxShadow: AppTheme.buttonShadow,
=======
                boxShadow: AppTheme.buttonShadow(Theme.of(context).primaryColor),
>>>>>>> 34d9f1ef3b42adc5bf7751b9cab7c34f309f7afe
              ),
              child: IconButton(
                onPressed: () => _sendMessage(_messageController.text),
                icon: Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationEndCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
<<<<<<< HEAD
        color: AppTheme.backgroundPrimary,
=======
        color: Theme.of(context).cardColor,
>>>>>>> 34d9f1ef3b42adc5bf7751b9cab7c34f309f7afe
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _endConversation,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: Icon(Icons.check_circle_outline, size: 24),
            label: Text(
              '会話を終了する',
              style: AppTheme.body1.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getEnglishPart(String text) {
    // 英語と日本語の境界を見つける
    // 最後の\n\nを境界として使用
    final parts = text.split('\n\n');
    if (parts.length >= 2) {
      // 日本語が含まれる部分を除外
      final englishParts = [];
      for (int i = 0; i < parts.length; i++) {
        if (!_containsJapanese(parts[i])) {
          englishParts.add(parts[i]);
        } else {
          break; // 日本語が見つかったら停止
        }
      }
      return englishParts.join('\n\n');
    }
    return text;
  }

  String _getJapanesePart(String text) {
    // 英語と日本語の境界を見つける
    final parts = text.split('\n\n');
    if (parts.length >= 2) {
      // 日本語が含まれる部分を抽出
      final japaneseParts = [];
      bool foundJapanese = false;
      for (int i = 0; i < parts.length; i++) {
        if (_containsJapanese(parts[i])) {
          foundJapanese = true;
          japaneseParts.add(parts[i]);
        } else if (foundJapanese) {
          // 日本語セクションの後の英語も含める（混在の場合）
          japaneseParts.add(parts[i]);
        }
      }
      return japaneseParts.join('\n\n');
    }
    return '';
  }

  bool _containsJapanese(String text) {
    final japanesePattern = RegExp(r'[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF]');
    return japanesePattern.hasMatch(text);
  }
<<<<<<< HEAD
}
=======
}
>>>>>>> 34d9f1ef3b42adc5bf7751b9cab7c34f309f7afe
