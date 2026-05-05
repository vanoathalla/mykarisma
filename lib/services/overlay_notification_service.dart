import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

/// Service untuk menampilkan notifikasi pop-up dari atas layar — iOS 26 style.
class OverlayNotificationService {
  static final OverlayNotificationService _instance =
      OverlayNotificationService._();
  factory OverlayNotificationService() => _instance;
  OverlayNotificationService._();

  OverlayEntry? _entry;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  void show({
    required String title,
    required String body,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onTap,
  }) {
    _dismiss();
    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) return;

    _entry = OverlayEntry(
      builder: (_) => _NotifPopup(
        title: title,
        body: body,
        duration: duration,
        onTap: onTap,
        onDismiss: _dismiss,
      ),
    );
    overlay.insert(_entry!);
  }

  void _dismiss() {
    _entry?.remove();
    _entry = null;
  }
}

class _NotifPopup extends StatefulWidget {
  final String title;
  final String body;
  final Duration duration;
  final VoidCallback? onTap;
  final VoidCallback onDismiss;

  const _NotifPopup({
    required this.title,
    required this.body,
    required this.duration,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<_NotifPopup> createState() => _NotifPopupState();
}

class _NotifPopupState extends State<_NotifPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.5)),
    );

    _ctrl.forward();

    Future.delayed(widget.duration, () {
      if (mounted) _animateOut();
    });
  }

  Future<void> _animateOut() async {
    if (!mounted) return;
    await _ctrl.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: SafeArea(
            child: GestureDetector(
              onTap: () { widget.onTap?.call(); _animateOut(); },
              onVerticalDragEnd: (d) {
                if ((d.primaryVelocity ?? 0) < -80) _animateOut();
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: BackdropFilter(
                    // iOS 26 style — blur kuat + tint putih/gelap
                    filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      decoration: BoxDecoration(
                        // Putih semi-transparan seperti notification iOS
                        color: Colors.white.withValues(alpha: 0.82),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.60),
                          width: 0.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 30,
                            spreadRadius: 0,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // App icon container
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1565C0),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.notifications_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Konten teks
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // App name kecil di atas
                                const Text(
                                  'KARISMA',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1565C0),
                                    letterSpacing: 0.5,
                                    height: 1.0,
                                    // Tidak ada decoration — tidak ada garis bawah
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                // Judul
                                Text(
                                  widget.title,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1A1A1A),
                                    height: 1.2,
                                    decoration: TextDecoration.none,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (widget.body.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.body,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xFF555555),
                                      height: 1.3,
                                      decoration: TextDecoration.none,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Close button
                          GestureDetector(
                            onTap: _animateOut,
                            child: Container(
                              width: 26, height: 26,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 14,
                                color: Color(0xFF555555),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
