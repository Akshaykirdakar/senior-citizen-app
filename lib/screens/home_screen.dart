import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/member.dart';
import 'birthdays_screen.dart';
import 'backup_screen.dart';
import 'meeting_message_screen.dart';

class HomeScreen extends StatelessWidget {
  final List<Member> members;
  final VoidCallback onAdd;
  final ValueChanged<int> onGoTab;
  final Future<void> Function() onDataChanged;
  const HomeScreen({super.key, required this.members, required this.onAdd, required this.onGoTab, required this.onDataChanged});

  String _dm(String iso) {
    final p = iso.split('-');
    return p.length == 3 ? '${p[2]}/${p[1]}' : iso;
  }
  String _when(int d) => d == 0 ? 'आज! 🎉' : d == 1 ? 'उद्या' : '$d दिवसांनी';

  @override
  Widget build(BuildContext context) {
    final total = members.length;
    final male = members.where((m) => m.gender == 'M').length;
    final female = total - male;
    final fees = members.fold<int>(0, (s, m) => s + m.fee);
    final now = DateTime.now();
    final ym = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final thisMonth = members.where((m) => m.joinDate.startsWith(ym)).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        const Text('|| ज्येष्ठ आम्ही ज्येष्ठच राहू ||',
            style: TextStyle(color: AppColors.marigold, fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 2),
        const Text('नमस्कार, कार्यालय 🙏',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.ink)),
        const SizedBox(height: 12),
        Row(children: [
          _stat('एकूण सभासद', '$total', AppColors.green),
          const SizedBox(width: 12),
          _stat('या महिन्यात नवीन', '$thisMonth', AppColors.marigold),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _stat('पुरुष', '$male', AppColors.male),
          const SizedBox(width: 12),
          _stat('महिला', '$female', AppColors.female),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.green, borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            const Icon(Icons.account_balance_wallet, color: Colors.white, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('जमा प्रवेश फी (एकूण)',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                Text('रु. $fees/–',
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        Row(children: [
          _quick(Icons.groups, 'सभासद यादी', () => onGoTab(1)),
          const SizedBox(width: 12),
          _quick(Icons.bar_chart, 'अहवाल', () => onGoTab(2)),
        ]),
        const SizedBox(height: 12),
        _birthdayCard(context),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BackupScreen(onRestored: onDataChanged))),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.green, side: const BorderSide(color: AppColors.line), minimumSize: const Size.fromHeight(46)),
              icon: const Icon(Icons.backup, size: 18),
              label: const Text('बॅकअप / रिस्टोअर', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MeetingMessageScreen(members: members))),
          style: FilledButton.styleFrom(backgroundColor: AppColors.green, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(48)),
          icon: const Icon(Icons.campaign),
          label: const Text('मिटींग मेसेज पाठवा', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ),
      ],
    );
  }

  Widget _birthdayCard(BuildContext context) {
    final up = members.where((m) => m.dob.isNotEmpty && m.birthdayInDays <= 30).toList()
      ..sort((a, b) => a.birthdayInDays.compareTo(b.birthdayInDays));
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: const [
            Icon(Icons.cake, color: AppColors.marigold, size: 18),
            SizedBox(width: 8),
            Text('वाढदिवस · येत्या ३० दिवसात', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink)),
          ]),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BirthdaysScreen(members: members))),
            child: const Text('सर्व पाहा', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.green)),
          ),
        ]),
        const SizedBox(height: 10),
        if (up.isEmpty)
          const Text('येत्या ३० दिवसात वाढदिवस नाही.', style: TextStyle(fontSize: 13, color: AppColors.muted))
        else
          for (final m in up.take(4))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Expanded(child: Text(m.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, color: AppColors.ink))),
                Text('${_dm(m.dob)}  ', style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
                Text(_when(m.birthdayInDays), style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: m.birthdayInDays == 0 ? AppColors.marigold : AppColors.green)),
              ]),
            ),
      ]),
    );
  }

  Widget _stat(String label, String value, Color color) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 13, color: AppColors.ink)),
          ]),
        ),
      );

  Widget _quick(IconData icon, String label, VoidCallback onTap) => Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(children: [
              Icon(icon, color: AppColors.green, size: 22),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
            ]),
          ),
        ),
      );
}
