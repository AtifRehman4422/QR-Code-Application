import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/qr_code_model.dart';
import '../utils/file_storage.dart';
import '../utils/qr_scanner.dart';
import '../widgets/qr_card.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _query = '';
  List<QrCodeModel> _list = [];
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _list = FileStorage.getAllQr(search: _query.isEmpty ? null : _query);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _content(QrCodeModel model) {
    return model.isEncrypted
        ? FileStorage.getDecryptedContent(model)
        : model.content;
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          if (_list.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              onPressed: () async {
                final confirm = await Get.dialog<bool>(
                  AlertDialog(
                    title: const Text('Clear history?'),
                    content: const Text(
                      'This will remove all scan and generate history.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Get.back(result: false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Get.back(result: true),
                        child: Text('Clear', style: TextStyle(color: theme.colorScheme.error)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await FileStorage.clearAll();
                  _load();
                }
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search history...',
                prefixIcon: const Icon(Icons.search_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (v) {
                setState(() {
                  _query = v;
                  _load();
                });
              },
            ),
          ),
          Expanded(
            child: _list.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 64,
                          color: theme.colorScheme.onSurface.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _query.isEmpty
                              ? 'No QR history yet'
                              : 'No results for "$_query"',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _list.length,
                    itemBuilder: (context, index) {
                      final model = _list[index];
                      final content = _content(model);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: QrCard(
                          model: model,
                          displayContent: content,
                          isDark: isDark,
                          analyticsCount: FileStorage.getScanCountForContent(content),
                          onTap: () {
                            Get.bottomSheet(
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(20),
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      content,
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        if (!(model.expiresAt != null && DateTime.now().isAfter(model.expiresAt!)) &&
                                            content.trim().toLowerCase().startsWith('http'))
                                          TextButton.icon(
                                            onPressed: () {
                                              Get.back();
                                              _openLink(content);
                                            },
                                            icon: const Icon(Icons.open_in_browser),
                                            label: const Text('Open'),
                                          ),
                                        if (!(model.expiresAt != null && DateTime.now().isAfter(model.expiresAt!)))
                                          TextButton.icon(
                                            onPressed: () {
                                              Share.share(content);
                                              Get.back();
                                            },
                                            icon: const Icon(Icons.share_rounded),
                                            label: const Text('Share'),
                                          ),
                                        if (model.expiresAt != null && DateTime.now().isAfter(model.expiresAt!))
                                          TextButton.icon(
                                            onPressed: () {},
                                            icon: const Icon(Icons.timer_off_rounded),
                                            label: const Text('Expired'),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          onDelete: () async {
                            await FileStorage.deleteQr(model.id);
                            _load();
                          },
                          onShare: () => Share.share(content),
                          onToggleFavorite: () async {
                            await FileStorage.setFavorite(model.id, !model.isFavorite);
                            _load();
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
