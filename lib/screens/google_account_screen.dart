import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

//import '../services/google_drive_service.dart';
//import '../services/providers_service.dart';
import '../main.dart';

class GoogleAccountScreen extends ConsumerStatefulWidget {
  const GoogleAccountScreen({super.key});

  @override
  ConsumerState<GoogleAccountScreen> createState() => _GoogleAccountScreenState();
}

class _GoogleAccountScreenState extends ConsumerState<GoogleAccountScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final driveService = ref.watch(googleDriveServiceProvider);
    final isAuthenticated = ref.watch(googleDriveAuthProvider);
    final account = ref.watch(googleDriveAccountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Аккаунт'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Синхронизация с Google',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Подключите ваш Google аккаунт для синхронизации списков и настроек между устройствами.',
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
                            'Подключен аккаунт',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                          Text(
                            account ?? 'Неизвестно',
                            style: TextStyle(
                              color: Colors.green.shade600,
                            ),
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
                  label: const Text('Отключить аккаунт'),
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
                child: const Row(
                  children: [
                    Icon(Icons.cloud_off, color: Colors.grey),
                    SizedBox(width: 12),
                    Text(
                      'Аккаунт не подключен',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
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
                  label: const Text('Подключить Google аккаунт'),
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
                  Text(
                    'Данные автоматически синхронизируются при сохранении',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _connectAccount(BuildContext context) async {
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
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Аккаунт успешно подключен!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка подключения аккаунта')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _disconnectAccount(BuildContext context) async {
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
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Аккаунт отключен')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
