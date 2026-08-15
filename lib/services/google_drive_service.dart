import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:googleapis/drive/v3.dart' as drive;
//import 'package:googleapis_auth/auth_io.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:path_provider/path_provider.dart';
import 'package:yaml/yaml.dart';

// Импортируем StorageService для сохранения локально
import 'storage_service.dart';

import '../constants.dart';

class GoogleDriveService {
  
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveAppdataScope],
  );
  
  drive.DriveApi? _driveApi;
  bool _isAuthenticated = false;
  
  // Проверка авторизации
  bool get isAuthenticated => _isAuthenticated;
  
  // Вход в Google аккаунт
  Future<bool> signIn() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account != null) {
        final authClient = await _googleSignIn.authenticatedClient();
        if (authClient != null) {
          _driveApi = drive.DriveApi(authClient);
          _isAuthenticated = true;
          return true;
        }
      }
      return false;
    } catch (e) {
      if (kDebugMode) print('Ошибка входа в Google: $e');
      return false;
    }
  }
  
  // Выход из Google аккаунта
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _isAuthenticated = false;
    _driveApi = null;
  }
  
  // Получение текущего аккаунта
  GoogleSignInAccount? getCurrentAccount() {
    return _googleSignIn.currentUser;
  }
  
  // Проверка существования папки приложения
  Future<String?> _getOrCreateAppFolder() async {
    if (_driveApi == null) return null;
    
    try {
      // Ищем папку приложения
      final folderList = await _driveApi!.files.list(
        q: "name = '$appFolderName' and mimeType = 'application/vnd.google-apps.folder' and trashed = false",
        spaces: 'appDataFolder',
      );
      
      if (folderList.files != null && folderList.files!.isNotEmpty) {
        return folderList.files!.first.id;
      }
      
      // Создаем папку, если не существует
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
      
      // Ищем файл
      final fileList = await _driveApi!.files.list(
        q: "name = '$fileName' and '$folderId' in parents and trashed = false",
        spaces: 'appDataFolder',
      );
      
      if (fileList.files == null || fileList.files!.isEmpty) {
        return null;
      }
      
      final fileId = fileList.files!.first.id;
      
      // Проверяем, что fileId не null и не пустой
      if (fileId == null || fileId.isEmpty) {
        if (kDebugMode) print('ID файла не найден');
        return null;
      }
      
      // Скачиваем файл - передаем fileId как String
      final response = await _driveApi!.files.get(
        fileId, // теперь fileId точно String
        downloadOptions: drive.DownloadOptions.fullMedia,
      );
      
      // Проверяем тип ответа
      if (response is drive.Media) {
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/$fileName');
        
        // Читаем данные из потока
        final List<int> data = [];
        await for (final chunk in response.stream) {
          data.addAll(chunk);
        }
        
        await tempFile.writeAsBytes(data);
        final content = await tempFile.readAsString();
        await tempFile.delete();
        
        return content;
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
      
      // Ищем существующий файл
      final fileList = await _driveApi!.files.list(
        q: "name = '$fileName' and '$folderId' in parents and trashed = false",
        spaces: 'appDataFolder',
      );
      
      final file = drive.File()
        ..name = fileName
        ..parents = [folderId];
      
      // Конвертируем строку в байты
      final bytes = utf8.encode(content);
      
      if (fileList.files != null && fileList.files!.isNotEmpty) {
        // Обновляем существующий файл
        final fileId = fileList.files!.first.id;
        if (fileId != null && fileId.isNotEmpty) {
          await _driveApi!.files.update(
            file,
            fileId,
            uploadMedia: drive.Media(
              Stream.fromIterable([bytes]),
              bytes.length,
            ),
          );
        }
      } else {
        // Создаем новый файл
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
    
    // Проверяем, что данные не null и не пустые
    if (data['settings'] != null && data['settings']!.isNotEmpty && 
        data['list'] != null && data['list']!.isNotEmpty) {
      try {
        // Парсим YAML строки
        final settingsYaml = loadYaml(data['settings']!);
        final listYaml = loadYaml(data['list']!);
        
        // Сохраняем загруженные данные локально
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