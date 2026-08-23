import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:path_provider/path_provider.dart';
import 'package:yaml/yaml.dart';
import 'package:universal_html/html.dart' as html;

import 'storage_service.dart';
import '../constants.dart';

class GoogleDriveService {
  static final GoogleDriveService _instance = GoogleDriveService._internal();
  factory GoogleDriveService() => _instance;

  late final GoogleSignIn _googleSignIn;
  
  drive.DriveApi? _driveApi;
  bool _isAuthenticated = false;
  GoogleSignInAccount? _currentUser;
  bool _isInitialized = false;
  bool _isRestoring = false;

  drive.DriveApi? get driveApi => _driveApi;

  Future<String?> getOrCreateAppFolder() => _getOrCreateAppFolder();

  GoogleDriveService._internal() {
    _initGoogleSignIn();
  }

  void _initGoogleSignIn() {
    if (_isInitialized) return;
    _isInitialized = true;
    
    _googleSignIn = GoogleSignIn(
      clientId: kIsWeb ? googleWebClientId : null,
      scopes: [drive.DriveApi.driveAppdataScope],
      hostedDomain: null,
      serverClientId: kIsWeb ? googleWebClientId : null,
    );
    
    // Для веба проверяем сохраненную сессию
    if (kIsWeb) {
      _checkWebSession();
    }
  }

  // Проверка веб-сессии в localStorage
  void _checkWebSession() {
    try {
      final token = html.window.localStorage['gsi_access_token'];
      if (token != null && token.isNotEmpty) {
        if (kDebugMode) print('Найден сохраненный токен в localStorage');
      }
    } catch (e) {
      if (kDebugMode) print('Ошибка проверки веб-сессии: $e');
    }
  }
  
  // Проверка авторизации
  bool get isAuthenticated => _isAuthenticated;
  
  // Пытаемся восстановить сессию автоматически
  Future<bool> restoreSession() async {
    if (_isRestoring) return _isAuthenticated;
    _isRestoring = true;
    
    try {
      // Для веба - специальная логика восстановления
      if (kIsWeb) {
        return await _restoreWebSession();
      }
      
      // Для мобильных платформ - стандартная логика
      return await _restoreMobileSession();
    } catch (e) {
      if (kDebugMode) print('Ошибка восстановления сессии Google: $e');
      return false;
    } finally {
      _isRestoring = false;
    }
  }

  // Восстановление для веба
  Future<bool> _restoreWebSession() async {
    try {
      if (kDebugMode) print('Попытка восстановления веб-сессии...');
      
      // 1. Проверяем текущего пользователя
      final GoogleSignInAccount? account = _googleSignIn.currentUser;
      if (account != null) {
        final authClient = await _googleSignIn.authenticatedClient();
        if (authClient != null) {
          _driveApi = drive.DriveApi(authClient);
          _isAuthenticated = true;
          _currentUser = account;
          if (kDebugMode) print('Веб-сессия восстановлена для: ${account.email}');
          return true;
        }
      }
      
      // 2. Пробуем signInSilently() - для веба может не работать
      try {
        final signedIn = await _googleSignIn.signInSilently();
        if (signedIn != null) {
          final authClient = await _googleSignIn.authenticatedClient();
          if (authClient != null) {
            _driveApi = drive.DriveApi(authClient);
            _isAuthenticated = true;
            _currentUser = signedIn;
            if (kDebugMode) print('Веб-сессия восстановлена через signInSilently для: ${signedIn.email}');
            return true;
          }
        }
      } catch (e) {
        if (kDebugMode) print('signInSilently не сработал: $e');
      }
      
      // 3. Пробуем восстановить через сохраненную информацию
      final savedInfo = await getSavedAccountInfo();
      if (savedInfo != null) {
        if (kDebugMode) print('Найдена сохраненная информация аккаунта: ${savedInfo['email']}');
      }
      
      // 4. Проверяем наличие токена в localStorage (GSI)
      try {
        final token = html.window.localStorage['gsi_access_token'];
        if (token != null && token.isNotEmpty) {
          if (kDebugMode) print('Найден GSI токен');
          // Пробуем signIn() - это покажет диалог входа, но пользователь уже авторизован
          final signedIn = await _googleSignIn.signIn();
          if (signedIn != null) {
            final authClient = await _googleSignIn.authenticatedClient();
            if (authClient != null) {
              _driveApi = drive.DriveApi(authClient);
              _isAuthenticated = true;
              _currentUser = signedIn;
              if (kDebugMode) print('Веб-сессия восстановлена через GSI токен для: ${signedIn.email}');
              return true;
            }
          }
        }
      } catch (e) {
        if (kDebugMode) print('Ошибка восстановления через GSI токен: $e');
      }
      
      if (kDebugMode) print('Не удалось восстановить веб-сессию Google');
      return false;
    } catch (e) {
      if (kDebugMode) print('Ошибка восстановления веб-сессии: $e');
      return false;
    }
  }

  // Восстановление для мобильных платформ
  Future<bool> _restoreMobileSession() async {
    try {
      // Проверяем, есть ли уже авторизованный пользователь
      final GoogleSignInAccount? account = _googleSignIn.currentUser;
      
      if (account != null) {
        // Если пользователь уже авторизован, восстанавливаем API
        final authClient = await _googleSignIn.authenticatedClient();
        if (authClient != null) {
          _driveApi = drive.DriveApi(authClient);
          _isAuthenticated = true;
          _currentUser = account;
          if (kDebugMode) print('Сессия Google восстановлена для: ${account.email}');
          return true;
        }
      }
      
      // Пробуем восстановить через silent sign-in
      final signedIn = await _googleSignIn.signInSilently();
      if (signedIn != null) {
        final authClient = await _googleSignIn.authenticatedClient();
        if (authClient != null) {
          _driveApi = drive.DriveApi(authClient);
          _isAuthenticated = true;
          _currentUser = signedIn;
          if (kDebugMode) print('Сессия Google восстановлена через silent sign-in для: ${signedIn.email}');
          return true;
        }
      }
      
      if (kDebugMode) print('Не удалось восстановить сессию Google');
      return false;
    } catch (e) {
      if (kDebugMode) print('Ошибка восстановления сессии Google: $e');
      return false;
    }
  }
  
  // ✅ Вход в Google аккаунт (исправлено для веба)
  Future<bool> signIn() async {
    try {
      if (kIsWeb && _isAuthenticated) {
        return true;
      }
      
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      
      if (account != null) {
        final authClient = await _googleSignIn.authenticatedClient();
        if (authClient != null) {
          _driveApi = drive.DriveApi(authClient);
          _isAuthenticated = true;
          _currentUser = account;
          
          if (kDebugMode) print('Успешный вход: ${account.email}');
          
          // ✅ Для веба дополнительно получаем данные профиля через People API
          if (kIsWeb) {
            await _fetchUserProfile(account);
            // Сохраняем токен в localStorage для веба
            try {
              final token = await _getAccessToken();
              if (token != null) {
                html.window.localStorage['gsi_access_token'] = token;
              }
            } catch (e) {
              if (kDebugMode) print('Ошибка сохранения токена: $e');
            }
          }
          
          // Сохраняем информацию об аккаунте
          await _saveAccountInfo(account);
          
          return true;
        }
      }
      return false;
    } catch (e) {
      if (kDebugMode) print('Ошибка входа в Google: $e');
      return false;
    }
  }

  // ✅ Получение access token для веба
  Future<String?> _getAccessToken() async {
    try {
      final account = _googleSignIn.currentUser;
      if (account == null) return null;
      
      // Получаем токен через authHeaders
      final headers = await account.authHeaders;
      if (headers != null && headers.containsKey('Authorization')) {
        final authHeader = headers['Authorization'];
        if (authHeader != null && authHeader.startsWith('Bearer ')) {
          return authHeader.substring(7);
        }
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) print('Ошибка получения токена: $e');
      return null;
    }
  }
  
  // ✅ Получение профиля пользователя через People API (для веба)
  Future<void> _fetchUserProfile(GoogleSignInAccount account) async {
    try {
      final authClient = await _googleSignIn.authenticatedClient();
      if (authClient == null) return;
      
      final response = await authClient.get(
        Uri.parse(
          'https://people.googleapis.com/v1/people/me?'
          'personFields=names,emailAddresses,photos&'
          'sources=READ_SOURCE_TYPE_PROFILE'
        ),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (kDebugMode) print('Профиль пользователя загружен');
      } else {
        if (kDebugMode) print('Ошибка загрузки профиля: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) print('Ошибка получения профиля: $e');
    }
  }
  
  // Выход из Google аккаунта
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _isAuthenticated = false;
    _driveApi = null;
    _currentUser = null;
    
    // Удаляем сохраненную информацию об аккаунте
    await _deleteAccountInfo();
    
    // Для веба - очищаем localStorage
    if (kIsWeb) {
      try {
        html.window.localStorage.remove('gsi_access_token');
        html.window.localStorage.remove('auth_redirect_url');
      } catch (e) {
        // Игнорируем
      }
    }
  }
  
  // Сохранение информации об аккаунте
  Future<void> _saveAccountInfo(GoogleSignInAccount account) async {
    try {
      final data = {
        'email': account.email,
        'displayName': account.displayName,
        'id': account.id,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$authFileName');
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      if (kDebugMode) print('Ошибка сохранения информации об аккаунте: $e');
    }
  }
  
  // Удаление информации об аккаунте
  Future<void> _deleteAccountInfo() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$authFileName');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      if (kDebugMode) print('Ошибка удаления информации об аккаунте: $e');
    }
  }
  
  // Получение сохраненной информации об аккаунте
  Future<Map<String, dynamic>?> getSavedAccountInfo() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$authFileName');
      if (await file.exists()) {
        final content = await file.readAsString();
        return jsonDecode(content) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('Ошибка чтения информации об аккаунте: $e');
      return null;
    }
  }
  
  // Получение текущего аккаунта
  GoogleSignInAccount? getCurrentAccount() {
    return _currentUser ?? _googleSignIn.currentUser;
  }

  // Проверка, есть ли веб-сессия
  bool hasWebSession() {
    if (!kIsWeb) return false;
    try {
      final token = html.window.localStorage['gsi_access_token'];
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
  
  // Проверка существования папки приложения
  Future<String?> _getOrCreateAppFolder() async {
    if (_driveApi == null) return null;
    
    try {
      final folderList = await _driveApi!.files.list(
        q: "name = '$appFolderName' and mimeType = 'application/vnd.google-apps.folder' and trashed = false",
        spaces: 'appDataFolder',
      );
      
      if (folderList.files != null && folderList.files!.isNotEmpty) {
        return folderList.files!.first.id;
      }
      
      final folder = drive.File()
        ..name = appFolderName
        ..mimeType = 'application/vnd.google-apps.folder'
        ..parents = ['appDataFolder'];
      
      final createdFolder = await _driveApi!.files.create(folder);
      return createdFolder.id;
    } catch (e) {
      if (kDebugMode) print('Ошибка при работе с папкой: $e');
      return null;
    }
  }
  
  // Загрузка файла из Google Drive
  Future<String?> downloadFile(String fileName) async {
    if (_driveApi == null) return null;
    
    try {
      final folderId = await _getOrCreateAppFolder();
      if (folderId == null) return null;
      
      final fileList = await _driveApi!.files.list(
        q: "name = '$fileName' and '$folderId' in parents and trashed = false",
        spaces: 'appDataFolder',
      );
      
      if (fileList.files == null || fileList.files!.isEmpty) {
        return null;
      }
      
      final fileId = fileList.files!.first.id;
      
      if (fileId == null || fileId.isEmpty) {
        if (kDebugMode) print('ID файла не найден');
        return null;
      }
      
      final response = await _driveApi!.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      );
      
      if (response is drive.Media) {
        final List<int> data = [];
        await for (final chunk in response.stream) {
          data.addAll(chunk);
        }

        return utf8.decode(data);
      } else {
        if (kDebugMode) print('Неожиданный тип ответа: ${response.runtimeType}');
        return null;
      }
    } catch (e) {
      if (kDebugMode) print('Ошибка загрузки файла $fileName: $e');
      return null;
    }
  }
  
  // Сохранение файла в Google Drive
  Future<bool> uploadFile(String fileName, String content) async {
    if (_driveApi == null) return false;
    
    try {
      final folderId = await _getOrCreateAppFolder();
      if (folderId == null) return false;
      
      final fileList = await _driveApi!.files.list(
        q: "name = '$fileName' and '$folderId' in parents and trashed = false",
        spaces: 'appDataFolder',
      );
      
      final bytes = utf8.encode(content);
      
      if (fileList.files != null && fileList.files!.isNotEmpty) {
        final fileId = fileList.files!.first.id;
        if (fileId != null && fileId.isNotEmpty) {
          final file = drive.File()
            ..name = fileName;
          
          await _driveApi!.files.update(
            file,
            fileId,
            uploadMedia: drive.Media(
              Stream.fromIterable([bytes]),
              bytes.length,
            ),
            addParents: folderId,
            removeParents: '',
          );
        }
      } else {
        final file = drive.File()
          ..name = fileName
          ..parents = [folderId];
        
        await _driveApi!.files.create(
          file,
          uploadMedia: drive.Media(
            Stream.fromIterable([bytes]),
            bytes.length,
          ),
        );
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) print('Ошибка сохранения файла $fileName: $e');
      return false;
    }
  }
  
  // Синхронизация: загружаем данные с Google Drive
  Future<Map<String, String?>> syncFromDrive() async {
    final settingsContent = await downloadFile(settingsFileName);
    final listContent = await downloadFile(listFileName);
    
    return {
      'settings': settingsContent,
      'list': listContent,
    };
  }
  
  // Синхронизация: сохраняем данные в Google Drive
  Future<bool> syncToDrive(String settingsYaml, String listYaml) async {
    final settingsUploaded = await uploadFile(settingsFileName, settingsYaml);
    final listUploaded = await uploadFile(listFileName, listYaml);
    
    return settingsUploaded && listUploaded;
  }
  
  // Загрузка всех данных с Drive
  Future<bool> restoreFromDrive() async {
    final data = await syncFromDrive();
    
    if (data['settings'] != null && data['settings']!.isNotEmpty && 
        data['list'] != null && data['list']!.isNotEmpty) {
      try {
        final settingsYaml = loadYaml(data['settings']!);
        final listYaml = loadYaml(data['list']!);
        
        if (settingsYaml is Map) {
          await StorageService.writeYamlFile(settingsFileName, Map<String, dynamic>.from(settingsYaml));
        }
        if (listYaml is Map) {
          await StorageService.writeYamlFile(listFileName, Map<String, dynamic>.from(listYaml));
        }
        return true;
      } catch (e) {
        if (kDebugMode) print('Ошибка восстановления данных: $e');
        return false;
      }
    }
    return false;
  }
  
  // Проверка наличия данных в Google Drive
  Future<bool> hasDataInDrive() async {
    if (_driveApi == null) return false;
    
    try {
      final folderId = await _getOrCreateAppFolder();
      if (folderId == null) return false;
      
      final fileList = await _driveApi!.files.list(
        q: "('$folderId' in parents) and trashed = false",
        spaces: 'appDataFolder',
      );
      
      return fileList.files != null && fileList.files!.isNotEmpty;
    } catch (e) {
      if (kDebugMode) print('Ошибка проверки данных: $e');
      return false;
    }
  }
}