import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

/// Private Google Drive document storage for Spendz.
///
/// Files are uploaded into a private app-created folder. No Drive permissions
/// are created, so files remain private to the signed-in Google account.
class DriveDocumentService {
  DriveDocumentService._();
  static final DriveDocumentService instance = DriveDocumentService._();

  static const String driveFileScope =
      'https://www.googleapis.com/auth/drive.file';
  static const String _driveBase = 'https://www.googleapis.com/drive/v3';
  static const String _uploadBase = 'https://www.googleapis.com/upload/drive/v3';

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  Future<void>? _initialization;
  GoogleSignInAccount? _account;
  String? _folderId;
  final http.Client _client = http.Client();

  String? get signedInEmail => _account?.email;
  bool get isSignedIn => _account != null;

  Future<void> _initialize() {
    return _initialization ??= _googleSignIn.initialize(
      // Android uses the app's native OAuth client; optionally pass the
      // Web OAuth client ID at build time for server-side integrations.
      serverClientId: const String.fromEnvironment(
        'GOOGLE_SERVER_CLIENT_ID',
        defaultValue: '',
      ).isEmpty
          ? null
          : const String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID'),
    );
  }

  Future<void> ensureConnected() async {
    if (_account == null) await signIn();
    await _authorizedHeaders(interactive: true);
  }

  Future<GoogleSignInAccount> signIn() async {
    await _initialize();
    _account = await _googleSignIn.authenticate(scopeHint: const [driveFileScope]);
    await _authorizedHeaders(interactive: true);
    _folderId = null;
    return _account!;
  }

  Future<void> restoreSession() async {
    await _initialize();
    final account = await _googleSignIn.attemptLightweightAuthentication();
    if (account == null) {
      _account = null;
      return;
    }
    _account = account;
    // Do not trigger a consent screen during startup.
    final authorization = await account.authorizationClient
        .authorizationForScopes(const [driveFileScope]);
    if (authorization == null) {
      _account = null;
      return;
    }
  }

  Future<Map<String, String>> _authorizedHeaders({
    bool interactive = false,
  }) async {
    await _initialize();
    final account = _account;
    if (account == null) {
      throw const DriveDocumentException(
        'Connect your Google account to access Spendz Documents.',
      );
    }

    var authorization = await account.authorizationClient
        .authorizationForScopes(const [driveFileScope]);
    if (authorization == null && interactive) {
      authorization = await account.authorizationClient
          .authorizeScopes(const [driveFileScope]);
    }
    if (authorization == null || authorization.accessToken.isEmpty) {
      throw const DriveDocumentException(
        'Google Drive permission is missing. Reconnect Google Drive.',
      );
    }
    return {
      'Authorization': 'Bearer ${authorization.accessToken}',
    };
  }

  Future<http.Response> _send(
    String method,
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final auth = await _authorizedHeaders(interactive: false);
    final request = http.Request(method, uri);
    request.headers.addAll({...auth, ...?headers});
    if (body is String) {
      request.body = body;
    } else if (body is List<int>) {
      request.bodyBytes = body;
    }
    final response = await _client.send(request);
    final result = await http.Response.fromStream(response);
    if (result.statusCode < 200 || result.statusCode >= 300) {
      var message = 'Google Drive request failed (${result.statusCode}).';
      try {
        final json = jsonDecode(result.body);
        message = json['error']?['message']?.toString() ?? message;
      } catch (_) {}
      throw DriveDocumentException(message, statusCode: result.statusCode);
    }
    return result;
  }

  Future<String> _ensureFolder() async {
    if (_folderId != null) return _folderId!;
    final headers = await _authorizedHeaders();
    final query =
        "name = 'Spendz Documents' and mimeType = 'application/vnd.google-apps.folder' and trashed = false";
    final list = await _client.get(
      Uri.parse('$_driveBase/files').replace(queryParameters: {
        'q': query,
        'spaces': 'drive',
        'pageSize': '10',
        'fields': 'files(id,name)',
      }),
      headers: headers,
    );
    if (list.statusCode < 200 || list.statusCode >= 300) {
      throw DriveDocumentException('Could not find Spendz folder: ${list.body}');
    }
    final files = (jsonDecode(list.body)['files'] as List?) ?? const [];
    if (files.isNotEmpty) {
      _folderId = files.first['id'] as String;
      return _folderId!;
    }

    final created = await _send(
      'POST',
      Uri.parse('$_driveBase/files?fields=id,name'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': 'Spendz Documents',
        'mimeType': 'application/vnd.google-apps.folder',
      }),
    );
    _folderId = jsonDecode(created.body)['id'] as String;
    return _folderId!;
  }

  Future<DriveStoredDocument> upload({
    required String documentId,
    required String fileName,
    required String mimeType,
    required Uint8List bytes,
  }) async {
    await ensureConnected();
    if (bytes.isEmpty) {
      throw const DriveDocumentException('Cannot upload an empty document.');
    }
    if (bytes.length > 25 * 1024 * 1024) {
      throw const DriveDocumentException('Document exceeds the 25 MB limit.');
    }
    final folderId = await _ensureFolder();
    final boundary = 'spendz_${const Uuid().v4().replaceAll('-', '')}';
    final metadata = jsonEncode({
      'name': fileName,
      'mimeType': mimeType,
      'parents': [folderId],
      'appProperties': {'spendzDocumentId': documentId},
    });
    final body = BytesBuilder(copy: false)
      ..add(utf8.encode('--$boundary\r\n'
          'Content-Type: application/json; charset=UTF-8\r\n\r\n'
          '$metadata\r\n'
          '--$boundary\r\n'
          'Content-Type: $mimeType\r\n\r\n'))
      ..add(bytes)
      ..add(utf8.encode('\r\n--$boundary--'));
    final response = await _send(
      'POST',
      Uri.parse('$_uploadBase/files?uploadType=multipart&fields=id,name,mimeType,size,createdTime,modifiedTime'),
      headers: {'Content-Type': 'multipart/related; boundary=$boundary'},
      body: body.takeBytes(),
    );
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return DriveStoredDocument(
      fileId: json['id'] as String,
      fileName: json['name'] as String? ?? fileName,
      mimeType: json['mimeType'] as String? ?? mimeType,
      size: int.tryParse(json['size']?.toString() ?? '') ?? bytes.length,
    );
  }

  Future<Uint8List> download(String fileId) async {
    final response = await _send(
      'GET',
      Uri.parse('$_driveBase/files/$fileId?alt=media'),
    );
    return response.bodyBytes;
  }

  Future<List<DriveStoredDocument>> listDocuments() async {
    final folderId = await _ensureFolder();
    final query = "'$folderId' in parents and trashed = false";
    final response = await _send(
      'GET',
      Uri.parse('$_driveBase/files').replace(queryParameters: {
        'q': query,
        'pageSize': '1000',
        'orderBy': 'modifiedTime desc',
        'fields': 'files(id,name,mimeType,size,createdTime,modifiedTime,appProperties)',
      }),
    );
    final files = (jsonDecode(response.body)['files'] as List?) ?? const [];
    return files.map((item) => DriveStoredDocument(
      fileId: item['id'] as String,
      fileName: item['name'] as String? ?? 'Document',
      mimeType: item['mimeType'] as String? ?? 'application/octet-stream',
      size: int.tryParse(item['size']?.toString() ?? '') ?? 0,
    )).toList();
  }

  Future<void> delete(String fileId) async {
    await _send('DELETE', Uri.parse('$_driveBase/files/$fileId'));
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _account = null;
    _folderId = null;
  }

  void dispose() => _client.close();
}

class DriveStoredDocument {
  final String fileId;
  final String fileName;
  final String mimeType;
  final int size;

  const DriveStoredDocument({
    required this.fileId,
    required this.fileName,
    required this.mimeType,
    required this.size,
  });
}

class DriveDocumentException implements Exception {
  final String message;
  final int? statusCode;

  const DriveDocumentException(this.message, {this.statusCode});

  @override
  String toString() => message;
}
