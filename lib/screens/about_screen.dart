import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';

import '../constants.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
/*             Icon(
              Icons.info_outline,
              size: 80,
              color: Colors.grey,
            ),
 */            const SizedBox(height: 24),
            Text(
              localizations.aboutApp,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(24),
/*               decoration: BoxDecoration(
                border: Border.all(color: Colors.blue.shade200),
                borderRadius: BorderRadius.circular(12),
              ), */
              child: Column(
                children: [
                  Text(
                    '${localizations.appTitle.toUpperCase()}${localizations.aboutContentText}',
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
//                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
/*                       const Icon(
                        Icons.code,
                        size: 20,
                        color: Colors.grey,
                      ), */
                      const SizedBox(width: 8),
                      Text(
                        '${localizations.version}: ',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
/*                           decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ), */
                          child: Text(
                            appVersion,
                            style: const TextStyle(
                              fontSize: 16,
/*                               fontWeight: FontWeight.bold,
                              color: Colors.blue, */
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
