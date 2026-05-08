import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.queueCount,
    required this.keptCount,
    required this.onClearQueue,
    required this.onResetKept,
  });

  final int queueCount;
  final int keptCount;
  final VoidCallback onClearQueue;
  final VoidCallback onResetKept;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          ListTile(
            title: const Text('Galeri izin ayarlarını aç'),
            subtitle: const Text('Sistem izin ekranını açar'),
            trailing: const Icon(Icons.open_in_new_rounded),
            onTap: PhotoManager.openSetting,
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('Silme kuyruğunu temizle'),
            subtitle: Text('$queueCount öğe sırada'),
            trailing: const Icon(Icons.delete_sweep_outlined),
            onTap: queueCount == 0
                ? null
                : () => _confirm(
                    context,
                    title: 'Kuyruk temizlensin mi?',
                    body: 'Kuyruktaki öğeler silinmez, sadece listeden çıkar.',
                    confirmLabel: 'Temizle',
                    onConfirm: onClearQueue,
                    successText: 'Kuyruk temizlendi',
                  ),
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('Tutulanları sıfırla'),
            subtitle: Text(
              keptCount == 0
                  ? 'Henüz tutulan öğe yok'
                  : '$keptCount öğe tekrar deste başına gelir',
            ),
            trailing: const Icon(Icons.restart_alt_rounded),
            onTap: keptCount == 0
                ? null
                : () => _confirm(
                    context,
                    title: 'Tutulanlar sıfırlansın mı?',
                    body:
                        'Sağa atarak "tut" dediğin öğeler tekrar deste başına gelir.',
                    confirmLabel: 'Sıfırla',
                    onConfirm: onResetKept,
                    successText: 'Tutulanlar sıfırlandı',
                  ),
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('Rehberi tekrar göster'),
            subtitle: const Text('Uygulama içi tanıtım turunu yeniden başlat'),
            trailing: const Icon(Icons.help_outline_rounded),
            onTap: () => Navigator.of(context).pop('restart_tour'),
          ),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Text(
            'Picme',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Hızlı galeri temizliği. Kuyruktaki ve tutulan öğeler uygulama kapansa da korunur.',
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Future<void> _confirm(
    BuildContext context, {
    required String title,
    required String body,
    required String confirmLabel,
    required String successText,
    required VoidCallback onConfirm,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      onConfirm();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successText)));
    }
  }
}
