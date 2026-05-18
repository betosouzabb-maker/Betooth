import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';
import '../../domain/entities/upload_entity.dart';
import '../controllers/upload_controller.dart';
import '../../../subscription/presentation/controllers/subscription_controller.dart';
import '../../../subscription/presentation/widgets/vip_paywall_bottom_sheet.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class UploadPage extends ConsumerStatefulWidget {
  const UploadPage({super.key});

  @override
  ConsumerState<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends ConsumerState<UploadPage> {
  final _titleController = TextEditingController();
  final _artistController = TextEditingController();
  final _albumController = TextEditingController();
  final _genreController = TextEditingController();
  String _privacy = 'public';

  PlatformFile? _selectedFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVip());
  }

  Future<void> _checkVip() async {
    if (!mounted) return;
    
    // Admins bypass VIP check
    final user = ref.read(authControllerProvider).user;
    if (user?.role == 'ADMIN') {
      return;
    }
    
    final subController = ref.read(subscriptionControllerProvider.notifier);
    await subController.refresh();
    if (!mounted) return;
    final isVip = ref.read(subscriptionControllerProvider).isVip;
    if (!isVip) {
      await showVipPaywallBottomSheet(context);
      if (!mounted) return;
      // If user still isn't VIP after paywall, navigate back
      final stillVip = ref.read(subscriptionControllerProvider).isVip;
      if (!stillVip) {
        context.pop();
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _albumController.dispose();
    _genreController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
      withData: false,
      withReadStream: false,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() => _selectedFile = result.files.first);
    }
  }

  Future<String> _computeChecksum(String path) async {
    final file = File(path);
    final bytes = await file.readAsBytes();
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  String _getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'mp3':
        return 'audio/mpeg';
      case 'mp4':
        return 'video/mp4';
      case 'm4a':
        return 'audio/x-m4a';
      case 'wav':
        return 'audio/wav';
      case 'flac':
        return 'audio/flac';
      case 'ogg':
        return 'audio/ogg';
      default:
        return 'audio/mpeg';
    }
  }

  Future<void> _startUpload() async {
    final file = _selectedFile;
    if (file == null || file.path == null) return;

    setState(() => _isLoading = true);

    try {
      final checksum = await _computeChecksum(file.path!);
      final ext = file.extension ?? 'mp3';
      final mimeType = _getMimeType(ext);

      await ref.read(uploadControllerProvider.notifier).startUpload(
            filePath: file.path!,
            fileName: file.name,
            mimeType: mimeType,
            sizeBytes: file.size,
            checksum: checksum,
            title: _titleController.text.trim().isEmpty
                ? null
                : _titleController.text.trim(),
            artist: _artistController.text.trim().isEmpty
                ? null
                : _artistController.text.trim(),
            album: _albumController.text.trim().isEmpty
                ? null
                : _albumController.text.trim(),
            genre: _genreController.text.trim().isEmpty
                ? null
                : _genreController.text.trim(),
            privacy: _privacy,
          );

      if (mounted) {
        setState(() => _selectedFile = null);
        _titleController.clear();
        _artistController.clear();
        _albumController.clear();
        _genreController.clear();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uploads = ref.watch(
      uploadControllerProvider.select((s) => s.items),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Upload',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DropZoneCard(
              selectedFile: _selectedFile,
              onTap: _isLoading ? null : _pickFile,
            ),
            const SizedBox(height: 24),
            if (_selectedFile != null) ...[
              _MetadataForm(
                titleController: _titleController,
                artistController: _artistController,
                albumController: _albumController,
                genreController: _genreController,
                privacy: _privacy,
                onPrivacyChanged: (v) => setState(() => _privacy = v ?? 'public'),
              ),
              const SizedBox(height: 20),
              _UploadButton(
                isLoading: _isLoading,
                onPressed: _startUpload,
              ),
              const SizedBox(height: 32),
            ],
            if (uploads.isNotEmpty) ...[
              const Text(
                'Uploads',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...uploads.map(
                (item) => _UploadItemCard(
                  key: ValueKey(item.localId),
                  item: item,
                  onCancel: () => ref
                      .read(uploadControllerProvider.notifier)
                      .cancelUpload(item.localId),
                  onRemove: () => ref
                      .read(uploadControllerProvider.notifier)
                      .removeItem(item.localId),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DropZoneCard extends StatelessWidget {
  const _DropZoneCard({
    required this.selectedFile,
    required this.onTap,
  });

  final PlatformFile? selectedFile;
  final VoidCallback? onTap;

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selectedFile != null
                ? AppColors.primaryAccent
                : AppColors.textSecondary.withValues(alpha: 0.3),
            width: selectedFile != null ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryAccent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                selectedFile != null
                    ? Icons.audio_file_rounded
                    : Icons.cloud_upload_rounded,
                color: AppColors.primaryAccent,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            if (selectedFile != null) ...[
              Text(
                selectedFile!.name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${_formatBytes(selectedFile!.size)}  •  ${selectedFile!.extension?.toUpperCase() ?? ''}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Toque para trocar o arquivo',
                style: TextStyle(
                  color: AppColors.primaryAccent.withValues(alpha: 0.8),
                  fontSize: 13,
                ),
              ),
            ] else ...[
              const Text(
                'Selecione um arquivo de áudio',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'MP3, MP4, M4A, WAV, FLAC, OGG • Máx. 100 MB',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetadataForm extends StatelessWidget {
  const _MetadataForm({
    required this.titleController,
    required this.artistController,
    required this.albumController,
    required this.genreController,
    required this.privacy,
    required this.onPrivacyChanged,
  });

  final TextEditingController titleController;
  final TextEditingController artistController;
  final TextEditingController albumController;
  final TextEditingController genreController;
  final String privacy;
  final ValueChanged<String?> onPrivacyChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Metadados (opcional)',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _InputField(controller: titleController, label: 'Título'),
          const SizedBox(height: 12),
          _InputField(controller: artistController, label: 'Artista'),
          const SizedBox(height: 12),
          _InputField(controller: albumController, label: 'Álbum'),
          const SizedBox(height: 12),
          _InputField(controller: genreController, label: 'Gênero'),
          const SizedBox(height: 16),
          const Text(
            'Privacidade',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _PrivacyChip(
                label: 'Público',
                icon: Icons.public_rounded,
                selected: privacy == 'public',
                onTap: () => onPrivacyChanged('public'),
              ),
              const SizedBox(width: 10),
              _PrivacyChip(
                label: 'Privado',
                icon: Icons.lock_rounded,
                selected: privacy == 'private',
                onTap: () => onPrivacyChanged('private'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primaryAccent, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

class _PrivacyChip extends StatelessWidget {
  const _PrivacyChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryAccent.withValues(alpha: 0.15)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.primaryAccent
                : AppColors.textSecondary.withValues(alpha: 0.3),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color:
                  selected ? AppColors.primaryAccent : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? AppColors.primaryAccent
                    : AppColors.textSecondary,
                fontSize: 13,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UploadButton extends StatelessWidget {
  const _UploadButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primaryAccent, AppColors.secondaryAccent],
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: isLoading ? null : onPressed,
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.upload_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Enviar música',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UploadItemCard extends StatelessWidget {
  const _UploadItemCard({
    super.key,
    required this.item,
    required this.onCancel,
    required this.onRemove,
  });

  final UploadItem item;
  final VoidCallback onCancel;
  final VoidCallback onRemove;

  String _formatBytes(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Color _statusColor() {
    switch (item.status) {
      case UploadStatus.completed:
        return AppColors.secondaryAccent;
      case UploadStatus.failed:
      case UploadStatus.cancelled:
        return Colors.redAccent;
      case UploadStatus.processing:
        return Colors.orange;
      default:
        return AppColors.primaryAccent;
    }
  }

  String _statusLabel() {
    switch (item.status) {
      case UploadStatus.uploading:
        return 'Enviando…';
      case UploadStatus.processing:
        return 'Processando…';
      case UploadStatus.completed:
        return 'Concluído';
      case UploadStatus.failed:
        return 'Erro';
      case UploadStatus.cancelled:
        return 'Cancelado';
      default:
        return 'Aguardando';
    }
  }

  IconData _statusIcon() {
    switch (item.status) {
      case UploadStatus.completed:
        return Icons.check_circle_rounded;
      case UploadStatus.failed:
      case UploadStatus.cancelled:
        return Icons.error_rounded;
      case UploadStatus.processing:
        return Icons.autorenew_rounded;
      default:
        return Icons.upload_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActive = item.status == UploadStatus.uploading ||
        item.status == UploadStatus.processing;
    final isDone = item.status == UploadStatus.completed ||
        item.status == UploadStatus.failed ||
        item.status == UploadStatus.cancelled;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _statusColor().withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_statusIcon(), color: _statusColor(), size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title ?? item.fileName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_formatBytes(item.sizeBytes)}  •  ${_statusLabel()}',
                      style: TextStyle(
                        color: _statusColor(),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isActive)
                GestureDetector(
                  onTap: onCancel,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.close_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                ),
              if (isDone)
                GestureDetector(
                  onTap: onRemove,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.close_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
          if (isActive) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: item.progress > 0 ? item.progress : null,
                backgroundColor: AppColors.surface,
                valueColor: AlwaysStoppedAnimation<Color>(
                  item.status == UploadStatus.processing
                      ? Colors.orange
                      : AppColors.primaryAccent,
                ),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item.status == UploadStatus.processing
                  ? 'Processando metadados…'
                  : '${(item.progress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
          if (item.status == UploadStatus.failed &&
              item.errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              item.errorMessage!,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
