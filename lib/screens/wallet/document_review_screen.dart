import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_text_styles.dart';
import '../../features/wallet/ocr/document_classifier.dart';
import '../../features/wallet/ocr/document_field_extractor.dart';
import '../../features/wallet/ocr/document_ocr_service.dart';
import '../../features/wallet/services/document_expiry_service.dart';
import '../../features/wallet/services/document_vault_service.dart';
import '../../features/wallet/services/image_processing_service.dart';
import '../../features/wallet/security/secure_number_service.dart';
import '../../providers/wallet_document_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/design_system/reusable_card.dart';
import '../../widgets/design_system/primary_button.dart';
import '../../widgets/design_system/secondary_button.dart';
import '../../widgets/design_system/app_form_field.dart';

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

  String? _rawFullDocumentNumber;
  String _selectedCategory = 'other';
  DateTime? _issueDate;
  DateTime? _expiryDate;
  bool _isFavorite = false;

  DocumentClassificationResult? _classificationResult;
  ExtractedFields? _extractedFields;
  bool _isSaving = false;
  bool _showUnclassifiedText = false;

  final List<Map<String, String>> _categories = [
    {'value': 'debit_card', 'label': 'Debit Card'},
    {'value': 'credit_card', 'label': 'Credit Card'},
    {'value': 'aadhaar', 'label': 'Aadhaar Card'},
    {'value': 'pan', 'label': 'PAN Card'},
    {'value': 'driving_license', 'label': 'Driving Licence'},
    {'value': 'passport', 'label': 'Passport'},
    {'value': 'voter_id', 'label': 'Voter ID'},
    {'value': 'rc', 'label': 'Vehicle RC'},
    {'value': 'insurance', 'label': 'Insurance Policy'},
    {'value': 'bank_document', 'label': 'Bank Document'},
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
    setState(() {
      _isProcessingOcr = true;
      _ocrError = null;
    });

    try {
      // 1. Generate enhanced version in background if it's an image
      if (widget.mimeType.startsWith('image/')) {
        _enhancedBytes = _imageProcessor.enhanceDocument(widget.originalBytes);
      }

      // 2. Run on-device OCR
      final ocrResult = await _ocrEngine.processImageBytes(
        widget.originalBytes,
        mimeType: widget.mimeType,
      );

      if (!ocrResult.isSuccess || ocrResult.fullText.trim().isEmpty) {
        setState(() {
          _isProcessingOcr = false;
          if (!ocrResult.isSuccess) {
            _ocrError = ocrResult.errorMessage ?? 'Unable to extract text from document';
          }
          if (_titleController.text.isEmpty) {
            _titleController.text = 'Scanned Document';
          }
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
        _extractedFields = fields;
        _selectedCategory = classification.category;

        _holderController.text = fields.holderName ?? '';
        _docNumberController.text = fields.documentNumber ?? '';
        _rawFullDocumentNumber = fields.rawDocumentNumber ?? fields.documentNumber;
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
        _ocrError = 'OCR Error: ${e.toString()}';
        if (_titleController.text.isEmpty) {
          _titleController.text = 'Scanned Document';
        }
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
      final finalBytes = (_useEnhancedImage && _enhancedBytes != null)
          ? _enhancedBytes!
          : widget.originalBytes;

      // Construct structured description preserving all mapped & unmapped fields
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
      if (_extractedFields?.cardNetwork != null) {
        descBuffer.writeln('Network: ${_extractedFields!.cardNetwork}');
      }
      if (_extractedFields?.issuingBank != null) {
        descBuffer.writeln('Bank: ${_extractedFields!.issuingBank}');
      }
      if (_extractedFields?.fatherName != null) {
        descBuffer.writeln("Father's Name: ${_extractedFields!.fatherName}");
      }
      if (_extractedFields?.vehicleCategories != null) {
        descBuffer.writeln('Vehicle Class: ${_extractedFields!.vehicleCategories}');
      }
      if (_extractedFields?.policyType != null) {
        descBuffer.writeln('Policy Type: ${_extractedFields!.policyType}');
      }
      if (_extractedFields?.accountNumber != null) {
        descBuffer.writeln('Account No: ${_extractedFields!.accountNumber}');
      }
      if (_extractedFields?.ifscCode != null) {
        descBuffer.writeln('IFSC: ${_extractedFields!.ifscCode}');
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

      // Save unmasked full document number in secure hardware storage
      final fullNumber = _rawFullDocumentNumber ?? _docNumberController.text.trim();
      if (fullNumber.isNotEmpty) {
        await SecureNumberService().saveDocumentFullNumber(savedDoc.id, fullNumber);
      }

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
            content: Text('Document encrypted & saved to Vault'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
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
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _cancel() {
    try {
      final f = File(widget.originalFilePath);
      if (f.existsSync()) f.deleteSync();
    } catch (_) {}
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final surfaceColor = AppColors.getSurface(context);
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        title: Text(
          'Review & Encrypt',
          style: AppTextStyles.headingSmall.copyWith(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: _cancel,
        ),
      ),
      body: _isSaving
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Encrypting document with AES-256-GCM...',
                    style: AppTextStyles.bodyMedium.copyWith(color: textPrimary, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Storing in hardware-backed keystore vault',
                    style: AppTextStyles.caption.copyWith(color: textSecondary),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Document Preview Card
                    _buildPreviewCard(context),
                    const SizedBox(height: AppSpacing.md),

                    // OCR Processing Status & Classification Banner
                    _buildClassificationBanner(context),
                    const SizedBox(height: AppSpacing.md),

                    // Form Fields Header
                    Text(
                      'Extracted Details',
                      style: AppTextStyles.headingSmall.copyWith(color: textPrimary, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    AppFormField(
                      controller: _titleController,
                      label: 'Document Title',
                      prefixIcon: Icons.title_rounded,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Title is required' : null,
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Category Selector
                    Container(
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.getBorder(context)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCategory,
                          isExpanded: true,
                          dropdownColor: surfaceColor,
                          style: AppTextStyles.bodyMedium.copyWith(color: textPrimary),
                          items: _categories.map((c) {
                            return DropdownMenuItem(
                              value: c['value'],
                              child: Row(
                                children: [
                                  const Icon(Icons.category_outlined, size: 18, color: AppColors.primary),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(c['label']!),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedCategory = val;
                                // Re-run field extraction for newly selected category if full text is available
                                if (_extractedFields?.rawFullText.isNotEmpty == true) {
                                  final newFields = _fieldExtractor.extract(
                                    rawText: _extractedFields!.rawFullText,
                                    category: val,
                                  );
                                  _extractedFields = newFields;
                                  if (newFields.holderName != null) _holderController.text = newFields.holderName!;
                                  if (newFields.documentNumber != null) _docNumberController.text = newFields.documentNumber!;
                                  if (newFields.issuer != null) _issuerController.text = newFields.issuer!;
                                }
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    AppFormField(
                      controller: _holderController,
                      label: 'Document Holder / Name',
                      prefixIcon: Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    AppFormField(
                      controller: _docNumberController,
                      label: 'Document Number / ID',
                      prefixIcon: Icons.badge_outlined,
                      onChanged: (val) {
                        _rawFullDocumentNumber = val;
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    AppFormField(
                      controller: _issuerController,
                      label: 'Issuing Authority / Agency / Bank',
                      prefixIcon: Icons.account_balance_outlined,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Dates Section (Issue & Expiry)
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(context, false),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                border: Border.all(color: AppColors.getBorder(context)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Issue Date', style: AppTextStyles.caption.copyWith(color: textSecondary)),
                                  const SizedBox(height: 4),
                                  Text(
                                    _issueDate != null ? dateFormat.format(_issueDate!) : 'Not set',
                                    style: AppTextStyles.bodyMedium.copyWith(color: textPrimary, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(context, true),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                border: Border.all(
                                  color: _expiryDate != null ? AppColors.primary.withAlpha(100) : AppColors.getBorder(context),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Expiry Date', style: AppTextStyles.caption.copyWith(color: textSecondary)),
                                      if (_expiryDate != null)
                                        InkWell(
                                          onTap: () => setState(() => _expiryDate = null),
                                          child: Icon(Icons.close_rounded, size: 14, color: textSecondary),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _expiryDate != null ? dateFormat.format(_expiryDate!) : 'No Expiry',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: _expiryDate != null ? AppColors.primary : textSecondary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    AppFormField(
                      controller: _descriptionController,
                      label: 'Additional Notes / Extracted Details (Optional)',
                      prefixIcon: Icons.notes_rounded,
                      maxLines: 2,
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Favorite Toggle
                    Container(
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.getBorder(context)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                                color: _isFavorite ? Colors.amber : textSecondary,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                'Pin to Favorites',
                                style: AppTextStyles.bodyMedium.copyWith(color: textPrimary),
                              ),
                            ],
                          ),
                          Switch(
                            value: _isFavorite,
                            onChanged: (val) => setState(() => _isFavorite = val),
                            activeThumbColor: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Unclassified OCR Text Section
                    if (_extractedFields != null && _extractedFields!.unclassifiedLines.isNotEmpty)
                      _buildUnclassifiedSection(context),

                    const SizedBox(height: AppSpacing.lg),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: SecondaryButton(
                            label: 'Cancel',
                            onPressed: _cancel,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          flex: 2,
                          child: PrimaryButton(
                            label: 'Confirm & Encrypt',
                            icon: Icons.lock_outline_rounded,
                            onPressed: _confirmAndEncrypt,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPreviewCard(BuildContext context) {
    final isPdf = widget.mimeType.contains('pdf');
    final activeBytes = (_useEnhancedImage && _enhancedBytes != null)
        ? _enhancedBytes!
        : widget.originalBytes;

    return ReusableCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.photo_outlined, size: 18, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.xs),
                  Text('Document Scan', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              if (!isPdf && _enhancedBytes != null)
                Row(
                  children: [
                    Text('Enhance Filter', style: AppTextStyles.caption),
                    const SizedBox(width: 4),
                    Switch(
                      value: _useEnhancedImage,
                      onChanged: (val) => setState(() => _useEnhancedImage = val),
                      activeThumbColor: AppColors.primary,
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: isPdf
                ? Container(
                    height: 160,
                    color: AppColors.primary.withAlpha(15),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.picture_as_pdf_rounded, size: 54, color: AppColors.primary),
                          SizedBox(height: AppSpacing.xs),
                          Text('Multi-Page PDF Attached', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  )
                : Image.memory(
                    activeBytes,
                    height: 200,
                    fit: BoxFit.contain,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassificationBanner(BuildContext context) {
    if (_isProcessingOcr) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(20),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.primary.withAlpha(60)),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'Analyzing document with on-device ML Kit OCR...',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    if (_ocrError != null) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.warning.withAlpha(20),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.warning.withAlpha(80)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 20),
                const SizedBox(width: AppSpacing.sm),
                const Expanded(
                  child: Text(
                    'OCR Incomplete or Ambiguous',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.warning),
                  ),
                ),
                TextButton(
                  onPressed: _runOcrAndClassification,
                  child: const Text('Retry OCR'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Text could not be automatically mapped. You can enter document details manually below.',
              style: AppTextStyles.caption,
            ),
          ],
        ),
      );
    }

    final conf = _classificationResult?.confidence ?? 0.0;
    final confPercent = (conf * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(20),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primary.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Identified as ${_classificationResult?.displayCategoryName ?? "Document"} ($confPercent% confidence)',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          if (_classificationResult?.reasons.isNotEmpty == true) ...[
            const SizedBox(height: 4),
            Text(
              'Matched: ${_classificationResult!.reasons.join(" • ")}',
              style: AppTextStyles.caption.copyWith(fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUnclassifiedSection(BuildContext context) {
    final lines = _extractedFields!.unclassifiedLines;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.getBorder(context)),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.text_snippet_outlined, size: 18, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Text('Unclassified OCR Lines (${lines.length})', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              IconButton(
                icon: Icon(
                  _showUnclassifiedText ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                ),
                onPressed: () => setState(() => _showUnclassifiedText = !_showUnclassifiedText),
              ),
            ],
          ),
          if (_showUnclassifiedText) ...[
            const Divider(),
            ...lines.take(8).map((line) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(line, style: AppTextStyles.caption),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      tooltip: 'Copy line',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: line));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied to clipboard'), duration: Duration(seconds: 1)),
                        );
                      },
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
