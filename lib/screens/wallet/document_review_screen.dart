import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../features/wallet/ocr/document_classifier.dart';
import '../../features/wallet/ocr/document_field_extractor.dart';
import '../../features/wallet/ocr/document_ocr_service.dart';
import '../../features/wallet/services/document_expiry_service.dart';
import '../../features/wallet/services/document_vault_service.dart';
import '../../features/wallet/services/image_processing_service.dart';
import '../../providers/wallet_document_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/glass_container.dart';

class DocumentReviewScreen extends StatefulWidget {
  final Uint8List originalBytes;
  final String originalFilePath;
  final String mimeType;
  final DocumentOcrEngine? ocrEngine;
  final DocumentVaultService? vaultService;
  final DocumentExpiryService? expiryService;
  final ImageProcessingService? imageProcessor;

  const DocumentReviewScreen({
    super.key,
    required this.originalBytes,
    required this.originalFilePath,
    this.mimeType = 'image/jpeg',
    this.ocrEngine,
    this.vaultService,
    this.expiryService,
    this.imageProcessor,
  });

  @override
  State<DocumentReviewScreen> createState() => _DocumentReviewScreenState();
}

class _DocumentReviewScreenState extends State<DocumentReviewScreen> {
  late final DocumentOcrEngine _ocrEngine;
  late final DocumentClassifier _classifier;
  late final DocumentFieldExtractor _fieldExtractor;
  late final DocumentVaultService _vaultService;
  late final DocumentExpiryService _expiryService;
  late final ImageProcessingService _imageProcessor;

  bool _isProcessingOcr = true;
  String? _ocrError;
  bool _useEnhancedImage = false;
  Uint8List? _enhancedBytes;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _holderController;
  late final TextEditingController _docNumberController;
  late final TextEditingController _issuerController;
  late final TextEditingController _descriptionController;

  String _selectedCategory = 'other';
  DateTime? _issueDate;
  DateTime? _expiryDate;
  bool _isFavorite = false;

  DocumentClassificationResult? _classificationResult;
  bool _isSaving = false;

  final List<Map<String, String>> _categories = [
    {'value': 'aadhaar', 'label': 'Aadhaar Card'},
    {'value': 'pan', 'label': 'PAN Card'},
    {'value': 'driving_license', 'label': 'Driving Licence'},
    {'value': 'passport', 'label': 'Passport'},
    {'value': 'rc', 'label': 'Vehicle RC'},
    {'value': 'insurance', 'label': 'Insurance Policy'},
    {'value': 'college_id', 'label': 'College / Student ID'},
    {'value': 'certificate', 'label': 'Certificate'},
    {'value': 'other', 'label': 'Other / General'},
  ];

  @override
  void initState() {
    super.initState();
    _ocrEngine = widget.ocrEngine ?? MlKitOcrEngine();
    _classifier = DocumentClassifier();
    _fieldExtractor = DocumentFieldExtractor();
    _vaultService = widget.vaultService ?? DocumentVaultService();
    _expiryService = widget.expiryService ?? DocumentExpiryService();
    _imageProcessor = widget.imageProcessor ?? ImageProcessingService();

    _titleController = TextEditingController();
    _holderController = TextEditingController();
    _docNumberController = TextEditingController();
    _issuerController = TextEditingController();
    _descriptionController = TextEditingController();

    _runOcrAndClassification();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _holderController.dispose();
    _docNumberController.dispose();
    _issuerController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _runOcrAndClassification() async {
    setState(() => _isProcessingOcr = true);

    try {
      // 1. Generate enhanced version in background if it's an image
      if (widget.mimeType.startsWith('image/')) {
        _enhancedBytes = _imageProcessor.enhanceDocument(widget.originalBytes);
      }

      // 2. Run on-device OCR
      final ocrResult = await _ocrEngine.processImageBytes(widget.originalBytes);
      if (!ocrResult.isSuccess) {
        setState(() {
          _isProcessingOcr = false;
          _ocrError = ocrResult.errorMessage ?? 'Unable to extract text from document';
          _titleController.text = 'Scanned Document';
        });
        return;
      }

      // 3. Classify document deterministically
      final classification = _classifier.classify(ocrResult.fullText);

      // 4. Extract structured fields
      final fields = _fieldExtractor.extract(
        rawText: ocrResult.fullText,
        category: classification.category,
      );

      setState(() {
        _classificationResult = classification;
        _selectedCategory = classification.category;

        _holderController.text = fields.holderName ?? '';
        _docNumberController.text = fields.documentNumber ?? '';
        _issuerController.text = fields.issuer ?? '';
        _issueDate = fields.issueDate;
        _expiryDate = fields.expiryDate;

        // Auto-generate sensible title
        if (fields.holderName != null && fields.holderName!.isNotEmpty) {
          _titleController.text = '${classification.displayCategoryName} - ${fields.holderName}';
        } else {
          _titleController.text = classification.displayCategoryName;
        }

        _isProcessingOcr = false;
      });
    } catch (e) {
      setState(() {
        _isProcessingOcr = false;
        _ocrError = e.toString();
        _titleController.text = 'Scanned Document';
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isExpiry) async {
    final initialDate = isExpiry
        ? (_expiryDate ?? DateTime.now().add(const Duration(days: 365)))
        : (_issueDate ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1950),
      lastDate: DateTime(2060),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.surface,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isExpiry) {
          _expiryDate = picked;
        } else {
          _issueDate = picked;
        }
      });
    }
  }

  Future<void> _confirmAndEncrypt() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // Determine final byte payload based on enhancement toggle
      final finalBytes = (_useEnhancedImage && _enhancedBytes != null)
          ? _enhancedBytes!
          : widget.originalBytes;

      // Construct description including holder name and doc number if present
      final descBuffer = StringBuffer();
      if (_holderController.text.trim().isNotEmpty) {
        descBuffer.writeln('Holder: ${_holderController.text.trim()}');
      }
      if (_docNumberController.text.trim().isNotEmpty) {
        descBuffer.writeln('Number: ${_docNumberController.text.trim()}');
      }
      if (_issuerController.text.trim().isNotEmpty) {
        descBuffer.writeln('Issuer: ${_issuerController.text.trim()}');
      }
      if (_descriptionController.text.trim().isNotEmpty) {
        descBuffer.writeln(_descriptionController.text.trim());
      }

      // 1. Encrypt and store through DocumentVaultService (AES-256-GCM)
      final savedDoc = await _vaultService.importDocument(
        documentName: _titleController.text.trim(),
        category: _selectedCategory,
        mimeType: widget.mimeType,
        fileBytes: finalBytes,
        description: descBuffer.isEmpty ? null : descBuffer.toString().trim(),
        issueDate: _issueDate,
        expiryDate: _expiryDate,
        isFavorite: _isFavorite,
      );

      // 2. Schedule reminders if expiry date is present
      if (_expiryDate != null) {
        await _expiryService.scheduleRemindersForDocument(savedDoc);
      }

      // 3. Clean up the unencrypted temporary staging file safely
      try {
        final originalFile = File(widget.originalFilePath);
        if (await originalFile.exists()) {
          await originalFile.delete();
        }
      } catch (_) {}

      // 4. Refresh Providers
      if (mounted) {
        try {
          context.read<WalletDocumentProvider>().loadDocuments();
          context.read<WalletProvider>().loadWallet();
        } catch (_) {}

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document encrypted & stored in Secure Vault'),
            backgroundColor: AppColors.success,
          ),
        );

        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Encryption error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _cancel() {
    // Delete temp unencrypted file
    try {
      final f = File(widget.originalFilePath);
      if (f.existsSync()) f.deleteSync();
    } catch (_) {}
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Review & Encrypt', style: AppTextStyles.heading3),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _cancel,
        ),
      ),
      body: _isSaving
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text(
                    'Encrypting document with AES-256-GCM...',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Document Preview Card with Enhancement Toggle
                    _buildPreviewCard(),
                    const SizedBox(height: 16),

                    // OCR Status & Classification Banner
                    _buildClassificationBanner(),
                    const SizedBox(height: 16),

                    // Legal Disclaimer
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber.withAlpha(50)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.amber, size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              DocumentClassificationResult.legalDisclaimer,
                              style: TextStyle(fontSize: 11, color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Form Fields
                    Text('Document Details', style: AppTextStyles.heading3),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Document Title',
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 12),

                    // Category Selector
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: _categories.map((c) {
                        return DropdownMenuItem(
                          value: c['value'],
                          child: Text(c['label']!),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCategory = val);
                      },
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _holderController,
                      decoration: const InputDecoration(
                        labelText: 'Document Holder Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _docNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Document Number / ID',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _issuerController,
                      decoration: const InputDecoration(
                        labelText: 'Issuing Authority / Agency',
                        prefixIcon: Icon(Icons.account_balance_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Dates Section
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(context, false),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Issue Date', style: TextStyle(fontSize: 11, color: Colors.white54)),
                                  const SizedBox(height: 4),
                                  Text(
                                    _issueDate != null ? dateFormat.format(_issueDate!) : 'Not specified',
                                    style: const TextStyle(fontSize: 13, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(context, true),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Expiry Date', style: TextStyle(fontSize: 11, color: Colors.white54)),
                                      if (_expiryDate != null)
                                        InkWell(
                                          onTap: () => setState(() => _expiryDate = null),
                                          child: const Icon(Icons.close, size: 14, color: Colors.white54),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _expiryDate != null ? dateFormat.format(_expiryDate!) : 'No Expiry',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: _expiryDate != null ? AppColors.primary : Colors.white70,
                                      fontWeight: _expiryDate != null ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Notes / Description (Optional)',
                        prefixIcon: Icon(Icons.notes),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Favorite Checkbox
                    SwitchListTile(
                      value: _isFavorite,
                      onChanged: (val) => setState(() => _isFavorite = val),
                      title: const Text('Add to Favorites', style: TextStyle(color: Colors.white, fontSize: 14)),
                      activeThumbColor: AppColors.primary,
                      activeTrackColor: AppColors.primary.withAlpha(80),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _cancel,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: Colors.white24),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: _confirmAndEncrypt,
                            icon: const Icon(Icons.lock_outline, size: 18),
                            label: const Text('Confirm & Encrypt'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPreviewCard() {
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 220,
              width: double.infinity,
              color: Colors.black45,
              child: widget.mimeType.startsWith('image/')
                  ? Image.memory(
                      (_useEnhancedImage && _enhancedBytes != null)
                          ? _enhancedBytes!
                          : widget.originalBytes,
                      fit: BoxFit.contain,
                    )
                  : const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 48),
                          SizedBox(height: 8),
                          Text('Scanned PDF Document', style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
            ),
          ),
          if (widget.mimeType.startsWith('image/') && _enhancedBytes != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Enhance Text Legibility',
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('Original')),
                    ButtonSegment(value: true, label: Text('Enhanced')),
                  ],
                  selected: {_useEnhancedImage},
                  onSelectionChanged: (set) {
                    setState(() => _useEnhancedImage = set.first);
                  },
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.selected) ? Colors.black : Colors.white70,
                    ),
                    backgroundColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.selected) ? AppColors.primary : Colors.transparent,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildClassificationBanner() {
    if (_isProcessingOcr) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
            SizedBox(width: 12),
            Text(
              'Running on-device OCR & classification...',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (_ocrError != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.error.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error.withAlpha(60)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _ocrError!,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    if (_classificationResult == null) return const SizedBox.shrink();

    final result = _classificationResult!;
    final confidencePercent = (result.confidence * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: result.isHighConfidence
            ? AppColors.primary.withAlpha(25)
            : Colors.amber.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: result.isHighConfidence
              ? AppColors.primary.withAlpha(60)
              : Colors.amber.withAlpha(60),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    result.isHighConfidence ? Icons.auto_awesome : Icons.help_outline,
                    color: result.isHighConfidence ? AppColors.primary : Colors.amber,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Detected: ${result.displayCategoryName}',
                    style: TextStyle(
                      color: result.isHighConfidence ? AppColors.primary : Colors.amber,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$confidencePercent% confidence',
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ),
            ],
          ),
          if (result.reasons.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Matched: ${result.reasons.join(", ")}',
              style: const TextStyle(fontSize: 11, color: Colors.white54),
            ),
          ],
        ],
      ),
    );
  }
}

