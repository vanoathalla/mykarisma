import 'dart:ui';
import 'package:flutter/material.dart';
import '../../controllers/ai_controller.dart';
import '../../controllers/acara_controller.dart';
import '../../controllers/catatan_controller.dart';
import '../../controllers/keuangan_controller.dart';
import '../../controllers/member_controller.dart';
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
  bool _loadingContext = true;
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final AIController _aiCtrl = AIController();
  final AcaraController _acaraCtrl = AcaraController();
  final KeuanganController _keuanganCtrl = KeuanganController();
  final CatatanController _catatanCtrl = CatatanController();
  final MemberController _memberCtrl = MemberController();

  @override
  void initState() {
    super.initState();
    _messages.add({'role': 'ai', 'text': 'Assalamu\'alaikum! Saya Karisma AI. Sedang memuat data aplikasi...'});
    _loadAndInjectContext();
  }

  Future<void> _loadAndInjectContext() async {
    setState(() => _loadingContext = true);
    try {
      final results = await Future.wait([
        _acaraCtrl.fetchAcara(),
        _keuanganCtrl.fetchKeuangan(),
        _catatanCtrl.fetchCatatan(),
        _memberCtrl.fetchMember(),
      ]);
      final acara = results[0] as List;
      final keuanganData = results[1] as Map<String, dynamic>;
      final catatan = results[2] as List;
      final members = results[3] as List;
      _aiCtrl.injectAppContext(
        acara: acara.cast(),
        keuangan: (keuanganData['data'] as List? ?? []).cast(),
        catatan: catatan.cast(),
        members: members.cast(),
        saldo: (keuanganData['saldo'] as int?) ?? 0,
      );
      if (mounted) {
        setState(() {
          _loadingContext = false;
          if (_messages.isNotEmpty && _messages.first['role'] == 'ai') {
            _messages[0] = {
              'role': 'ai',
              'text': 'Assalamu\'alaikum! Saya Karisma AI.\n\nData dimuat: ${acara.length} agenda, ${members.length} anggota, ${catatan.length} catatan.\n\nSilakan tanya apa saja!',
            };
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingContext = false);
    }
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
      _messages.add({'role': 'ai', 'text': 'Chat direset. Silakan tanya apa saja!'});
    });
    _aiCtrl.clearChatOnly();
  }

  Future<void> _kirimPesan() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _loading || _loadingContext) return;
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
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A1C1C) : AppTheme.background;
    final inputBg = isDark ? const Color(0xFF252828) : AppTheme.surfaceContainerLow;
    final barBg = isDark ? const Color(0xFF1A1C1C).withValues(alpha: 0.95) : AppTheme.surfaceContainerLowest;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: bg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 20),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              color: barBg,
              child: SafeArea(
                bottom: false,
                child: Column(children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
                    child: Row(children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios_new_rounded,
                            color: isDark ? const Color(0xFFF1F1F1) : AppTheme.onSurface, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.tertiary]),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Karisma AI',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                                  color: isDark ? const Color(0xFFF1F1F1) : AppTheme.onSurface)),
                          Row(children: [
                            _PulsingDot(color: _loadingContext ? Colors.orange : Colors.green),
                            const SizedBox(width: 4),
                            Text(_loadingContext ? 'Memuat data...' : 'Terhubung',
                                style: TextStyle(fontSize: 11,
                                    color: _loadingContext ? Colors.orange : Colors.green)),
                          ]),
                        ]),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, color: AppTheme.primary, size: 20),
                        onPressed: _loadingContext ? null : () async {
                          await _loadAndInjectContext();
                          if (mounted) {
                            setState(() => _messages.add({'role': 'ai', 'text': 'Data diperbarui!'}));
                            _scrollToBottom();
                          }
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline_rounded,
                            color: isDark ? const Color(0xFF889390) : AppTheme.outline),
                        onPressed: _clearChat,
                      ),
                    ]),
                  ),
                  Container(height: 1, color: AppTheme.primary.withValues(alpha: 0.08)),
                ]),
              ),
            ),
          ),
        ),
      ),
      body: Column(children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollCtrl,
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            itemCount: _messages.length + (_loading ? 1 : 0),
            itemBuilder: (ctx, i) {
              if (_loading && i == _messages.length) return _buildTypingBubble(isDark);
              final msg = _messages[i];
              return _buildChatBubble(msg['text'] as String, msg['role'] == 'user', isDark);
            },
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: barBg,
            border: Border(top: BorderSide(color: AppTheme.primary.withValues(alpha: 0.08))),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _inputCtrl,
                    enabled: !_loadingContext,
                    style: TextStyle(color: isDark ? const Color(0xFFF1F1F1) : AppTheme.onSurface),
                    decoration: InputDecoration(
                      hintText: _loadingContext ? 'Memuat data...' : 'Tanya tentang agenda, keuangan...',
                      hintStyle: TextStyle(color: isDark ? const Color(0xFF889390) : AppTheme.outline, fontSize: 13),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: inputBg,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                    onSubmitted: (_) => _kirimPesan(),
                    textInputAction: TextInputAction.send,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _loadingContext ? null : _kirimPesan,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      gradient: _loadingContext ? null : const LinearGradient(colors: [AppTheme.primary, AppTheme.tertiary]),
                      color: _loadingContext ? AppTheme.outline : null,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildChatBubble(String text, bool isUser, bool isDark) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          gradient: isUser ? const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryContainer]) : null,
          color: isUser ? null : (isDark ? const Color(0xFF252828) : AppTheme.surfaceContainerLow),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18), topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4), bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          border: isUser ? null : Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.06) : AppTheme.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: Text(text,
            style: TextStyle(
                color: isUser ? Colors.white : (isDark ? const Color(0xFFF1F1F1) : AppTheme.onSurface),
                fontSize: 14, height: 1.5)),
      ),
    );
  }

  Widget _buildTypingBubble(bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252828) : AppTheme.surfaceContainerLow,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18), topRight: Radius.circular(18),
            bottomRight: Radius.circular(18), bottomLeft: Radius.circular(4),
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const TypingIndicator(),
          const SizedBox(width: 8),
          Text('Mengetik...',
              style: TextStyle(
                  color: isDark ? const Color(0xFF889390) : AppTheme.outline,
                  fontSize: 12, fontStyle: FontStyle.italic)),
        ]),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) => Container(
        width: 7, height: 7,
        decoration: BoxDecoration(color: widget.color.withValues(alpha: _anim.value), shape: BoxShape.circle),
      ),
    );
  }
}
