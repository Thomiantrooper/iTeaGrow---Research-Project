import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iteagrow/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';

class ContactUsPageSimple extends StatefulWidget {
  const ContactUsPageSimple({super.key});

  @override
  State<ContactUsPageSimple> createState() => _ContactUsPageSimpleState();
}

class _ContactUsPageSimpleState extends State<ContactUsPageSimple> {
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.contact_title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ContactInfoCard(
              icon: Icons.email_outlined,
              title: l10n.contact_email,
              value: l10n.contact_email_value,
            ),

            const SizedBox(height: 16),

            _ContactInfoCard(
              icon: Icons.phone_outlined,
              title: l10n.contact_phone,
              value: l10n.contact_phone_value,
            ),

            const SizedBox(height: 16),

            _ContactInfoCard(
              icon: Icons.location_on_outlined,
              title: l10n.contact_address,
              value: l10n.contact_address_value,
            ),

            const SizedBox(height: 32),

            Text(
              l10n.contact_feedback,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _messageController,
              decoration: InputDecoration(
                labelText: l10n.contact_message,
                hintText: l10n.contact_message_hint,
              ),
              maxLines: 5,
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.contact_message_sent),
                      backgroundColor: AppTheme.statusGood,
                    ),
                  );
                  _messageController.clear();
                },
                child: Text(l10n.contact_send),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _ContactInfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppTheme.primaryGreen, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
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
