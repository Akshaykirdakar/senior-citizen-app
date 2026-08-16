import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../data/member_repo.dart';

/// Backup = write all data to a .json file and open the share sheet
/// (Google Drive, WhatsApp, email, etc. appear as targets).
/// Restore = pick a backup .json and load it back into the database.
class BackupService {
  static Future<String> backup() async {
    final data = await MemberRepo.instance.dumpAll();
    final json = const JsonEncoder.withIndent('  ').convert(data);
    final now = DateTime.now();
    final stamp = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/sangh-backup-$stamp.json';
    File(path).writeAsStringSync(json);
    await Share.shareXFiles([XFile(path)],
        text: 'सभासद बॅकअप — माळशिरस तालुका ज्येष्ठ नागरिक संघ, अकलूज');
    return path;
  }

  /// Returns number of members restored, or null if the user cancelled.
  static Future<int?> restore() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (res == null || res.files.isEmpty) return null;
    final f = res.files.first;
    final content = f.bytes != null
        ? utf8.decode(f.bytes!)
        : File(f.path!).readAsStringSync();
    final data = jsonDecode(content) as Map<String, dynamic>;
    if (data['app'] != 'senior_sangh') {
      throw const FormatException('ही फाइल या अ‍ॅपची बॅकअप फाइल नाही.');
    }
    await MemberRepo.instance.replaceAllData(data);
    return (data['members'] as List? ?? []).length;
  }
}
