import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../helpers/auth_helper.dart';
import '../../helpers/database_helper.dart';
import '../../theme/app_theme.dart';
import 'login_view.dart';
import '../../widgets/karisma_logo.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _namaCtrl = TextEditingController();
  final _panggilanCtrl = TextEditingController();
  final _noHpCtrl = TextEditingController();
  final _rtCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _konfirmasiCtrl = TextEditingController();

  String? _gender;
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureKonfirmasi = true;
  int _usia = 17;

  static const List<String> _genderList = ['Laki-laki', 'Perempuan'];

  @override
  void dispose() {
    _namaCtrl.dispose();
    _panggilanCtrl.dispose();
    _noHpCtrl.dispose();
    _rtCtrl.dispose();
    _passwordCtrl.dispose();
    _konfirmasiCtrl.dispose();
    super.dispose();
  }

  void _pilihUsia() {
    int tempUsia = _usia;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => SizedBox(
          height: 300,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppTheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              const Text('Pilih Usia',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              Expanded(
                child: ListWheelScrollView.useDelegate(
                  itemExtent: 48,
                  perspective: 0.003,
                  diameterRatio: 1.5,
                  physics: const FixedExtentScrollPhysics(),
                  controller:
                      FixedExtentScrollController(initialItem: tempUsia - 10),
                  onSelectedItemChanged: (i) => setS(() => tempUsia = i + 10),
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: 90,
                    builder: (ctx, i) => Center(
                      child: Text(
                        '${i + 10} tahun',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: tempUsia == i + 10
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: tempUsia == i + 10
                              ? AppTheme.primary
                              : AppTheme.outline,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() => _usia = tempUsia);
                      Navigator.pop(ctx);
                    },
                    child: const Text('Pilih'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _daftar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);

    try {
      final passwordHash = AuthHelper.hashPassword(_passwordCtrl.text.trim());
      final data = {
        'nama': _namaCtrl.text.trim(),
        'nama_panggilan': _panggilanCtrl.text.trim(),
        'no_hp': _noHpCtrl.text.trim(),
        'role': 'member',
        'rt': _rtCtrl.text.trim(),
        'password_hash': passwordHash,
      };

      final db = await DatabaseHelper.instance.database;
      await db.insert('member', data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pendaftaran berhasil! Silakan masuk.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginView()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mendaftar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.primary, AppTheme.tertiary],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    const SizedBox(height: 40),

                    // Logo KARISMA
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: const KarismaLogo(size: 110),
                    ),
                    const SizedBox(height: 8),

                    const Spacer(),

                    // '"-'"- Register Card '"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-'"-
                    Container(
                      margin: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 40,
                            offset: const Offset(0, 20),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Daftar Anggota',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Isi data diri Anda dengan benar',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.outline,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Nama Lengkap
                            TextFormField(
                              controller: _namaCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Nama Lengkap',
                                prefixIcon: Icon(Icons.person_outline_rounded,
                                    color: AppTheme.primary),
                              ),
                              textCapitalization: TextCapitalization.words,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Nama lengkap wajib diisi';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            // Nama Panggilan
                            TextFormField(
                              controller: _panggilanCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Nama Panggilan / Username',
                                prefixIcon: Icon(Icons.badge_outlined,
                                    color: AppTheme.primary),
                              ),
                              textCapitalization: TextCapitalization.none,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[a-zA-Z0-9_]')),
                              ],
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Nama panggilan wajib diisi';
                                }
                                if (v.trim().length < 3) {
                                  return 'Minimal 3 karakter';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            // Usia '-" BottomSheet picker
                            GestureDetector(
                              onTap: _pilihUsia,
                              child: AbsorbPointer(
                                child: TextFormField(
                                  controller: TextEditingController(
                                      text: '$_usia tahun'),
                                  decoration: const InputDecoration(
                                    labelText: 'Usia',
                                    prefixIcon: Icon(Icons.cake_outlined,
                                        color: AppTheme.primary),
                                    suffixIcon: Icon(Icons.expand_more_rounded,
                                        color: AppTheme.outline),
                                  ),
                                  validator: (_) => _usia < 10 || _usia > 99
                                      ? 'Usia tidak valid'
                                      : null,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Gender
                            DropdownButtonFormField<String>(
                              value: _gender,
                              decoration: const InputDecoration(
                                labelText: 'Jenis Kelamin',
                                prefixIcon: Icon(Icons.wc_rounded,
                                    color: AppTheme.primary),
                              ),
                              hint: const Text('Pilih jenis kelamin'),
                              items: _genderList
                                  .map((g) => DropdownMenuItem(
                                      value: g, child: Text(g)))
                                  .toList(),
                              validator: (v) =>
                                  v == null ? 'Pilih jenis kelamin' : null,
                              onChanged: (v) => setState(() => _gender = v),
                            ),
                            const SizedBox(height: 12),

                            // No HP
                            TextFormField(
                              controller: _noHpCtrl,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: const InputDecoration(
                                labelText: 'No HP',
                                prefixIcon: Icon(Icons.phone_outlined,
                                    color: AppTheme.primary),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'No HP wajib diisi';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            // RT
                            TextFormField(
                              controller: _rtCtrl,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: const InputDecoration(
                                labelText: 'RT',
                                prefixIcon: Icon(Icons.home_outlined,
                                    color: AppTheme.primary),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'RT wajib diisi';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            // Password
                            TextFormField(
                              controller: _passwordCtrl,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(
                                    Icons.lock_outline_rounded,
                                    color: AppTheme.primary),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: AppTheme.outline,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(
                                      () => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Password wajib diisi';
                                }
                                if (v.length < 6) {
                                  return 'Password minimal 6 karakter';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            // Konfirmasi Password
                            TextFormField(
                              controller: _konfirmasiCtrl,
                              obscureText: _obscureKonfirmasi,
                              decoration: InputDecoration(
                                labelText: 'Konfirmasi Password',
                                prefixIcon: const Icon(
                                    Icons.lock_outline_rounded,
                                    color: AppTheme.primary),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureKonfirmasi
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: AppTheme.outline,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() =>
                                      _obscureKonfirmasi = !_obscureKonfirmasi),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Konfirmasi password wajib diisi';
                                }
                                if (v != _passwordCtrl.text) {
                                  return 'Password tidak cocok';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),

                            // Tombol Daftar
                            SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _daftar,
                                child: _loading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'DAFTAR',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Link ke Login
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Sudah punya akun? ',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.outline,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const LoginView()),
                                  ),
                                  child: const Text(
                                    'Masuk',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    Text(
                      '(c) 2024 MyKarisma',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
