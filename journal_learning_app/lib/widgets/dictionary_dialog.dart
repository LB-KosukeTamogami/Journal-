import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../services/dictionary_service.dart';
import '../services/tts_service.dart';
import '../widgets/text_to_speech_button.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';

class DictionaryDialog extends StatefulWidget {
  final String word;

  const DictionaryDialog({
    super.key,
    required this.word,
  });

  @override
  State<DictionaryDialog> createState() => _DictionaryDialogState();
}

class _DictionaryDialogState extends State<DictionaryDialog> {
  bool _isLoading = true;
  DictionaryEntry? _dictionaryEntry;
  List<DictionaryEntry>? _additionalMeanings;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlayingAudio = false;

  @override
  void initState() {
    super.initState();
    _loadDictionaryData();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadDictionaryData() async {
    final result = await DictionaryService.lookupWord(widget.word);
    final additionalMeanings = await DictionaryService.lookupMultipleMeanings(widget.word);
    
    if (mounted) {
      setState(() {
        _dictionaryEntry = result;
        _additionalMeanings = additionalMeanings.length > 1 ? additionalMeanings.sublist(1) : null;
        _isLoading = false;
      });
    }
  }

  Future<void> _playAudio() async {
    if (_dictionaryEntry?.audioUrl == null || _dictionaryEntry!.audioUrl!.isEmpty) {
      // 音声URLがない場合はTTSを使用
      await TTSService().speak(_dictionaryEntry?.word ?? widget.word);
      return;
    }

    setState(() {
      _isPlayingAudio = true;
    });

    try {
      await _audioPlayer.play(UrlSource(_dictionaryEntry!.audioUrl!));
      _audioPlayer.onPlayerComplete.listen((_) {
        if (mounted) {
          setState(() {
            _isPlayingAudio = false;
          });
        }
      });
    } catch (e) {
      // エラーが発生した場合はTTSにフォールバック
      await TTSService().speak(_dictionaryEntry?.word ?? widget.word);
      if (mounted) {
        setState(() {
          _isPlayingAudio = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        decoration: BoxDecoration(
          color: AppTheme.backgroundPrimary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ヘッダー
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.05),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.menu_book,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '辞書',
                      style: AppTheme.headline3.copyWith(
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            // コンテンツ
            Flexible(
              child: _isLoading
                  ? Container(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '辞書を検索中...',
                              style: AppTheme.body2.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _dictionaryEntry == null
                      ? Container(
                          padding: const EdgeInsets.all(40),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 48,
                                  color: AppTheme.textTertiary,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '"${widget.word}" の定義が見つかりませんでした',
                                  style: AppTheme.body1.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 単語と発音
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _dictionaryEntry!.word,
                                          style: AppTheme.headline1.copyWith(
                                            color: AppTheme.primaryColor,
                                            fontSize: 32,
                                          ),
                                        ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.1, end: 0),
                                        if (_dictionaryEntry!.phonetics != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            _dictionaryEntry!.phonetics!,
                                            style: AppTheme.body1.copyWith(
                                              color: AppTheme.textSecondary,
                                              fontSize: 18,
                                            ),
                                          ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
                                        ],
                                      ],
                                    ),
                                  ),
                                  // 音声再生ボタン
                                  IconButton(
                                    onPressed: _isPlayingAudio ? null : _playAudio,
                                    icon: Icon(
                                      _isPlayingAudio ? Icons.stop : Icons.volume_up,
                                      color: _isPlayingAudio 
                                          ? AppTheme.textTertiary 
                                          : AppTheme.primaryColor,
                                      size: 28,
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // 品詞
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.info.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _dictionaryEntry!.partOfSpeech,
                                  style: AppTheme.body2.copyWith(
                                    color: AppTheme.info,
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ).animate().fadeIn(delay: 200.ms, duration: 300.ms).scale(begin: const Offset(0.8, 0.8)),
                              
                              const SizedBox(height: 16),
                              
                              // 定義
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.backgroundSecondary,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppTheme.borderColor,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.description,
                                          size: 18,
                                          color: AppTheme.textSecondary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '定義',
                                          style: AppTheme.body2.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _dictionaryEntry!.definition,
                                      style: AppTheme.body1.copyWith(
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ).animate().fadeIn(delay: 300.ms, duration: 300.ms).slideY(begin: 0.1, end: 0),
                              
                              // 例文
                              if (_dictionaryEntry!.examples != null && _dictionaryEntry!.examples!.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.success.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppTheme.success.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.format_quote,
                                            size: 18,
                                            color: AppTheme.success,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '例文',
                                            style: AppTheme.body2.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.success,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _dictionaryEntry!.examples!.first,
                                        style: AppTheme.body2.copyWith(
                                          fontStyle: FontStyle.italic,
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ).animate().fadeIn(delay: 400.ms, duration: 300.ms).slideY(begin: 0.1, end: 0),
                              ],
                              
                              // 同義語
                              if (_dictionaryEntry!.synonyms != null && _dictionaryEntry!.synonyms!.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '同義語',
                                      style: AppTheme.body2.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: _dictionaryEntry!.synonyms!
                                          .take(5)
                                          .map((synonym) => Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(16),
                                                  border: Border.all(
                                                    color: AppTheme.primaryColor.withOpacity(0.3),
                                                  ),
                                                ),
                                                child: Text(
                                                  synonym,
                                                  style: AppTheme.caption.copyWith(
                                                    color: AppTheme.primaryColor,
                                                  ),
                                                ),
                                              ))
                                          .toList(),
                                    ),
                                  ],
                                ).animate().fadeIn(delay: 500.ms, duration: 300.ms),
                              ],
                              
                              // 追加の意味
                              if (_additionalMeanings != null && _additionalMeanings!.isNotEmpty) ...[
                                const SizedBox(height: 24),
                                Text(
                                  'その他の意味',
                                  style: AppTheme.body1.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ..._additionalMeanings!.map((entry) => Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.backgroundTertiary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry.partOfSpeech,
                                        style: AppTheme.caption.copyWith(
                                          color: AppTheme.info,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        entry.definition,
                                        style: AppTheme.body2,
                                      ),
                                    ],
                                  ),
                                )).toList(),
                              ],
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 200.ms).scale(begin: const Offset(0.95, 0.95)),
    );
  }
}