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
  bool _notifAcara = true;
  bool _notifKeuangan = false;
  String _bahasa = 'Indonesia';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFF1F1F1) : AppTheme.onSurface;
    final subColor = isDark ? const Color(0xFF889390) : AppTheme.outline;
    final cardColor = isDark ? const Color(0xFF252828) : AppTheme.surfaceContainerLowest;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1C1C) : AppTheme.background,
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          // â”€â”€ App Bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
                height: 1,
                color: AppTheme.primary.withValues(alpha: 0.08),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // â”€â”€ Tampilan â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
                    _Divider(color: isDark ? Colors.white12 : AppTheme.outlineVariant.withValues(alpha: 0.4)),
                    _SettingsTile(
                      icon: Icons.language_rounded,
                      iconColor: AppTheme.primaryContainer,
                      title: 'Bahasa',
                      subtitle: _bahasa,
                      textColor: textColor,
                      subColor: subColor,
                      trailing: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: subColor,
                      ),
                      onTap: () => _showBahasaSheet(context, isDark, textColor, subColor),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // â”€â”€ Notifikasi â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                _SectionLabel(label: 'Notifikasi', color: subColor),
                const SizedBox(height: 10),
                _SettingsCard(
                  color: cardColor,
                  children: [
                    _SettingsTile(
                      icon: Icons.event_rounded,
                      iconColor: AppTheme.secondary,
                      title: 'Pengingat Acara',
                      subtitle: 'Notifikasi H-1 sebelum acara',
                      textColor: textColor,
                      subColor: subColor,
                      trailing: Switch(
                        value: _notifAcara,
                        activeThumbColor: AppTheme.primary,
                        onChanged: (val) async {
                          if (val) {
                            await NotificationController.requestPermission();
                          }
                          setState(() => _notifAcara = val);
                        },
                      ),
                    ),
                    _Divider(color: isDark ? Colors.white12 : AppTheme.outlineVariant.withValues(alpha: 0.4)),
                    _SettingsTile(
                      icon: Icons.account_balance_wallet_rounded,
                      iconColor: Colors.green,
                      title: 'Laporan Keuangan',
                      subtitle: 'Notifikasi transaksi baru',
                      textColor: textColor,
                      subColor: subColor,
                      trailing: Switch(
                        value: _notifKeuangan,
                        activeThumbColor: AppTheme.primary,
                        onChanged: (val) => setState(() => _notifKeuangan = val),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // â”€â”€ Preferensi Aplikasi â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
                    _Divider(color: isDark ? Colors.white12 : AppTheme.outlineVariant.withValues(alpha: 0.4)),
                    _SettingsTile(
                      icon: Icons.privacy_tip_outlined,
                      iconColor: AppTheme.tertiary,
                      title: 'Kebijakan Privasi',
                      subtitle: 'Lihat kebijakan privasi kami',
                      textColor: textColor,
                      subColor: subColor,
                      trailing: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: subColor,
                      ),
                      onTap: () {},
                    ),
                    _Divider(color: isDark ? Colors.white12 : AppTheme.outlineVariant.withValues(alpha: 0.4)),
                    _SettingsTile(
                      icon: Icons.help_outline_rounded,
                      iconColor: AppTheme.primaryContainer,
                      title: 'Bantuan & Dukungan',
                      subtitle: 'FAQ dan kontak support',
                      textColor: textColor,
                      subColor: subColor,
                      trailing: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: subColor,
                      ),
                      onTap: () {},
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // â”€â”€ Logout â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
                        borderRadius: BorderRadius.circular(50),
                      ),
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
    BuildContext context,
    bool isDark,
    Color textColor,
    Color subColor,
  ) {
    final options = ['Indonesia', 'English', 'Ø§Ù„Ø¹Ø±Ø¨ÙŠØ©'];
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF252828) : AppTheme.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
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
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Pilih Bahasa',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            ...options.map((lang) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    lang,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
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
            child: const Text('Batal'),
          ),
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

// â”€â”€â”€ Helper Widgets â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
        letterSpacing: 0.8,
      ),
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
        border: Border.all(
          color: AppTheme.outlineVariant.withValues(alpha: 0.3),
        ),
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
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: subColor),
      ),
      trailing: trailing,
    );
  }
}

class _Divider extends StatelessWidget {
  final Color color;
  const _Divider({required this.color});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 68,
      endIndent: 16,
      color: color,
    );
  }
}
