import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import '../data/member_repo.dart';

/// Direct Google Drive sync (private app folder).
///
/// NOTE: This needs a one-time Google Cloud setup — an OAuth 2.0 **Android**
/// client with this app's package name + signing SHA-1, and the Drive API
/// enabled. Until that exists, sign-in returns null and the UI shows a
/// "setup required" message. See README → "Google Drive setup".
class DriveService {
  static final GoogleSignIn _google = GoogleSignIn(scopes: [drive.DriveApi.driveAppdataScope]);
  static const String _fileName = 'sangh-backup.json';

  static Future<drive.DriveApi?> _api() async {
    var account = await _google.signInSilently();
    account ??= await _google.signIn();
    if (account == null) return null;
    final client = await _google.authenticatedClient();
    if (client == null) return null;
    return drive.DriveApi(client);
  }

  /// Upload current data to Drive. Returns true on success, false if not signed in.
  static Future<bool> backup() async {
    final api = await _api();
    if (api == null) return false;
    final data = await MemberRepo.instance.dumpAll();
    final bytes = utf8.encode(jsonEncode(data));
    final media = drive.Media(Stream.value(bytes), bytes.length);
    final existing = await api.files.list(spaces: 'appDataFolder', q: "name = '$_fileName'");
    if (existing.files != null && existing.files!.isNotEmpty) {
      await api.files.update(drive.File(), existing.files!.first.id!, uploadMedia: media);
    } else {
      final f = drive.File()
        ..name = _fileName
        ..parents = ['appDataFolder'];
      await api.files.create(f, uploadMedia: media);
    }
    return true;
  }

  /// Restore from Drive. Returns members restored, 0 if no backup, null if not signed in.
  static Future<int?> restore() async {
    final api = await _api();
    if (api == null) return null;
    final list = await api.files.list(spaces: 'appDataFolder', q: "name = '$_fileName'");
    if (list.files == null || list.files!.isEmpty) return 0;
    final media = await api.files.get(
      list.files!.first.id!,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;
    final bytes = <int>[];
    await for (final chunk in media.stream) {
      bytes.addAll(chunk);
    }
    final data = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    await MemberRepo.instance.replaceAllData(data);
    return (data['members'] as List? ?? []).length;
  }

  static Future<void> signOut() => _google.signOut();
}
