import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/backup_service.dart';
import '../services/drive_service.dart';

class BackupScreen extends StatefulWidget {
  final Future<void> Function() onRestored;
  const BackupScreen({super.key, required this.onRestored});
  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _busy = false;

  Future<void> _backup() async {
    setState(() => _busy = true);
    try {
      await BackupService.backup();
    } catch (e) {
      _snack('बॅकअप अयशस्वी: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('रिस्टोअर करायचे?'),
        content: const Text('सध्याची सर्व माहिती बॅकअप फाइलमधील माहितीने बदलली जाईल. हे पूर्ववत होणार नाही.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('रद्द')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('रिस्टोअर')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      final n = await BackupService.restore();
      if (n == null) {
        _snack('फाइल निवडली नाही.');
      } else {
        await widget.onRestored();
        _snack('$n सभासद रिस्टोअर झाले.');
      }
    } catch (e) {
      _snack('रिस्टोअर अयशस्वी: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _driveBackup() async {
    setState(() => _busy = true);
    try {
      final ok = await DriveService.backup();
      _snack(ok ? 'Google Drive वर बॅकअप झाला.' : 'Google Drive साइन-इन रद्द / सेटअप आवश्यक.');
    } catch (e) {
      _snack('Drive बॅकअप अयशस्वी (सेटअप आवश्यक): $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _driveRestore() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Drive मधून रिस्टोअर?'),
        content: const Text('सध्याची सर्व माहिती Drive वरील बॅकअपने बदलली जाईल.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('रद्द')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('रिस्टोअर')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      final n = await DriveService.restore();
      if (n == null) {
        _snack('Google Drive साइन-इन रद्द / सेटअप आवश्यक.');
      } else if (n == 0) {
        _snack('Drive वर बॅकअप फाइल सापडली नाही.');
      } else {
        await widget.onRestored();
        _snack('$n सभासद Drive वरून रिस्टोअर झाले.');
      }
    } catch (e) {
      _snack('Drive रिस्टोअर अयशस्वी (सेटअप आवश्यक): $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: AppColors.greenDeep));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
        title: const Text('बॅकअप / रिस्टोअर', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Stack(children: [
        ListView(padding: const EdgeInsets.all(16), children: [
          _card(
            icon: Icons.cloud_upload,
            title: 'बॅकअप घ्या',
            body: 'सर्व सभासद व मास्टर माहितीची एक फाइल तयार होते. शेअर मेनूमधून ती Google Drive, WhatsApp किंवा ई-मेलवर जतन करा.',
            button: 'बॅकअप फाइल तयार करा',
            color: AppColors.green,
            onTap: _backup,
          ),
          const SizedBox(height: 14),
          _card(
            icon: Icons.cloud_download,
            title: 'रिस्टोअर करा',
            body: 'आधी घेतलेली बॅकअप (.json) फाइल निवडा. सध्याची माहिती त्या फाइलमधील माहितीने बदलली जाईल.',
            button: 'बॅकअप फाइल निवडा',
            color: AppColors.marigold,
            textColor: const Color(0xFF3A2400),
            onTap: _restore,
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: const [
                Icon(Icons.add_to_drive, color: AppColors.male),
                SizedBox(width: 8),
                Text('थेट Google Drive', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.ink)),
              ]),
              const SizedBox(height: 8),
              const Text('थेट तुमच्या Google खात्यातील Drive मध्ये सेव्ह/रिस्टोअर करा. (पहिल्यांदा वापरण्यापूर्वी Google Cloud सेटअप आवश्यक — README पाहा.)',
                  style: TextStyle(fontSize: 13, height: 1.4, color: AppColors.muted)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: FilledButton.icon(
                  onPressed: _driveBackup,
                  style: FilledButton.styleFrom(backgroundColor: AppColors.male, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(46)),
                  icon: const Icon(Icons.cloud_upload, size: 18), label: const Text('Drive सेव्ह'),
                )),
                const SizedBox(width: 8),
                Expanded(child: OutlinedButton.icon(
                  onPressed: _driveRestore,
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.male, side: const BorderSide(color: AppColors.male), minimumSize: const Size.fromHeight(46)),
                  icon: const Icon(Icons.cloud_download, size: 18), label: const Text('Drive आणा'),
                )),
              ]),
            ]),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.marigoldSoft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.marigold.withOpacity(0.35)),
            ),
            child: const Text(
              'सूचना: दर महिन्याला बॅकअप घ्या व Drive वर ठेवा. फोन बदलल्यास त्याच फाइलवरून सर्व माहिती परत मिळेल.',
              style: TextStyle(fontSize: 12.5, height: 1.4, color: AppColors.ink),
            ),
          ),
        ]),
        if (_busy) Container(color: Colors.black26, child: const Center(child: CircularProgressIndicator())),
      ]),
    );
  }

  Widget _card({
    required IconData icon,
    required String title,
    required String body,
    required String button,
    required Color color,
    Color textColor = Colors.white,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.ink)),
        ]),
        const SizedBox(height: 8),
        Text(body, style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.muted)),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(backgroundColor: color, foregroundColor: textColor, minimumSize: const Size.fromHeight(46)),
          child: Text(button, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }
}
