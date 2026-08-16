import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/generated/app_localizations.dart';

import '../services/providers_service.dart';

class GoogleAccountScreen extends ConsumerStatefulWidget {
  const GoogleAccountScreen({super.key});

  @override
  ConsumerState<GoogleAccountScreen> createState() => _GoogleAccountScreenState();
}

class _GoogleAccountScreenState extends ConsumerState<GoogleAccountScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isAuthenticated = ref.watch(googleDriveAuthProvider);
    final account = ref.watch(googleDriveAccountProvider);
    final initState = ref.watch(googleDriveInitializationProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.googleAccount),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Показываем индикатор загрузки при восстановлении
                if (initState.isLoading) ...[
                  Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(localizations.sessionRestoration),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                
                Text(
                  localizations.googleSync,
                  style: TextStyle(
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
                
                // Всегда показываем статус аккаунта
                if (isAuthenticated) ...[
                  // Аккаунт подключен
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
                  // Аккаунт не подключен
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.cloud_off, color: Colors.grey),
                        SizedBox(width: 12),
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
        
        // Обновляем провайдеры с сервисом Drive
        final listNotifier = ref.read(listProvider.notifier);
        final settingsNotifier = ref.read(settingsProvider.notifier);
        listNotifier.setDriveService(driveService);
        settingsNotifier.setDriveService(driveService);
        
        // Перезагружаем данные из Drive
        await listNotifier.loadList();
        await settingsNotifier.loadSettings();
        
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
      
      // Отключаем Drive сервис
      final listNotifier = ref.read(listProvider.notifier);
      final settingsNotifier = ref.read(settingsProvider.notifier);
      listNotifier.setDriveService(null);
      settingsNotifier.setDriveService(null);
      
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
}
