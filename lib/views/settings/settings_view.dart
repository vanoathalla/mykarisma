import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../auth/login_view.dart';
import '../../helpers/auth_helper.dart';
import '../../controllers/notification_controller.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  // Notifikasi
  bool _notifUpdate = true;   // notif saat admin tambah/update data
  bool _notifAcara = true;    // pengingat H-1 otomatis
  bool _notifHariH = true;    // pengingat hari-H (diset per acara)

  // Tampilan
  String _bahasa = 'Indonesia';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final update = await NotificationController.isNotifUpdateAktif();
    final acara = await NotificationController.isNotifAcaraAktif();
    final hariH = await NotificationController.isNotifHariHAktif();
    if (mounted) {
      setState(() {
        _notifUpdate = update;
        _notifAcara = acara;
        _notifHariH = hariH;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFF1F1F1) : AppTheme.onSurface;
    final subColor = isDark ? const Color(0xFF889390) : AppTheme.outline;
    final cardColor = isDark ? const Color(0xFF252828) : AppTheme.surfaceContainerLowest;
    final divColor = isDark ? Colors.white12 : AppTheme.outlineVariant.withValues(alpha: 0.4);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: isDark ? const Color(0xFF1A1C1C) : AppTheme.background,
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          // ── App Bar ──────────────────────────────────────────────────
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: isDark
                ? const Color(0xFF1A1C1C).withValues(alpha: 0.95)
                : AppTheme.surfaceContainerLowest.withValues(alpha: 0.92),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            titleSpacing: 20,
            title: Text(
              'Pengaturan',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                  height: 1, color: AppTheme.primary.withValues(alpha: 0.08)),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // ── Tampilan ─────────────────────────────────────────
                _SectionLabel(label: 'Tampilan', color: subColor),
                const SizedBox(height: 10),
                _SettingsCard(
                  color: cardColor,
                  children: [
                    ValueListenableBuilder<ThemeMode>(
                      valueListenable: themeNotifier,
                      builder: (context, mode, _) {
                        return _SettingsTile(
                          icon: Icons.dark_mode_rounded,
                          iconColor: AppTheme.tertiary,
                          title: 'Mode Gelap',
                          subtitle: mode == ThemeMode.dark ? 'Aktif' : 'Nonaktif',
                          textColor: textColor,
                          subColor: subColor,
                          trailing: Switch(
                            value: mode == ThemeMode.dark,
                            activeThumbColor: AppTheme.primary,
                            onChanged: (val) {
                              themeNotifier.value =
                                  val ? ThemeMode.dark : ThemeMode.light;
                            },
                          ),
                        );
                      },
                    ),
                    _Divider(color: divColor),
                    _SettingsTile(
                      icon: Icons.language_rounded,
                      iconColor: AppTheme.primaryContainer,
                      title: 'Bahasa',
                      subtitle: _bahasa,
                      textColor: textColor,
                      subColor: subColor,
                      trailing: Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: subColor),
                      onTap: () =>
                          _showBahasaSheet(context, isDark, textColor, subColor),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Notifikasi ────────────────────────────────────────
                _SectionLabel(label: 'Notifikasi', color: subColor),
                const SizedBox(height: 6),
                // Info box
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: isDark ? 0.12 : 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: AppTheme.primary, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Notifikasi mengikuti pengaturan suara HP kamu. '
                          'Jika HP dalam mode senyap, notifikasi tidak berbunyi.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFF84D5C5)
                                : AppTheme.primaryContainer,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _SettingsCard(
                  color: cardColor,
                  children: [
                    // Notif update data
                    _SettingsTile(
                      icon: Icons.notifications_active_rounded,
                      iconColor: AppTheme.secondaryContainer,
                      title: 'Update Data',
                      subtitle: 'Notif saat admin tambah/perbarui acara, keuangan, atau catatan',
                      textColor: textColor,
                      subColor: subColor,
                      trailing: Switch(
                        value: _notifUpdate,
                        activeThumbColor: AppTheme.primary,
                        onChanged: (val) async {
                          if (val) await NotificationController.requestPermission();
                          await NotificationController.setNotifUpdate(val);
                          setState(() => _notifUpdate = val);
                        },
                      ),
                    ),
                    _Divider(color: divColor),
                    // Pengingat H-1
                    _SettingsTile(
                      icon: Icons.event_rounded,
                      iconColor: AppTheme.secondary,
                      title: 'Pengingat H-1 Acara',
                      subtitle: 'Notif otomatis jam 08:00 sehari sebelum acara',
                      textColor: textColor,
                      subColor: subColor,
                      trailing: Switch(
                        value: _notifAcara,
                        activeThumbColor: AppTheme.primary,
                        onChanged: (val) async {
                          if (val) await NotificationController.requestPermission();
                          await NotificationController.setNotifAcara(val);
                          setState(() => _notifAcara = val);
                        },
                      ),
                    ),
                    _Divider(color: divColor),
                    // Pengingat hari-H
                    _SettingsTile(
                      icon: Icons.alarm_rounded,
                      iconColor: Colors.orange,
                      title: 'Pengingat Hari-H',
                      subtitle: 'Aktifkan agar bisa set pengingat tepat saat acara berlangsung (dari halaman Acara)',
                      textColor: textColor,
                      subColor: subColor,
                      trailing: Switch(
                        value: _notifHariH,
                        activeThumbColor: AppTheme.primary,
                        onChanged: (val) async {
                          if (val) await NotificationController.requestPermission();
                          await NotificationController.setNotifHariH(val);
                          setState(() => _notifHariH = val);
                        },
                      ),
                    ),
                  ],
                ),

                // Panduan pengingat hari-H
                if (_notifHariH) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: isDark ? 0.12 : 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.20)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.tips_and_updates_rounded,
                            color: Colors.orange, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Cara set pengingat hari-H: Buka menu Acara → '
                            'tap ikon 🔔 di samping acara yang ingin diingatkan.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.orange.shade200
                                  : Colors.orange.shade800,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // ── Preferensi Aplikasi ───────────────────────────────
                _SectionLabel(label: 'Preferensi Aplikasi', color: subColor),
                const SizedBox(height: 10),
                _SettingsCard(
                  color: cardColor,
                  children: [
                    _SettingsTile(
                      icon: Icons.info_outline_rounded,
                      iconColor: AppTheme.outline,
                      title: 'Versi Aplikasi',
                      subtitle: 'MyKarisma v1.0.0',
                      textColor: textColor,
                      subColor: subColor,
                    ),
                    _Divider(color: divColor),
                    _SettingsTile(
                      icon: Icons.privacy_tip_outlined,
                      iconColor: AppTheme.tertiary,
                      title: 'Kebijakan Privasi',
                      subtitle: 'Lihat kebijakan privasi kami',
                      textColor: textColor,
                      subColor: subColor,
                      trailing: Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: subColor),
                      onTap: () {},
                    ),
                    _Divider(color: divColor),
                    _SettingsTile(
                      icon: Icons.help_outline_rounded,
                      iconColor: AppTheme.primaryContainer,
                      title: 'Bantuan & Dukungan',
                      subtitle: 'FAQ dan kontak support',
                      textColor: textColor,
                      subColor: subColor,
                      trailing: Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: subColor),
                      onTap: () {},
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // ── Logout ────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () => _doLogout(context),
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text(
                      'Keluar dari Akun',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50)),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _showBahasaSheet(
      BuildContext context, bool isDark, Color textColor, Color subColor) {
    final options = ['Indonesia', 'English', 'العربية'];
    showModalBottomSheet(
      context: context,
      backgroundColor:
          isDark ? const Color(0xFF252828) : AppTheme.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppTheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text('Pilih Bahasa',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textColor)),
            const SizedBox(height: 16),
            ...options.map((lang) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(lang,
                      style: TextStyle(
                          fontWeight: FontWeight.w600, color: textColor)),
                  trailing: _bahasa == lang
                      ? const Icon(Icons.check_circle_rounded,
                          color: AppTheme.primary)
                      : null,
                  onTap: () {
                    setState(() => _bahasa = lang);
                    Navigator.pop(ctx);
                  },
                )),
          ],
        ),
      ),
    );
  }

  Future<void> _doLogout(BuildContext context) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (konfirmasi != true) return;
    await AuthHelper.clearSession();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginView()),
        (route) => false,
      );
    }
  }
}

// ─── Helper Widgets ───────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.8),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  final Color color;
  const _SettingsCard({required this.children, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Color textColor;
  final Color subColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.textColor,
    required this.subColor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title,
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
      subtitle: Text(subtitle,
          style: TextStyle(fontSize: 12, color: subColor)),
      trailing: trailing,
    );
  }
}

class _Divider extends StatelessWidget {
  final Color color;
  const _Divider({required this.color});

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, indent: 68, endIndent: 16, color: color);
  }
}
