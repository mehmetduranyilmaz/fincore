import 'package:fincore_app/features/app_shell/presentation/constants/app_shell_strings.dart';
import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/core/widgets/app_button.dart';
import 'package:fincore_app/core/widgets/app_card.dart';
import 'package:fincore_app/core/widgets/app_section_header.dart';
import 'package:fincore_app/features/settings/presentation/controllers/backup_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(backupControllerProvider);
    ref.listen(backupControllerProvider, (previous, next) {
      if (next.message == null || next.message == previous?.message) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(next.message!),
            backgroundColor: next.isError
                ? Theme.of(context).colorScheme.error
                : null,
          ),
        );
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppSectionHeader(title: AppShellStrings.settings),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Verilerinizi koruyun ve gerektiğinde başka bir kuruluma taşıyın.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.lg),
          _BackupActionCard(
            icon: Icons.cloud_upload_outlined,
            title: 'Şifreli Yedek Oluştur',
            description:
                'Hesap, kart, müşteri, kategori, bütçe, ekstre ve işlem '
                'kayıtlarını parola korumalı bir dosyaya aktarır. Oturum '
                'bilgileri yedeğe eklenmez.',
            buttonLabel: 'Yedekle',
            isLoading: state.operation == BackupOperation.creating,
            isEnabled: !state.isBusy,
            onPressed: () => _createBackup(context, ref),
          ),
          const SizedBox(height: AppSpacing.md),
          _BackupActionCard(
            icon: Icons.settings_backup_restore,
            title: 'Yedekten Geri Yükle',
            description:
                'Seçtiğiniz Fincore yedeği mevcut finansal kayıtların yerine '
                'yüklenir. Yanlış parola veya bozuk dosya değişiklik yapmaz.',
            buttonLabel: 'Geri Yükle',
            isLoading: state.operation == BackupOperation.restoring,
            isEnabled: !state.isBusy,
            onPressed: () => _restoreBackup(context, ref),
          ),
          const SizedBox(height: AppSpacing.md),
          const AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Yedek dosyasını ve parolasını ayrı, güvenli yerlerde '
                    'saklayın. Parola unutulursa dosya açılamaz.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createBackup(BuildContext context, WidgetRef ref) async {
    final password = await _showPasswordDialog(
      context,
      title: 'Yedek Parolası',
      confirmPassword: true,
    );
    if (password == null || !context.mounted) return;
    await ref.read(backupControllerProvider.notifier).create(password);
  }

  Future<void> _restoreBackup(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mevcut kayıtlar değiştirilsin mi?'),
        content: const Text(
          'Geri yükleme, telefondaki finansal kayıtların tamamını seçilen '
          'yedekteki kayıtlarla değiştirecektir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Devam Et'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final password = await _showPasswordDialog(
      context,
      title: 'Yedek Parolası',
      confirmPassword: false,
    );
    if (password == null || !context.mounted) return;
    await ref.read(backupControllerProvider.notifier).restore(password);
  }

  Future<String?> _showPasswordDialog(
    BuildContext context, {
    required String title,
    required bool confirmPassword,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          _PasswordDialog(title: title, confirmPassword: confirmPassword),
    );
  }
}

final class _BackupActionCard extends StatelessWidget {
  const _BackupActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.isLoading,
    required this.isEnabled,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String description;
  final String buttonLabel;
  final bool isLoading;
  final bool isEnabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 28),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(description),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: AppButton(
              label: buttonLabel,
              icon: icon,
              isLoading: isLoading,
              isEnabled: isEnabled,
              onPressed: onPressed,
            ),
          ),
        ],
      ),
    );
  }
}

final class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog({required this.title, required this.confirmPassword});

  final String title;
  final bool confirmPassword;

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

final class _PasswordDialogState extends State<_PasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              key: const Key('backup_password'),
              controller: _passwordController,
              obscureText: _obscure,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Parola',
                helperText: 'En az 8 karakter',
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure ? Icons.visibility_outlined : Icons.visibility_off,
                  ),
                ),
              ),
              validator: (value) =>
                  (value?.length ?? 0) < 8 ? 'En az 8 karakter girin.' : null,
            ),
            if (widget.confirmPassword) ...[
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                key: const Key('backup_password_confirmation'),
                controller: _confirmationController,
                obscureText: _obscure,
                decoration: const InputDecoration(labelText: 'Parola Tekrarı'),
                validator: (value) => value != _passwordController.text
                    ? 'Parolalar eşleşmiyor.'
                    : null,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          key: const Key('backup_password_submit'),
          onPressed: () {
            if (_formKey.currentState?.validate() != true) return;
            Navigator.pop(context, _passwordController.text);
          },
          child: Text(widget.confirmPassword ? 'Yedekle' : 'Dosya Seç'),
        ),
      ],
    );
  }
}
