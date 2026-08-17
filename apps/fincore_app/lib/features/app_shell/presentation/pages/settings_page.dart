import 'package:fincore_app/features/app_shell/presentation/constants/app_shell_strings.dart';
import 'package:fincore_app/core/errors/error_mapper.dart';
import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/core/widgets/app_button.dart';
import 'package:fincore_app/core/widgets/app_card.dart';
import 'package:fincore_app/core/widgets/app_section_header.dart';
import 'package:fincore_app/features/settings/domain/entities/automatic_backup_configuration.dart';
import 'package:fincore_app/features/settings/domain/errors/backup_exception.dart';
import 'package:fincore_app/features/settings/presentation/controllers/automatic_backup_controller.dart';
import 'package:fincore_app/features/settings/presentation/controllers/backup_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(backupControllerProvider);
    final automaticBackup = ref.watch(automaticBackupControllerProvider);
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
    ref.listen(automaticBackupControllerProvider, (previous, next) {
      if (!next.hasError || previous?.error == next.error) return;
      _showMessage(context, _errorMessage(next.error!), isError: true);
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
          if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) ...[
            automaticBackup.when(
              loading: () => const AppCard(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stackTrace) => _AutomaticBackupErrorCard(
                message: _errorMessage(error),
                onRetry: () =>
                    ref.invalidate(automaticBackupControllerProvider),
              ),
              data: (overview) => _AutomaticBackupCard(
                overview: overview,
                onConfigure: () => _configureAutomaticBackup(
                  context,
                  ref,
                  overview.configuration,
                ),
                onRunNow: () => _runAutomaticBackupNow(context, ref),
                onDisable: () => _disableAutomaticBackup(context, ref),
                onRestore: () => _restoreAutomaticSnapshot(context, ref),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
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

  Future<void> _configureAutomaticBackup(
    BuildContext context,
    WidgetRef ref,
    AutomaticBackupConfiguration? current,
  ) async {
    final target = await ref
        .read(automaticBackupControllerProvider.notifier)
        .selectTarget(initialUri: current?.targetUri);
    if (target == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: current?.hour ?? 2,
        minute: current?.minute ?? 0,
      ),
      helpText: 'Günlük yedekleme saati',
      confirmText: 'Seç',
      cancelText: 'Vazgeç',
    );
    if (time == null || !context.mounted) return;
    final password = await _showPasswordDialog(
      context,
      title: 'Otomatik Yedek Parolası',
      confirmPassword: true,
    );
    if (password == null || !context.mounted) return;
    final succeeded = await ref
        .read(automaticBackupControllerProvider.notifier)
        .enable(
          target: target,
          password: password,
          hour: time.hour,
          minute: time.minute,
        );
    if (succeeded && context.mounted) {
      _showMessage(
        context,
        'Otomatik yedekleme açıldı ve ilk yedek oluşturuldu.',
      );
    }
  }

  Future<void> _runAutomaticBackupNow(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final succeeded = await ref
        .read(automaticBackupControllerProvider.notifier)
        .runNow();
    if (succeeded && context.mounted) {
      _showMessage(context, 'Şifreli yedek başarıyla güncellendi.');
    }
  }

  Future<void> _disableAutomaticBackup(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Otomatik yedekleme kapatılsın mı?'),
        content: const Text(
          'Zamanlanmış görev ve klasör izni kaldırılır. Daha önce oluşturulan '
          'yedek dosyası silinmez.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final succeeded = await ref
        .read(automaticBackupControllerProvider.notifier)
        .disable();
    if (succeeded && context.mounted) {
      _showMessage(context, 'Otomatik yedekleme kapatıldı.');
    }
  }

  Future<void> _restoreAutomaticSnapshot(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Son otomatik yedek geri yüklensin mi?'),
        content: const Text(
          'Telefondaki finansal kayıtlar son otomatik yedekteki kayıtlarla '
          'değiştirilecektir.',
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
      title: 'Otomatik Yedek Parolası',
      confirmPassword: false,
    );
    if (password == null || !context.mounted) return;
    final restored = await ref
        .read(automaticBackupControllerProvider.notifier)
        .restoreLocalSnapshot(password);
    if (restored && context.mounted) {
      _showMessage(context, 'Son otomatik yedek başarıyla geri yüklendi.');
    }
  }

  static void _showMessage(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
        ),
      );
  }

  static String _errorMessage(Object error) {
    return error is BackupException ? error.message : ErrorMapper.map(error);
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

final class _AutomaticBackupCard extends StatelessWidget {
  const _AutomaticBackupCard({
    required this.overview,
    required this.onConfigure,
    required this.onRunNow,
    required this.onDisable,
    required this.onRestore,
  });

  final AutomaticBackupOverview overview;
  final VoidCallback onConfigure;
  final VoidCallback onRunNow;
  final VoidCallback onDisable;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final configuration = overview.configuration;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.cloud_sync_outlined, size: 28),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Otomatik Şifreli Yedek',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              _StatusChip(enabled: configuration != null),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Her gün tek bir tam yedek oluşturur ve seçtiğiniz cihaz veya '
            'Google Drive klasöründeki önceki dosyanın üzerine yazar. Android '
            'arka plan kısıtlamaları nedeniyle saat yaklaşık çalışır.',
          ),
          if (configuration != null) ...[
            const SizedBox(height: AppSpacing.md),
            _InfoLine(
              icon: Icons.schedule_outlined,
              label: 'Her gün yaklaşık ${configuration.timeLabel}',
            ),
            _InfoLine(
              icon: Icons.folder_outlined,
              label: configuration.targetName,
            ),
            if (configuration.lastSuccessAt != null)
              _InfoLine(
                icon: Icons.check_circle_outline,
                label:
                    'Son başarılı: ${_dateTime(configuration.lastSuccessAt!)}',
                color: Colors.green,
              ),
            if (configuration.lastError != null)
              _InfoLine(
                icon: Icons.error_outline,
                label: configuration.lastError!,
                color: Theme.of(context).colorScheme.error,
              ),
          ],
          if (overview.localSnapshotAvailable) ...[
            const SizedBox(height: AppSpacing.sm),
            TextButton.icon(
              key: const Key('restore_automatic_snapshot'),
              onPressed: onRestore,
              icon: const Icon(Icons.restore),
              label: const Text('Son Otomatik Yedeği Geri Yükle'),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (configuration != null)
                TextButton.icon(
                  key: const Key('disable_automatic_backup'),
                  onPressed: onDisable,
                  icon: const Icon(Icons.pause_circle_outline),
                  label: const Text('Kapat'),
                ),
              if (configuration != null)
                OutlinedButton.icon(
                  key: const Key('run_automatic_backup_now'),
                  onPressed: onRunNow,
                  icon: const Icon(Icons.sync),
                  label: const Text('Şimdi Yedekle'),
                ),
              FilledButton.icon(
                key: const Key('configure_automatic_backup'),
                onPressed: onConfigure,
                icon: Icon(
                  configuration == null ? Icons.tune : Icons.edit_outlined,
                ),
                label: Text(configuration == null ? 'Yapılandır' : 'Değiştir'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Parola telefonda güvenli depoda tutulur ve Android sistem '
            'yedeğine eklenmez. Yeni cihazda geri yükleme için parolayı '
            'hatırlamanız gerekir.',
          ),
        ],
      ),
    );
  }

  static String _dateTime(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(value.day)}.${two(value.month)}.${value.year} '
        '${two(value.hour)}:${two(value.minute)}';
  }
}

final class _AutomaticBackupErrorCard extends StatelessWidget {
  const _AutomaticBackupErrorCard({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Otomatik yedekleme bilgileri okunamadı.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(message),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
            ),
          ),
        ],
      ),
    );
  }
}

final class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(enabled ? Icons.check_circle : Icons.pause_circle, size: 18),
      label: Text(enabled ? 'Açık' : 'Kapalı'),
      visualDensity: VisualDensity.compact,
    );
  }
}

final class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(label, style: TextStyle(color: color)),
          ),
        ],
      ),
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
