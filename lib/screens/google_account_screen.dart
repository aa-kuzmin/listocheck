import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:universal_html/html.dart' as html;
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/providers_service.dart';

class GoogleAccountScreen extends ConsumerStatefulWidget {
  const GoogleAccountScreen({super.key});

  @override
  ConsumerState<GoogleAccountScreen> createState() => _GoogleAccountScreenState();
}

class _GoogleAccountScreenState extends ConsumerState<GoogleAccountScreen> {
  bool _isLoading = false;
  bool _isLoadingFiles = false;
  bool _isDeletingAll = false;
  List<Map<String, dynamic>> _driveFiles = [];
  bool _showFiles = false;

  String _shortenString(String str, int maxLength) {
    if (str.length <= maxLength) return str;
    return str.substring(0, maxLength);
  }

  Future<void> _loadDriveFiles() async {
    if (_isLoadingFiles) return;
    
    setState(() {
      _isLoadingFiles = true;
      _driveFiles = [];
    });
    
    try {
      final driveService = ref.read(googleDriveServiceProvider);
      if (!driveService.isAuthenticated) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Аккаунт не подключен')),
          );
        }
        return;
      }
      
      final driveApi = driveService.driveApi;
      if (driveApi == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Drive API не доступен')),
          );
        }
        return;
      }
      
      final folderId = await driveService.getOrCreateAppFolder();
      if (folderId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Не удалось найти папку приложения')),
          );
        }
        return;
      }
      
      final fileList = await driveApi.files.list(
        q: "('$folderId' in parents) and trashed = false",
        spaces: 'appDataFolder',
      );
      
      if (fileList.files != null && fileList.files!.isNotEmpty) {
        setState(() {
          _driveFiles = fileList.files!.map((file) {
            int size = 0;
            final sizeStr = file.size;
            if (sizeStr != null && sizeStr.isNotEmpty) {
              try {
                size = int.tryParse(sizeStr) ?? 0;
              } catch (e) {
                size = 0;
              }
            }
            
            String modifiedTime = 'Неизвестно';
            try {
              if (file.modifiedTime != null) {
                final time = file.modifiedTime!.toLocal();
                modifiedTime = time.toString();
              }
            } catch (e) {
              modifiedTime = 'Неизвестно';
            }
            
            return {
              'id': file.id ?? '',
              'name': file.name ?? 'Без имени',
              'mimeType': file.mimeType ?? '',
              'createdTime': file.createdTime?.toLocal().toString() ?? 'Неизвестно',
              'modifiedTime': modifiedTime,
              'size': size,
            };
          }).toList();
        });
      } else {
        setState(() {
          _driveFiles = [];
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('В Drive нет файлов')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки файлов: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingFiles = false;
        });
      }
    }
  }

  Future<void> _downloadFile(String fileId, String fileName) async {
    try {
      final driveService = ref.read(googleDriveServiceProvider);
      final driveApi = driveService.driveApi;
      if (driveApi == null) return;
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Скачивание файла...'),
            ],
          ),
        ),
      );
      
      final response = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      );
      
      if (mounted) Navigator.pop(context);
      
      if (response is drive.Media) {
        final List<int> data = [];
        await for (final chunk in response.stream) {
          data.addAll(chunk);
        }
        
        if (kIsWeb) {
          _downloadFileWeb(data, fileName);
        } else {
          await _saveFileToDownloads(data, fileName);
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Файл "$fileName" успешно скачан!')),
          );
        }
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка скачивания: $e')),
        );
      }
    }
  }

  // ✅ Сохранение файлов с использованием Share Plus
  Future<void> _saveFileToDownloads(List<int> data, String fileName) async {
    try {
      // Сохраняем файл во временную папку
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(data);
      
      if (Platform.isAndroid || Platform.isIOS) {
        // Используем Share Plus для Android и iOS
        final result = await Share.shareXFiles(
          [XFile(tempFile.path, name: fileName)],
          text: 'Скачанный файл: $fileName',
        );
        
        if (result.status == ShareResultStatus.success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('✅ Файл сохранён успешно!')),
            );
          }
        } else {
          // Если пользователь отменил, показываем где файл сохранен
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('📁 Файл сохранён во временную папку: ${tempFile.path}')),
            );
          }
        }
      } else {
        // Для Desktop пытаемся сохранить в Downloads
        String? downloadsPath;
        
        if (Platform.isMacOS) {
          final home = Platform.environment['HOME'] ?? '';
          downloadsPath = '$home/Downloads';
        } else if (Platform.isWindows) {
          final userProfile = Platform.environment['USERPROFILE'] ?? '';
          downloadsPath = '$userProfile\\Downloads';
        } else if (Platform.isLinux) {
          final home = Platform.environment['HOME'] ?? '';
          downloadsPath = '$home/Downloads';
        }
        
        if (downloadsPath != null) {
          final downloadsDir = Directory(downloadsPath);
          if (await downloadsDir.exists()) {
            final finalFile = File('$downloadsPath/$fileName');
            await tempFile.copy(finalFile.path);
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('✅ Файл сохранён в: ${finalFile.path}')),
              );
            }
            return;
          }
        }
        
        // Fallback: Documents папка
        final appDocDir = await getApplicationDocumentsDirectory();
        final finalFile = File('${appDocDir.path}/$fileName');
        await tempFile.copy(finalFile.path);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('📁 Файл сохранён в: ${finalFile.path}')),
          );
        }
      }
    } catch (e) {
      // Если все else не сработало, оставляем во временной папке
      try {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(data);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('⚠️ Файл сохранён во временную папку: ${file.path}')),
          );
        }
      } catch (e2) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Ошибка сохранения: $e2')),
          );
        }
      }
    }
  }

  // 🌐 Веб: скачивание через браузер
  void _downloadFileWeb(List<int> data, String fileName) {
    try {
      final blob = html.Blob([data]);
      final url = html.Url.createObjectUrl(blob);
      final anchor = html.AnchorElement(href: url)
        ..download = fileName
        ..click();
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка скачивания в вебе: $e')),
        );
      }
    }
  }

  // 🗑️ Удаление всех файлов из Google Drive
  Future<void> _deleteAllFiles() async {
    if (_driveFiles.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Нет файлов для удаления')),
        );
      }
      return;
    }

    // Подтверждение удаления
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить все файлы?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Вы уверены, что хотите удалить все файлы из Google Drive?'),
            const SizedBox(height: 8),
            Text(
              'Будет удалено: ${_driveFiles.length} файлов',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Удалить все'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isDeletingAll = true;
    });

    try {
      final driveService = ref.read(googleDriveServiceProvider);
      final driveApi = driveService.driveApi;
      if (driveApi == null) {
        throw Exception('Drive API не доступен');
      }

      int deletedCount = 0;
      int errorCount = 0;

      // Показываем прогресс
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('Удаление файлов... (0/${_driveFiles.length})'),
            ],
          ),
        ),
      );

      for (int i = 0; i < _driveFiles.length; i++) {
        final file = _driveFiles[i];
        try {
          await driveApi.files.delete(file['id']);
          deletedCount++;
          
          // Обновляем прогресс
          if (mounted) {
            Navigator.pop(context);
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text('Удаление файлов... (${i + 1}/${_driveFiles.length})'),
                  ],
                ),
              ),
            );
          }
        } catch (e) {
          errorCount++;
          print('Ошибка удаления файла ${file['name']}: $e');
        }
      }

      if (mounted) Navigator.pop(context);

      await _loadDriveFiles();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Удалено: $deletedCount файлов, ошибок: $errorCount',
            ),
            backgroundColor: errorCount > 0 ? Colors.orange : Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Ошибка удаления: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeletingAll = false;
        });
      }
    }
  }

  void _showFileDetails(Map<String, dynamic> file) {
    final sizeInKB = (file['size'] / 1024).toStringAsFixed(2);
    final sizeInMB = (file['size'] / (1024 * 1024)).toStringAsFixed(2);
    final sizeStr = file['size'] > 1024 * 1024 
        ? '$sizeInMB MB' 
        : '$sizeInKB KB';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(file['name']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('ID', file['id']),
            _buildInfoRow('Тип', file['mimeType']),
            _buildInfoRow('Размер', sizeStr),
            _buildInfoRow('Создан', file['createdTime']),
            _buildInfoRow('Изменён', file['modifiedTime']),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _downloadFile(file['id'], file['name']);
            },
            icon: const Icon(Icons.download),
            label: const Text('Скачать'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _connectAccount(BuildContext context) async {
    final localizations = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);
    try {
      final driveService = ref.read(googleDriveServiceProvider);
      final success = await driveService.signIn();
      
      if (success) {
        ref.read(googleDriveAuthProvider.notifier).state = true;
        final account = driveService.getCurrentAccount();
        ref.read(googleDriveAccountProvider.notifier).state = account?.email;
        
        final listNotifier = ref.read(listProvider.notifier);
        final settingsNotifier = ref.read(settingsProvider.notifier);
        listNotifier.setDriveService(driveService);
        settingsNotifier.setDriveService(driveService);
        
        await listNotifier.loadList(force: true);
        await settingsNotifier.loadSettings(force: true);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(localizations.accLinkSuccess)),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(localizations.errAccLink)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${localizations.error}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _disconnectAccount(BuildContext context) async {
    final localizations = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);
    try {
      final driveService = ref.read(googleDriveServiceProvider);
      await driveService.signOut();
      
      ref.read(googleDriveAuthProvider.notifier).state = false;
      ref.read(googleDriveAccountProvider.notifier).state = null;
      
      final listNotifier = ref.read(listProvider.notifier);
      final settingsNotifier = ref.read(settingsProvider.notifier);
      listNotifier.setDriveService(null);
      settingsNotifier.setDriveService(null);
      
      setState(() {
        _driveFiles = [];
        _showFiles = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.accUnlinked)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${localizations.error}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isAuthenticated = ref.watch(googleDriveAuthProvider);
    final account = ref.watch(googleDriveAccountProvider);
    final initState = ref.watch(googleDriveInitializationProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.googleAccount),
        actions: [
          if (kDebugMode && isAuthenticated)
            IconButton(
              icon: _isLoadingFiles
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              onPressed: _isLoadingFiles ? null : _loadDriveFiles,
              tooltip: 'Обновить список файлов',
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (initState.isLoading) ...[
                  const Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Восстановление сессии...'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                
                Text(
                  localizations.googleSync,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  localizations.googleLink,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 32),
                
                if (isAuthenticated) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                localizations.accLinked,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                              Text(
                                account ?? localizations.unknown,
                                style: TextStyle(
                                  color: Colors.green.shade600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  if (kDebugMode) ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _showFiles = !_showFiles;
                              });
                              if (_showFiles && _driveFiles.isEmpty) {
                                _loadDriveFiles();
                              }
                            },
                            icon: Icon(_showFiles ? Icons.visibility_off : Icons.visibility),
                            label: Text(_showFiles ? 'Скрыть файлы Drive' : 'Показать файлы Drive'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(color: Colors.blue.shade300),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_showFiles && _driveFiles.isNotEmpty)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isDeletingAll ? null : _deleteAllFiles,
                              icon: _isDeletingAll
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.delete_forever, color: Colors.red),
                              label: Text(
                                _isDeletingAll ? 'Удаление...' : 'Удалить все',
                                style: const TextStyle(color: Colors.red),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: const BorderSide(color: Colors.red),
                                backgroundColor: Colors.red.shade50,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    if (_showFiles) ...[
                      if (_isLoadingFiles)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_driveFiles.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              'Файлы не найдены',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _driveFiles.length,
                            separatorBuilder: (context, index) => Divider(
                              height: 1,
                              color: Colors.grey.shade200,
                            ),
                            itemBuilder: (context, index) {
                              final file = _driveFiles[index];
                              final isYaml = file['name'].endsWith('.yaml') || 
                                            file['name'].endsWith('.yml');
                              final isJson = file['name'].endsWith('.json');
                              final iconColor = isYaml 
                                  ? Colors.orange.shade700
                                  : isJson
                                      ? Colors.blue.shade700
                                      : Colors.grey.shade600;
                              final iconData = isYaml
                                  ? Icons.description
                                  : isJson
                                      ? Icons.code
                                      : Icons.insert_drive_file;
                              
                              return ListTile(
                                leading: Icon(
                                  iconData,
                                  color: iconColor,
                                  size: 28,
                                ),
                                title: Text(
                                  file['name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(
                                  '${(file['size'] / 1024).toStringAsFixed(1)} KB • '
                                  '${_shortenString(file['modifiedTime'], 16)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.info_outline,
                                        size: 20,
                                      ),
                                      onPressed: () => _showFileDetails(file),
                                      tooltip: 'Информация',
                                      constraints: const BoxConstraints(
                                        minWidth: 32,
                                        minHeight: 32,
                                      ),
                                      padding: EdgeInsets.zero,
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.download,
                                        color: Colors.blue,
                                        size: 20,
                                      ),
                                      onPressed: () => _downloadFile(
                                        file['id'],
                                        file['name'],
                                      ),
                                      tooltip: 'Скачать',
                                      constraints: const BoxConstraints(
                                        minWidth: 32,
                                        minHeight: 32,
                                      ),
                                      padding: EdgeInsets.zero,
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                      onPressed: () => _deleteSingleFile(file),
                                      tooltip: 'Удалить файл',
                                      constraints: const BoxConstraints(
                                        minWidth: 32,
                                        minHeight: 32,
                                      ),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ],
                                ),
                                onTap: () => _showFileDetails(file),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 16),
                    ],
                  ],
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : () => _disconnectAccount(context),
                      icon: const Icon(Icons.logout),
                      label: Text(localizations.unlinkAccount),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cloud_off, color: Colors.grey),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            localizations.accNotLinked,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : () => _connectAccount(context),
                      icon: const Icon(Icons.account_circle),
                      label: Text(localizations.googleLinkAccount),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
                
                const SizedBox(height: 32),
                if (isAuthenticated) ...[
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.sync, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          localizations.dataSyncOnSaving,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🗑️ Удаление одного файла
  Future<void> _deleteSingleFile(Map<String, dynamic> file) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить файл?'),
        content: Text('Вы уверены, что хотите удалить "${file['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final driveService = ref.read(googleDriveServiceProvider);
      final driveApi = driveService.driveApi;
      if (driveApi == null) return;

      await driveApi.files.delete(file['id']);
      
      setState(() {
        _driveFiles.removeWhere((f) => f['id'] == file['id']);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Файл "${file['name']}" удалён'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Ошибка удаления: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}