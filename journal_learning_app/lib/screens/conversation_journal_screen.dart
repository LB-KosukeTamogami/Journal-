import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../services/gemini_service.dart';
import '../models/conversation_message.dart';
import '../services/storage_service.dart';

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
  
  @override
  void initState() {
    super.initState();
    _initializeConversation();
  }
  
  void _initializeConversation() {
    // 初期メッセージを追加
    _messages.add(
      ConversationMessage(
        text: "Hello! I'm Aco, your English conversation partner. What would you like to talk about today? 😊\n\nこんにちは！私はAcoです。英会話の練習相手として一緒に学習しましょう。今日は何について話しましょうか？",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
    
    // トピック提案を追加
    _messages.add(
      ConversationMessage(
        text: "Here are some topics we can discuss:\n• Daily activities (日常の活動)\n• Hobbies (趣味)\n• Food and cooking (食べ物と料理)\n• Travel experiences (旅行の経験)\n• Work or study (仕事や勉強)\n\nOr we can talk about anything you'd like!",
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
          _messages.add(
            ConversationMessage(
              text: response.reply,
              isUser: false,
              timestamp: DateTime.now(),
              corrections: response.corrections,
              suggestions: response.suggestions,
            ),
          );
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
    _sendMessage(suggestion);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundSecondary,
      appBar: AppBar(
        title: Text('Conversation Journal', style: AppTheme.headline3),
        backgroundColor: AppTheme.backgroundPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppTheme.textPrimary),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppTheme.backgroundPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Text('新しい会話を始めますか？', style: AppTheme.headline3),
                  content: Text(
                    '現在の会話履歴がクリアされます。',
                    style: AppTheme.body2,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('キャンセル', style: AppTheme.body2),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          _messages.clear();
                          _conversationTopic = null;
                          _initializeConversation();
                        });
                      },
                      child: Text(
                        '新しい会話',
                        style: AppTheme.body2.copyWith(color: AppTheme.primaryColor),
                      ),
                    ),
                  ],
                ),
              );
            },
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
          
          // 入力フィールド
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
          // Acoの場合、アイコンと名前を表示
          if (!isUser) ...[
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFF5F5F5),
                        const Color(0xFFE8E8E8),
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
                const SizedBox(width: 8),
                Text(
                  'Aco',
                  style: AppTheme.body2.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isUser ? AppTheme.primaryColor : AppTheme.backgroundPrimary,
              borderRadius: BorderRadius.circular(16).copyWith(
                bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
                bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
              ),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.text,
                  style: AppTheme.body1.copyWith(
                    color: isUser ? Colors.white : AppTheme.textPrimary,
                  ),
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
          ).animate().fadeIn(duration: 300.ms).slideX(
            begin: isUser ? 0.1 : -0.1,
            end: 0,
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
                      color: AppTheme.backgroundPrimary,
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
              color: AppTheme.backgroundPrimary,
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
        color: AppTheme.backgroundPrimary,
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
                  fillColor: AppTheme.backgroundSecondary,
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
                boxShadow: AppTheme.buttonShadow,
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
}