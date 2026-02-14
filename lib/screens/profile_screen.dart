import 'package:flutter/material.dart';
import '../models/admin_data.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController(text: 'Admin Principal');
  final _emailCtrl = TextEditingController(text: 'admin@antbms.dz');
  final _phoneCtrl = TextEditingController(text: '+213 555 123 456');
  final _currentPwCtrl = TextEditingController();
  final _newPwCtrl = TextEditingController();
  final _confirmPwCtrl = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _currentPwCtrl.dispose();
    _newPwCtrl.dispose();
    _confirmPwCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        LayoutBuilder(builder: (ctx, c) {
          if (c.maxWidth > 800) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildAccountCard()),
                const SizedBox(width: 16),
                Expanded(child: Column(children: [
                  _buildSecurityCard(),
                  const SizedBox(height: 16),
                  _buildSessionCard(),
                ])),
              ],
            );
          }
          return Column(children: [
            _buildAccountCard(),
            const SizedBox(height: 16),
            _buildSecurityCard(),
            const SizedBox(height: 16),
            _buildSessionCard(),
          ]);
        }),
      ],
    );
  }

  // ═══════════════════ ACCOUNT INFO ═══════════════════

  Widget _buildAccountCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.person_rounded, size: 20, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Account Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          ]),
          const SizedBox(height: 24),
          // Avatar
          Center(
            child: Column(children: [
              const CircleAvatar(
                radius: 44,
                backgroundColor: AppColors.primaryDark,
                child: Text('A', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.camera_alt_outlined, size: 16),
                label: const Text('Change Avatar', style: TextStyle(fontSize: 12)),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          _buildField('Full Name', _nameCtrl, Icons.person_outline),
          const SizedBox(height: 14),
          _buildField('Email', _emailCtrl, Icons.email_outlined),
          const SizedBox(height: 14),
          _buildField('Phone', _phoneCtrl, Icons.phone_outlined),
          const SizedBox(height: 14),
          // Role (read-only)
          _buildReadonlyField('Role', 'Administrator', Icons.badge_outlined),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => _showSnack('Profile updated successfully'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════ SECURITY ═══════════════════

  Widget _buildSecurityCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.accent),
            SizedBox(width: 8),
            Text('Security', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          ]),
          const SizedBox(height: 20),
          TextField(
            controller: _currentPwCtrl,
            obscureText: _obscureCurrent,
            decoration: InputDecoration(
              labelText: 'Current Password',
              prefixIcon: const Icon(Icons.lock_outline, size: 18),
              suffixIcon: IconButton(
                icon: Icon(_obscureCurrent ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _newPwCtrl,
            obscureText: _obscureNew,
            decoration: InputDecoration(
              labelText: 'New Password',
              prefixIcon: const Icon(Icons.lock_rounded, size: 18),
              suffixIcon: IconButton(
                icon: Icon(_obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                onPressed: () => setState(() => _obscureNew = !_obscureNew),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _confirmPwCtrl,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Confirm New Password',
              prefixIcon: const Icon(Icons.lock_rounded, size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _showSnack('Password updated successfully'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: const BorderSide(color: AppColors.accent),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Update Password', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════ SESSION INFO ═══════════════════

  Widget _buildSessionCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.devices_rounded, size: 20, color: AppColors.primaryDark),
            SizedBox(width: 8),
            Text('Session Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          ]),
          const SizedBox(height: 16),
          _sessionRow(Icons.access_time, 'Last Login', _fmtDate(DateTime.now().subtract(const Duration(minutes: 5)))),
          _sessionRow(Icons.language, 'IP Address', '192.168.1.100'),
          _sessionRow(Icons.computer_rounded, 'Browser', 'Chrome 120 / Linux'),
          _sessionRow(Icons.timer_outlined, 'Session Duration', '2h 34m'),
          _sessionRow(Icons.verified_user_outlined, 'Status', 'Active', color: AppColors.success),
        ],
      ),
    );
  }

  Widget _sessionRow(IconData icon, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Icon(icon, size: 16, color: AppColors.textLight),
        const SizedBox(width: 10),
        SizedBox(width: 120, child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textLight))),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color ?? AppColors.textDark)),
      ]),
    );
  }

  // ═══════════════════ HELPERS ═══════════════════

  Widget _buildField(String label, TextEditingController ctrl, IconData icon) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildReadonlyField(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(children: [
        Icon(icon, size: 18, color: AppColors.textLight),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark)),
        ]),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: AppColors.primaryDark.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: const Text('Admin', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primaryDark)),
        ),
      ]),
    );
  }

  String _fmtDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
