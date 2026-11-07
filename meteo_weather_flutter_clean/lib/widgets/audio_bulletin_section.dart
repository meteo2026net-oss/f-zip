import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/weather_models.dart';
import '../theme/app_theme.dart';

class AudioBulletinSection extends StatefulWidget {
  final AudioBulletinItem bulletin;

  const AudioBulletinSection({
    super.key,
    required this.bulletin,
  });

  @override
  State<AudioBulletinSection> createState() => _AudioBulletinSectionState();
}

class _AudioBulletinSectionState extends State<AudioBulletinSection> {
  final FlutterTts _tts = FlutterTts();
  bool _isPlaying = false;
  bool _ttsReady = false;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage("ar");
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.45);
      if (mounted) setState(() => _ttsReady = true);
    } catch (_) {
      if (mounted) setState(() => _ttsReady = false);
    }

    _tts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _progress = 1.0;
        });
      }
    });

    _tts.setProgressHandler((text, start, end, word) {
      if (mounted && text.isNotEmpty) {
        setState(() {
          _progress = (end / text.length).clamp(0.0, 1.0);
        });
      }
    });
  }

  Future<void> _togglePlay() async {
    if (!_ttsReady) return;
    try {
      if (_isPlaying) {
        await _tts.stop();
        if (mounted) setState(() => _isPlaying = false);
      } else {
        setState(() {
          _isPlaying = true;
          _progress = 0.0;
        });
        await _tts.speak(widget.bulletin.bulletinScriptAr);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isPlaying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("تعذر تشغيل القراءة الصوتية على هذا الجهاز.")),
        );
      }
    }
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.secondary.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.graphic_eq,
                      color: AppTheme.secondary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "قراءة نص النشرة الجوية محلياً",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                widget.bulletin.dateFormatted,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.bulletin.title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.bulletin.bulletinScriptAr,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textMuted,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              IconButton.filled(
                onPressed: _ttsReady ? _togglePlay : null,
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: const Color(0xFF0F172A),
                ),
                icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _progress,
                        backgroundColor: AppTheme.borderLight,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.bulletin.announcerName,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const Text(
                          "قراءة آلية محلية",
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
