import 'package:flutter/material.dart';
import '../controllers/member_controller.dart';
import '../helpers/auth_helper.dart';
import '../models/member_model.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';

class MemberView extends StatefulWidget {
  const MemberView({super.key});
  @override
  State<MemberView> createState() => _MemberViewState();
}

class _MemberViewState extends State<MemberView> {
  final MemberController _ctrl = MemberController();
  List<MemberModel> _all = [], _filtered = [];
  String _q = '';
  bool _loading = true, _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadRole();
    _load();
  }

  Future<void> _loadRole() async {
    final s = await AuthHelper.getActiveSession();
    if (mounted) setState(() => _isAdmin = s?['role'] == 'admin');
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _ctrl.fetchMember();
    if (mounted) {
      setState(() {
        _all = data;
        _filtered = _q.isEmpty ? data : data.where((m) =>
          m.nama.toLowerCase().contains(_q.toLowerCase()) ||
          m.panggilan.toLowerCase().contains(_q.toLowerCase())).toList();
        _loading = false;
      });
    }
  }

  void _search(String q) {
    setState(() {
      _q = q;
      _filtered = q.isEmpty ? _all : _all.where((m) =>
        m.nama.toLowerCase().contains(q.toLowerCase()) ||
        m.panggilan.toLowerCase().contains(q.toLowerCase())).toList();
    });
  }

  String _inisial(String n) {
    final p = n.trim().split(' ');
    return p.length >= 2 ? '${p[0][0]}${p[1][0]}'.toUpperCase()
        : (n.isNotEmpty ? n[0].toUpperCase() : '?');
  }

  Color _roleColor(String r) {
    switch (r.toLowerCase()) {
      case 'admin': return AppTheme.primary;
      case 'pengurus': return AppTheme.tertiary;
      default: return AppTheme.secondary;
    }
  }

  void _bukaForm({MemberModel? m}) {
    final namaC = TextEditingController(text: m?.nama ?? '');
    final pangC = TextEditingController(text: m?.panggilan ?? '');
    final hpC   = TextEditingController(text: m?.noHp ?? '');
    final rtC   = TextEditingController(text: m?.rt ?? '');
    final passC = TextEditingController();
    String role = m?.role ?? 'member';
    bool saving = false, obscure = true;
    final isEdit = m != null;

    showModalBottomSheet(
      context: context, isScrollControlled: true, useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Container(
          decoration: const BoxDecoration(
            color: AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(left: 24, right: 24, top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 32),
            child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: AppTheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(isEdit ? 'Edit Member' : 'Tambah Member',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                    color: AppTheme.onSurface)),
                IconButton(icon: const Icon(Icons.close_rounded, color: AppTheme.outline),
                  onPressed: () => Navigator.pop(ctx)),
              ]),
              const SizedBox(height: 16),
              TextFormField(controller: namaC,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nama Lengkap',
                  prefixIcon: Icon(Icons.person_outline_rounded, color: AppTheme.primary))),
              const SizedBox(height: 12),
              TextFormField(controller: pangC,
                decoration: const InputDecoration(labelText: 'Username',
                  prefixIcon: Icon(Icons.badge_outlined, color: AppTheme.primary))),
              const SizedBox(height: 12),
              TextFormField(controller: hpC, keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'No HP',
                  prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.primary))),
              const SizedBox(height: 12),
              TextFormField(controller: rtC, keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'RT',
                  prefixIcon: Icon(Icons.home_outlined, color: AppTheme.primary))),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: role,
                decoration: const InputDecoration(labelText: 'Role',
                  prefixIcon: Icon(Icons.admin_panel_settings_outlined, color: AppTheme.primary)),
                items: ['member','pengurus','admin'].map((r) =>
                  DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (v) => set(() => role = v ?? 'member'),
              ),
              const SizedBox(height: 12),
              TextFormField(controller: passC, obscureText: obscure,
                decoration: InputDecoration(
                  labelText: isEdit
                    ? 'Password Baru (kosongkan jika tidak diubah)' : 'Password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.primary),
                  suffixIcon: IconButton(
                    icon: Icon(obscure ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                      color: AppTheme.outline, size: 20),
                    onPressed: () => set(() => obscure = !obscure)))),
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: saving ? null : () async {
                    set(() => saving = true);
                    final msg = ScaffoldMessenger.of(context);
                    Map<String, dynamic> res;
                    if (isEdit) {
                      res = await _ctrl.updateMember(
                        id: m.id, nama: namaC.text.trim(),
                        panggilan: pangC.text.trim(), noHp: hpC.text.trim(),
                        role: role, rt: rtC.text.trim(),
                        passwordBaru: passC.text.isEmpty ? null : passC.text);
                    } else {
                      res = await _ctrl.tambahMember(
                        nama: namaC.text.trim(), panggilan: pangC.text.trim(),
                        noHp: hpC.text.trim(), role: role, rt: rtC.text.trim(),
                        password: passC.text);
                    }
                    set(() => saving = false);
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    msg.showSnackBar(SnackBar(content: Text(res['message']),
                      backgroundColor: res['success'] ? Colors.green : Colors.red));
                    if (res['success']) _load();
                  },
                  child: saving
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(isEdit ? 'PERBARUI MEMBER' : 'TAMBAH MEMBER'),
                )),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _hapus(MemberModel m) async {
    final ok = await showDialog<bool>(context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Member'),
        content: Text('Yakin hapus "${m.nama}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus')),
        ],
      ));
    if (ok != true) return;
    final res = await _ctrl.hapusMember(m.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['message']),
        backgroundColor: res['success'] ? Colors.green : Colors.red));
      if (res['success']) _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A1C1C) : AppTheme.background;
    final tp = isDark ? const Color(0xFFF1F1F1) : AppTheme.onSurface;
    final cardBg = isDark ? const Color(0xFF252828) : AppTheme.surfaceContainerLowest;
    final bdr = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : AppTheme.outlineVariant.withValues(alpha: 0.5);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isDark
            ? const Color(0xFF1A1C1C).withValues(alpha: 0.95)
            : AppTheme.surfaceContainerLowest.withValues(alpha: 0.92),
        surfaceTintColor: Colors.transparent, elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: tp, size: 20),
          onPressed: () => Navigator.pop(context)),
        title: Text('Pengurus & Member',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: tp)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded, color: AppTheme.primary),
            onPressed: _load),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: TextField(onChanged: _search, style: TextStyle(color: tp),
                decoration: InputDecoration(
                  hintText: 'Cari member...',
                  hintStyle: TextStyle(
                    color: isDark ? const Color(0xFF889390) : AppTheme.outline),
                  prefixIcon: const Icon(Icons.search_rounded,
                    color: AppTheme.primary, size: 20),
                  suffixIcon: _q.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () => _search(''))
                    : null,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12)))),
            Container(height: 1, color: AppTheme.primary.withValues(alpha: 0.08)),
          ]),
        ),
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
        : _filtered.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.group_off_rounded, size: 56,
                color: isDark ? const Color(0xFF889390) : AppTheme.outline),
              const SizedBox(height: 12),
              Text(_q.isNotEmpty ? 'Tidak ada member yang cocok' : 'Belum ada data member',
                style: TextStyle(
                  color: isDark ? const Color(0xFF889390) : AppTheme.outline,
                  fontSize: 14)),
            ]))
          : ListView.builder(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: _filtered.length,
              itemBuilder: (_, i) {
                final m = _filtered[i];
                final rc = _roleColor(m.role);
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: bdr)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                    leading: CircleAvatar(radius: 22,
                      backgroundColor: rc.withValues(alpha: 0.12),
                      child: Text(_inisial(m.nama),
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                          color: rc))),
                    title: Text(m.nama, style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14, color: tp)),
                    subtitle: Text('@${m.panggilan}  •  RT ${m.rt}',
                      style: TextStyle(fontSize: 12,
                        color: isDark ? const Color(0xFF889390) : AppTheme.outline)),
                    trailing: _isAdmin
                      ? Row(mainAxisSize: MainAxisSize.min, children: [
                          CategoryBadge(label: m.role,
                            color: rc.withValues(alpha: 0.1), textColor: rc),
                          const SizedBox(width: 8),
                          GestureDetector(onTap: () => _bukaForm(m: m),
                            child: Container(width: 32, height: 32,
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.edit_rounded,
                                size: 16, color: AppTheme.primary))),
                          const SizedBox(width: 6),
                          GestureDetector(onTap: () => _hapus(m),
                            child: Container(width: 32, height: 32,
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.delete_outline_rounded,
                                size: 16, color: Colors.red))),
                        ])
                      : CategoryBadge(label: m.role,
                          color: rc.withValues(alpha: 0.1), textColor: rc),
                  ),
                );
              }),
      floatingActionButton: _isAdmin
        ? FloatingActionButton(
            backgroundColor: AppTheme.secondary, foregroundColor: Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            onPressed: () => _bukaForm(),
            child: const Icon(Icons.person_add_rounded, size: 26))
        : null,
    );
  }
}
