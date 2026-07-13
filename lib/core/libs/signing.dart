import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;

const List<String> _kDriveScopes = [
  'https://www.googleapis.com/auth/drive.readonly',
  'https://www.googleapis.com/auth/spreadsheets',
];

bool _isInitialized = false;

Future<void> _ensureInitialized() async {
  if (_isInitialized) return;
  await GoogleSignIn.instance.initialize();
  _isInitialized = true;
}

Future<GoogleSignInAccount?> _getAuthenticatedAccount() async {
  try {
    final lightweight = GoogleSignIn.instance.attemptLightweightAuthentication();
    final account = lightweight is Future ? await lightweight : lightweight;
    if (account != null) return account;
  } catch (_) {
    // Fallthrough to interactive auth
  }

  try {
    return await GoogleSignIn.instance.authenticate(scopeHint: _kDriveScopes);
  } catch (_) {
    // User cancelled or auth failed
    return null;
  }
}

Future<List<drive.File>> listUserSheets() async {
  try {
    await _ensureInitialized();

    final account = await _getAuthenticatedAccount();
    if (account == null) return [];

    // Verify existing scope authorization or prompt user for access
    var authorization = await account.authorizationClient.authorizationForScopes(_kDriveScopes);
    authorization ??= await account.authorizationClient.authorizeScopes(_kDriveScopes);

    final authClient = authorization.authClient(scopes: _kDriveScopes);
    final driveApi = drive.DriveApi(authClient);

    final result = await driveApi.files.list(
      q: "mimeType='application/vnd.google-apps.spreadsheet'",
      spaces: 'drive',
      $fields: 'files(id, name, modifiedTime, owners)',
      orderBy: 'modifiedTime desc',
    );

    return result.files ?? [];
  } catch (_) {
    // Catch-all for API errors, revoked tokens, or network issues
    return [];
  }
}