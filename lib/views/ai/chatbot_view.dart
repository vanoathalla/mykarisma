import 'package:flutter/material.dart';
import '../../controllers/ai_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';

class ChatbotView extends StatefulWidget {
  const ChatbotView({super.key});

  @override
  State<ChatbotView> createState() => _ChatbotViewState();
}

class _ChatbotViewState extends State<ChatbotView> {
  final List<Map<String, dynamic>> _messages = [];
  bool _loading = false;
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final AIController _aiCtrl = AIController();

  @override
  void initState() {
    super.initState();
    _messages.add({
      'role': 'ai',
      'text': 'Assalamu\'alaikum! Saya asisten digital KARISMA. Ada yang bisa saya bantu?',
    });
  }

  @override
  void dispose() {
    _aiCtrl.clearHistory();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
      _messages.add({
        'role': 'ai',
        'text': 'Assalamu\'alaikum! Saya asisten digital KARISMA. Ada yang bisa saya bantu?',
      });
    });
    _aiCtrl.clearHistory();
  }

  Future<void> _kirimPesan() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _loading) return;

    _inputCtrl.clear();

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _loading = true;
    });

    _scrollToBottom();

    final response = await _aiCtrl.sendMessage(text);

    if (mounted) {
      setState(() {
        _messages.add({'role': 'ai', 'text': response});
        _loading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          // ── App Bar ──────────────────────────────────────────────────
          Container(
            color: AppTheme.surfaceContainerLowest.withValues(alpha: 0.92),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: AppTheme.onSurface, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppTheme.primary, AppTheme.tertiary],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.smart_toy_rounded,
                              color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Karisma AI',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.onSurface,
                                ),
                              ),
                              Text(
                                'Asisten Digital KARISMA',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.outline,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded,
                              color: AppTheme.outline),
                          onPressed: _clearChat,
                          tooltip: 'Hapus riwayat',
                        ),
                      ],
                    ),
                  ),
                  Container(
                      height: 1, color: AppTheme.primary.withValues(alpha: 0.08)),
                ],
              ),
            ),
          ),

          // ── Messages ─────────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: _messages.length + (_loading ? 1 : 0),
              itemBuilder: (ctx, i) {
                if (_loading && i == _messages.length) {
                  return _buildTypingBubble();
                }
                final msg = _messages[i];
                final isUser = msg['role'] == 'user';
                return _buildChatBubble(msg['text'] as String, isUser);
              },
            ),
          ),

          // ── Input Area ───────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              border: Border(
                top: BorderSide(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputCtrl,
                      decoration: InputDecoration(
                        hintText: 'Ketik pesan...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: AppTheme.surfaceContainerLow,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _kirimPesan(),
                      textInputAction: TextInputAction.send,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _kirimPesan,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primary, AppTheme.tertiary],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.send_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          gradient: isUser
              ? const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryContainer],
                )
              : null,
          color: isUser ? null : AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : AppTheme.onSurface,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLow,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TypingIndicator(),
            const SizedBox(width: 8),
            Text(
              'Mengetik...',
              style: TextStyle(
                color: AppTheme.outline,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
