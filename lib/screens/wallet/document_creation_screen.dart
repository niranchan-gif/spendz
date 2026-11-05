import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_text_styles.dart';
import '../../features/wallet/security/secure_number_service.dart';
import '../../features/wallet/security/wallet_key_service.dart';
import '../../features/wallet/services/document_scanner_service.dart';
import '../../features/wallet/services/document_vault_service.dart';
import '../../models/wallet_document_model.dart';
import '../../providers/wallet_document_provider.dart';
import '../../providers/wallet_provider.dart';
import 'document_attachment_scanner_screen.dart';
import 'widgets/virtual_document_card.dart';

/// Screen managing manual document creation and editing with dedicated category forms.
///
/// Workflow:
/// 1. Select Document Category
/// 2. Fill Dedicated Category Form (Strict validation, no CVV/PIN)
/// 3. Optionally attach original scanned image or PDF copy
/// 4. Live preview of individual Virtual Document Card
/// 5. AES-256-GCM Vault Encryption & Save
class DocumentCreationScreen extends StatefulWidget {
  final WalletDocumentModel? documentToEdit;
  final String? initialCategory;

  const DocumentCreationScreen({
    super.key,
    this.documentToEdit,
    this.initialCategory,
  });

  @override
  State<DocumentCreationScreen> createState() => _DocumentCreationScreenState();
}

class _DocumentCreationScreenState extends State<DocumentCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final DocumentVaultService _vaultService = DocumentVaultService();
  final SecureNumberService _secureNumberService = SecureNumberService();

  int _currentStep =
      0; // 0: Select Category, 1: Enter Details, 2: Preview & Save
  late String _selectedCategory;

  // Common Form Fields
  final _nameController = TextEditingController();
  final _holderController = TextEditingController();
  final _numberController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _issueDate;
  DateTime? _expiryDate;
  DateTime? _dob;

  // Category Specific Fields
  final _fatherNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _mobileController = TextEditingController();
  String _gender = 'Male';

  // DL Specific
  final _authorityController = TextEditingController();
  final _stateController = TextEditingController();
  final Set<String> _selectedVehicleClasses = {'LMV'};

  // Passport Specific
  final _nationalityController = TextEditingController(text: 'Indian');
  final _pobController = TextEditingController();
  final _poiController = TextEditingController();

  // Payment Card Specific
  final _bankController = TextEditingController();
  String _cardNetwork = 'Visa';
  String _cardType = 'debit_card';
  int _expiryMonth = DateTime.now().month;
  int _expiryYear = DateTime.now().year + 3;

  // Insurance Specific
  final _providerController = TextEditingController();
  String _policyType = 'Health Insurance';
  final _coverageController = TextEditingController();
  final _contactController = TextEditingController();

  // Attachment State
  final DocumentScannerService _scannerService = DocumentScannerService();
  DocumentAttachmentPayload? _attachmentPayload;
  bool _isSaving = false;

  final List<Map<String, dynamic>> _categories = [
    {
      'id': 'aadhaar',
      'title': 'Aadhaar Card',
      'subtitle': 'UIDAI • 12-Digit Identity',
      'icon': Icons.badge_outlined,
      'color': Color(0xFFFF9933),
    },
    {
      'id': 'pan',
      'title': 'PAN Card',
      'subtitle': 'Income Tax Dept • 10-Char Tax ID',
      'icon': Icons.credit_card_rounded,
      'color': Color(0xFF0284C7),
    },
    {
      'id': 'driving_license',
      'title': 'Driving Licence',
      'subtitle': 'Transport Dept • Motor Vehicle Licence',
      'icon': Icons.directions_car_outlined,
      'color': Color(0xFF16A34A),
    },
    {
      'id': 'passport',
      'title': 'Passport',
      'subtitle': 'Govt of India • International Travel',
      'icon': Icons.flight_takeoff_rounded,
      'color': Color(0xFF1E3A8A),
    },
    {
      'id': 'debit_card',
      'title': 'Debit / Credit Card',
      'subtitle': 'Bank Payment Card • Masked & Encrypted',
      'icon': Icons.payment_rounded,
      'color': Color(0xFF6366F1),
    },
    {
      'id': 'insurance',
      'title': 'Insurance Policy',
      'subtitle': 'Health, Motor, Life, Term & Travel',
      'icon': Icons.health_and_safety_outlined,
      'color': Color(0xFF0D9488),
    },
    {
      'id': 'other',
      'title': 'Other Document',
      'subtitle': 'RC, Certificates, College ID, Custom',
      'icon': Icons.description_outlined,
      'color': Color(0xFF64748B),
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory =
        widget.initialCategory ?? widget.documentToEdit?.category ?? 'aadhaar';

    if (widget.initialCategory != null || widget.documentToEdit != null) {
      _currentStep = 1;
    }

    if (widget.documentToEdit != null) {
      _populateFromExisting(widget.documentToEdit!);
    }
  }

  Future<void> _populateFromExisting(WalletDocumentModel doc) async {
    _selectedCategory = doc.category;
    final preferredName = doc.holderName?.isNotEmpty == true
        ? doc.holderName!
        : doc.documentName;
    _nameController.text = preferredName;
    _holderController.text = preferredName;
    _issueDate = doc.issueDate;
    _expiryDate = doc.expiryDate;

    // Retrieve unmasked number if stored
    final fullNumber = await _secureNumberService.getDocumentFullNumber(doc.id);
    _numberController.text = fullNumber ?? doc.maskedIdentifier ?? '';

    // Decrypt extra fields if present
    if (doc.encryptedFields != null && doc.encryptedFields!.isNotEmpty) {
      final extra = await _vaultService.decryptMetadataFields(
        doc.encryptedFields!,
      );
      _fatherNameController.text = extra['father_name'] ?? '';
      _addressController.text = extra['address'] ?? '';
      _mobileController.text = extra['mobile'] ?? '';
      if (extra['gender'] != null) _gender = extra['gender'];
      if (extra['dob'] != null) _dob = DateTime.tryParse(extra['dob']);

      _authorityController.text = extra['issuing_authority'] ?? '';
      _stateController.text = extra['state'] ?? '';
      if (extra['vehicle_classes'] != null) {
        _selectedVehicleClasses.clear();
        _selectedVehicleClasses.addAll(
          List<String>.from(extra['vehicle_classes']),
        );
      }

      _nationalityController.text = extra['nationality'] ?? 'Indian';
      _pobController.text = extra['place_of_birth'] ?? '';
      _poiController.text = extra['place_of_issue'] ?? '';

      _bankController.text = extra['bank_name'] ?? '';
      if (extra['card_network'] != null) _cardNetwork = extra['card_network'];
      if (extra['card_type'] != null) _cardType = extra['card_type'];

      _providerController.text = extra['provider_name'] ?? '';
      if (extra['policy_type'] != null) _policyType = extra['policy_type'];
      _coverageController.text = extra['coverage_amount']?.toString() ?? '';
      _contactController.text = extra['contact_info'] ?? '';
    }

    // Fallback: parse description lines if extra fields were not in encryptedFields
    if (doc.description != null && doc.description!.isNotEmpty) {
      final lines = doc.description!.split('\n');
      for (final line in lines) {
        final trimmed = line.trim();
        if (_fatherNameController.text.isEmpty &&
            trimmed.startsWith('Father:')) {
          _fatherNameController.text = trimmed
              .replaceFirst('Father:', '')
              .trim();
        } else if (_dob == null && trimmed.startsWith('DOB:')) {
          final rawDob = trimmed.replaceFirst('DOB:', '').trim();
          try {
            _dob = DateFormat('dd/MM/yyyy').parse(rawDob);
          } catch (_) {}
        } else if (_addressController.text.isEmpty &&
            trimmed.startsWith('Address:')) {
          _addressController.text = trimmed.replaceFirst('Address:', '').trim();
        } else if (_authorityController.text.isEmpty &&
            trimmed.startsWith('Issuer:')) {
          _authorityController.text = trimmed
              .replaceFirst('Issuer:', '')
              .trim();
        } else if (_stateController.text.isEmpty &&
            trimmed.startsWith('State:')) {
          _stateController.text = trimmed.replaceFirst('State:', '').trim();
        } else if (_providerController.text.isEmpty &&
            trimmed.startsWith('Provider:')) {
          _providerController.text = trimmed
              .replaceFirst('Provider:', '')
              .trim();
        } else if (_selectedVehicleClasses.isEmpty &&
            trimmed.startsWith('Vehicle Class:')) {
          final raw = trimmed.replaceFirst('Vehicle Class:', '').trim();
          _selectedVehicleClasses.addAll(
            raw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty),
          );
        }
      }
    }

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nameController.dispose();
    _holderController.dispose();
    _numberController.dispose();
    _nicknameController.dispose();
    _notesController.dispose();
    _fatherNameController.dispose();
    _addressController.dispose();
    _mobileController.dispose();
    _authorityController.dispose();
    _stateController.dispose();
    _nationalityController.dispose();
    _pobController.dispose();
    _poiController.dispose();
    _bankController.dispose();
    _providerController.dispose();
    _coverageController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  String _computeMaskedIdentifier(String raw) {
    final clean = raw.replaceAll(RegExp(r'\s+'), '').trim();
    if (clean.isEmpty) return '';

    switch (_selectedCategory) {
      case 'aadhaar':
        if (clean.length == 12) {
          return '•••• •••• ${clean.substring(8)}';
        }
        return '•••• •••• ${clean.length > 4 ? clean.substring(clean.length - 4) : clean}';

      case 'pan':
        if (clean.length == 10) {
          return '${clean.substring(0, 5)}••••${clean.substring(9)}';
        }
        return clean.length > 4
            ? '••••••${clean.substring(clean.length - 4)}'
            : clean;

      case 'driving_license':
        return clean.length > 4
            ? 'DL-••••${clean.substring(clean.length - 4)}'
            : clean;

      case 'passport':
        return clean.length > 3
            ? '${clean.substring(0, 1)}••••${clean.substring(clean.length - 3)}'
            : clean;

      case 'debit_card':
      case 'credit_card':
        if (clean.length >= 12) {
          return '•••• •••• •••• ${clean.substring(clean.length - 4)}';
        }
        return clean.length > 4
            ? '•••• ${clean.substring(clean.length - 4)}'
            : clean;

      case 'insurance':
        return clean.length > 4
            ? 'POL-••••${clean.substring(clean.length - 4)}'
            : clean;

      default:
        return clean.length > 4
            ? '••••${clean.substring(clean.length - 4)}'
            : clean;
    }
  }

  Future<void> _openAttachmentScanner() async {
    final result = await Navigator.push<DocumentAttachmentPayload?>(
      context,
      MaterialPageRoute(
        builder: (_) => DocumentAttachmentScannerScreen(
          category: _selectedCategory,
          suggestedTitle: _nameController.text.trim().isNotEmpty
              ? _nameController.text.trim()
              : null,
          initialPayload: _attachmentPayload,
        ),
      ),
    );

    if (result != null) {
      setState(() => _attachmentPayload = result);
    }
  }

  Future<void> _attachExistingPdf() async {
    final payload = await _scannerService.pickExistingDocument();
    if (payload != null) {
      setState(() => _attachmentPayload = payload);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Attached "${payload.fileName}" (${payload.pageCount} page(s), ${DocumentScannerService.formatFileSize(payload.calculatedSize)})',
            ),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  Future<void> _selectDate(
    BuildContext context, {
    required DateTime? initial,
    required ValueChanged<DateTime> onSelected,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(1920),
      lastDate: DateTime(2060),
    );
    if (picked != null) {
      onSelected(picked);
    }
  }

  void _proceedToPreview() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please correct the highlighted form errors before proceeding.',
          ),
        ),
      );
      return;
    }

    // Specific business validations
    if (_selectedCategory == 'driving_license' &&
        _issueDate != null &&
        _expiryDate != null) {
      if (_expiryDate!.isBefore(_issueDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Licence expiry date cannot precede the issue date.'),
          ),
        );
        return;
      }
    }

    if (_selectedCategory == 'passport' &&
        _issueDate != null &&
        _expiryDate != null) {
      if (_expiryDate!.isBefore(_issueDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Passport expiry date cannot precede the issue date.',
            ),
          ),
        );
        return;
      }
    }

    setState(() => _currentStep = 2);
  }

  Future<void> _saveDocument() async {
    setState(() => _isSaving = true);
    try {
      final rawPersonName = _nameController.text.trim().isNotEmpty
          ? _nameController.text.trim()
          : (_holderController.text.trim().isNotEmpty
                ? _holderController.text.trim()
                : null);

      final docTitle = rawPersonName != null
          ? (_selectedCategory == 'aadhaar'
                ? 'Aadhaar Card'
                : _selectedCategory == 'pan'
                ? 'PAN Card'
                : _selectedCategory == 'driving_license' ||
                      _selectedCategory == 'driving_licence'
                ? 'Driving Licence'
                : _selectedCategory == 'insurance'
                ? 'Health Insurance'
                : rawPersonName)
          : '${_selectedCategory.replaceAll('_', ' ').toUpperCase()} Document';

      final holder = rawPersonName;
      final rawNumber = _selectedCategory == 'pan'
          ? _numberController.text
                .replaceAll(RegExp(r'[\s\-]+'), '')
                .toUpperCase()
                .trim()
          : _numberController.text.trim();
      final masked = _computeMaskedIdentifier(rawNumber);

      // Pack extra metadata map for AES-256-GCM encryption
      final extraMap = <String, dynamic>{
        if (_fatherNameController.text.isNotEmpty)
          'father_name': _fatherNameController.text.trim(),
        if (_addressController.text.isNotEmpty)
          'address': _addressController.text.trim(),
        if (_mobileController.text.isNotEmpty)
          'mobile': _mobileController.text.trim(),
        if (_gender.isNotEmpty) 'gender': _gender,
        if (_dob != null) 'dob': _dob!.toIso8601String(),
        if (_authorityController.text.isNotEmpty)
          'issuing_authority': _authorityController.text.trim(),
        if (_stateController.text.isNotEmpty)
          'state': _stateController.text.trim(),
        if (_selectedVehicleClasses.isNotEmpty)
          'vehicle_classes': _selectedVehicleClasses.toList(),
        if (_nationalityController.text.isNotEmpty)
          'nationality': _nationalityController.text.trim(),
        if (_pobController.text.isNotEmpty)
          'place_of_birth': _pobController.text.trim(),
        if (_poiController.text.isNotEmpty)
          'place_of_issue': _poiController.text.trim(),
        if (_bankController.text.isNotEmpty)
          'bank_name': _bankController.text.trim(),
        if (_cardNetwork.isNotEmpty) 'card_network': _cardNetwork,
        if (_cardType.isNotEmpty) 'card_type': _cardType,
        if (_providerController.text.isNotEmpty)
          'provider_name': _providerController.text.trim(),
        if (_policyType.isNotEmpty) 'policy_type': _policyType,
        if (_coverageController.text.isNotEmpty)
          'coverage_amount': _coverageController.text.trim(),
        if (_contactController.text.isNotEmpty)
          'contact_info': _contactController.text.trim(),
      };

      // Construct description lines for backward compatible view rendering
      final descBuffer = StringBuffer();
      if (holder != null) descBuffer.writeln('Holder: $holder');
      if (masked.isNotEmpty) descBuffer.writeln('Number: $masked');
      if (_fatherNameController.text.isNotEmpty)
        descBuffer.writeln('Father: ${_fatherNameController.text.trim()}');
      if (_dob != null)
        descBuffer.writeln('DOB: ${DateFormat('dd/MM/yyyy').format(_dob!)}');
      if (_addressController.text.isNotEmpty)
        descBuffer.writeln('Address: ${_addressController.text.trim()}');
      if (_bankController.text.isNotEmpty)
        descBuffer.writeln('Bank: ${_bankController.text.trim()}');
      if (_cardNetwork.isNotEmpty) descBuffer.writeln('Network: $_cardNetwork');
      if (_providerController.text.isNotEmpty)
        descBuffer.writeln('Provider: ${_providerController.text.trim()}');
      if (_policyType.isNotEmpty) descBuffer.writeln('Type: $_policyType');
      if (_authorityController.text.isNotEmpty)
        descBuffer.writeln('Issuer: ${_authorityController.text.trim()}');
      if (_stateController.text.isNotEmpty)
        descBuffer.writeln('State: ${_stateController.text.trim()}');
      if (_selectedVehicleClasses.isNotEmpty)
        descBuffer.writeln(
          'Vehicle Class: ${_selectedVehicleClasses.join(', ')}',
        );
      if (_notesController.text.isNotEmpty)
        descBuffer.writeln('Notes: ${_notesController.text.trim()}');

      if (widget.documentToEdit != null) {
        // Updating existing document
        final existing = widget.documentToEdit!;
        await _vaultService.updateDocumentDetails(
          document: existing,
          documentName: docTitle,
          category: _selectedCategory,
          holderName: holder,
          maskedIdentifier: masked,
          unmaskedIdentifier: rawNumber,
          extraFields: extraMap,
          description: descBuffer.toString(),
          issueDate: _issueDate,
          expiryDate: _expiryDate,
        );

        // If new attachment was provided, attach it
        if (_attachmentPayload != null) {
          final bytes = _attachmentPayload!.primaryBytes;
          if (bytes.isNotEmpty) {
            await _vaultService.attachFileToDocument(
              document: existing,
              fileBytes: bytes,
              mimeType: _attachmentPayload!.mimeType,
              attachmentType: _attachmentPayload!.attachmentType,
            );
          }
        }
      } else {
        // Saving brand new document
        List<int>? attachBytes;
        String? attachMime;
        String? attachType;

        if (_attachmentPayload != null) {
          attachBytes = _attachmentPayload!.primaryBytes;
          attachMime = _attachmentPayload!.mimeType;
          attachType = _attachmentPayload!.attachmentType;
        }

        await _vaultService.saveManualDocument(
          documentName: docTitle,
          category: _selectedCategory,
          holderName: holder,
          maskedIdentifier: masked,
          unmaskedIdentifier: rawNumber,
          extraFields: extraMap,
          description: descBuffer.toString(),
          issueDate: _issueDate,
          expiryDate: _expiryDate,
          attachmentBytes: attachBytes,
          attachmentMimeType: attachMime,
          attachmentType: attachType,
        );
      }

      if (!mounted) return;
      await context.read<WalletDocumentProvider>().loadDocuments();
      try {
        await context.read<WalletProvider>().loadWallet();
      } catch (_) {}
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.documentToEdit != null
                ? 'Document updated successfully'
                : 'Document securely stored in vault',
          ),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        if (e is MasterKeyLostException ||
            e.toString().contains('MasterKeyLostException')) {
          _showMasterKeyLostRecoveryDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save document: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _showMasterKeyLostRecoveryDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Encryption Key Missing',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Text(
          'Your secure hardware encryption key was not found in secure storage, but older vault documents exist. '
          'To protect your data, automatic key regeneration was prevented.\n\n'
          'Would you like to reset your vault security keys? This will initialize a brand-new master encryption key so you can save this card and all future documents.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Reset Keys & Save Card',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      setState(() => _isSaving = true);
      try {
        await _vaultService.resetVault();
        if (mounted) {
          await _saveDocument();
        }
      } catch (err) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Vault reset failed: $err'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          widget.documentToEdit != null
              ? 'Edit Document'
              : (_currentStep == 0
                    ? 'Select Document Category'
                    : (_currentStep == 1
                          ? 'Enter Document Details'
                          : 'Preview & Save')),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (_currentStep > 0 && widget.documentToEdit == null) {
              setState(() => _currentStep--);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : (_currentStep == 0
                ? _buildCategorySelector()
                : (_currentStep == 1 ? _buildFormStep() : _buildPreviewStep())),
    );
  }

  // --- STEP 1: CATEGORY SELECTOR ---
  Widget _buildCategorySelector() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text(
          'Choose Document Type',
          style: AppTextStyles.headingSmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Select the kind of document you want to add to your private encrypted vault.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.getTextSecondary(context),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ..._categories.map((cat) {
          final isSelected = _selectedCategory == cat['id'];
          return Card(
            elevation: isSelected ? 3 : 1,
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.card),
              side: BorderSide(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (cat['color'] as Color).withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  cat['icon'] as IconData,
                  color: cat['color'] as Color,
                  size: 24,
                ),
              ),
              title: Text(
                cat['title'] as String,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                cat['subtitle'] as String,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.getTextSecondary(context),
                ),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                setState(() {
                  _selectedCategory = cat['id'] as String;
                  _currentStep = 1;
                });
              },
            ),
          );
        }),
      ],
    );
  }

  // --- STEP 2: CATEGORY SPECIFIC MANUAL FORM ---
  Widget _buildFormStep() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Header info
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _selectedCategory.replaceAll('_', ' ').toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              const Spacer(),
              if (widget.documentToEdit == null)
                TextButton(
                  onPressed: () => setState(() => _currentStep = 0),
                  child: const Text('Change Type'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Render specific fields
          if (_selectedCategory == 'aadhaar') ..._buildAadhaarFields(),
          if (_selectedCategory == 'pan') ..._buildPanFields(),
          if (_selectedCategory == 'driving_license' ||
              _selectedCategory == 'driving_licence')
            ..._buildDrivingLicenceFields(),
          if (_selectedCategory == 'passport') ..._buildPassportFields(),
          if (_selectedCategory == 'debit_card' ||
              _selectedCategory == 'credit_card')
            ..._buildPaymentCardFields(),
          if (_selectedCategory == 'insurance') ..._buildInsuranceFields(),
          if (_selectedCategory != 'aadhaar' &&
              _selectedCategory != 'pan' &&
              _selectedCategory != 'driving_license' &&
              _selectedCategory != 'driving_licence' &&
              _selectedCategory != 'passport' &&
              _selectedCategory != 'debit_card' &&
              _selectedCategory != 'credit_card' &&
              _selectedCategory != 'insurance')
            ..._buildOtherDocumentFields(),

          const SizedBox(height: AppSpacing.md),
          const Divider(),
          const SizedBox(height: AppSpacing.sm),

          // Attachment Section
          _buildAttachmentSection(),

          const SizedBox(height: AppSpacing.xl),
          ElevatedButton(
            onPressed: _proceedToPreview,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
            child: const Text(
              'Preview Virtual Card',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  // --- AADHAAR FORM FIELDS ---
  List<Widget> _buildAadhaarFields() {
    return [
      TextFormField(
        controller: _nameController,
        decoration: const InputDecoration(
          labelText: 'Full Name *',
          hintText: 'As per Aadhaar Card',
          prefixIcon: Icon(Icons.person_outline_rounded),
        ),
        validator: (v) =>
            v == null || v.trim().isEmpty ? 'Full name is required' : null,
      ),
      const SizedBox(height: AppSpacing.sm),
      TextFormField(
        controller: _numberController,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(12),
        ],
        decoration: const InputDecoration(
          labelText: 'Aadhaar Number (12 Digits) *',
          hintText: '123456789012',
          prefixIcon: Icon(Icons.fingerprint_rounded),
        ),
        validator: (v) {
          final digits = v?.replaceAll(RegExp(r'\s+'), '') ?? '';
          if (digits.length != 12)
            return 'Aadhaar number must contain exactly 12 digits';
          return null;
        },
      ),
      const SizedBox(height: AppSpacing.sm),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.cake_outlined),
        title: Text(
          _dob == null
              ? 'Select Date of Birth *'
              : 'DOB: ${DateFormat('dd MMM yyyy').format(_dob!)}',
        ),
        trailing: const Icon(Icons.calendar_today_rounded, size: 18),
        onTap: () => _selectDate(
          context,
          initial: _dob ?? DateTime(1995, 1, 1),
          onSelected: (d) => setState(() => _dob = d),
        ),
      ),
      const SizedBox(height: AppSpacing.xs),
      DropdownButtonFormField<String>(
        initialValue: _gender,
        decoration: const InputDecoration(
          labelText: 'Gender *',
          prefixIcon: Icon(Icons.transgender_rounded),
        ),
        items: const [
          DropdownMenuItem(value: 'Male', child: Text('Male')),
          DropdownMenuItem(value: 'Female', child: Text('Female')),
          DropdownMenuItem(value: 'Other', child: Text('Other')),
        ],
        onChanged: (v) => setState(() => _gender = v ?? 'Male'),
      ),
      const SizedBox(height: AppSpacing.sm),
      TextFormField(
        controller: _addressController,
        maxLines: 2,
        decoration: const InputDecoration(
          labelText: 'Address',
          hintText: 'Residential Address',
          prefixIcon: Icon(Icons.home_outlined),
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      TextFormField(
        controller: _fatherNameController,
        decoration: const InputDecoration(
          labelText: "Father's / Guardian's Name (Optional)",
          prefixIcon: Icon(Icons.family_restroom_rounded),
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      TextFormField(
        controller: _mobileController,
        keyboardType: TextInputType.phone,
        decoration: const InputDecoration(
          labelText: 'Registered Mobile Number (Optional)',
          prefixIcon: Icon(Icons.phone_outlined),
        ),
      ),
    ];
  }

  // --- PAN FORM FIELDS ---
  List<Widget> _buildPanFields() {
    return [
      TextFormField(
        controller: _nameController,
        decoration: const InputDecoration(
          labelText: "Full Name *",
          hintText: "As printed on PAN Card",
          prefixIcon: Icon(Icons.person_outline_rounded),
        ),
        validator: (v) =>
            v == null || v.trim().isEmpty ? 'Full name is required' : null,
      ),
      const SizedBox(height: AppSpacing.sm),
      TextFormField(
        controller: _fatherNameController,
        decoration: const InputDecoration(
          labelText: "Father's Name *",
          prefixIcon: Icon(Icons.family_restroom_rounded),
        ),
        validator: (v) =>
            v == null || v.trim().isEmpty ? "Father's name is required" : null,
      ),
      const SizedBox(height: AppSpacing.sm),
      TextFormField(
        controller: _numberController,
        textCapitalization: TextCapitalization.characters,
        inputFormatters: [
          LengthLimitingTextInputFormatter(14),
          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9•\s\-]')),
          _UpperCaseTextFormatter(),
        ],
        decoration: const InputDecoration(
          labelText: 'PAN Number (10 Characters) *',
          hintText: 'ABCDE1234F',
          prefixIcon: Icon(Icons.credit_card_rounded),
        ),
        validator: (v) {
          final pan = v?.replaceAll(RegExp(r'[\s\-]+'), '').toUpperCase() ?? '';
          if (pan.isEmpty) {
            return 'PAN number is required';
          }
          if (pan.contains('•')) {
            return null; // Preserving existing masked PAN identifier
          }
          if (pan.length != 10) {
            return 'PAN number must be exactly 10 characters';
          }
          if (!RegExp(r'^[A-Z0-9]{10}$').hasMatch(pan)) {
            return 'Enter a valid 10-character PAN (e.g. ABCDE1234F)';
          }
          return null;
        },
      ),
      const SizedBox(height: AppSpacing.sm),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.cake_outlined),
        title: Text(
          _dob == null
              ? 'Select Date of Birth *'
              : 'DOB: ${DateFormat('dd MMM yyyy').format(_dob!)}',
        ),
        trailing: const Icon(Icons.calendar_today_rounded, size: 18),
        onTap: () => _selectDate(
          context,
          initial: _dob ?? DateTime(1995, 1, 1),
          onSelected: (d) => setState(() => _dob = d),
        ),
      ),
    ];
  }

  // --- DRIVING LICENCE FIELDS ---
  List<Widget> _buildDrivingLicenceFields() {
    return [
      TextFormField(
        controller: _nameController,
        decoration: const InputDecoration(
          labelText: 'Full Name *',
          hintText: 'Licence Holder Name',
          prefixIcon: Icon(Icons.person_outline_rounded),
        ),
        validator: (v) =>
            v == null || v.trim().isEmpty ? 'Holder name is required' : null,
      ),
      const SizedBox(height: AppSpacing.sm),
      TextFormField(
        controller: _numberController,
        textCapitalization: TextCapitalization.characters,
        decoration: const InputDecoration(
          labelText: 'Driving Licence Number *',
          hintText: 'e.g. DL-1420110012345',
          prefixIcon: Icon(Icons.badge_outlined),
        ),
        validator: (v) =>
            v == null || v.trim().isEmpty ? 'Licence number is required' : null,
      ),
      const SizedBox(height: AppSpacing.sm),
      Row(
        children: [
          Expanded(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined),
              title: Text(
                _issueDate == null
                    ? 'Issue Date *'
                    : DateFormat('dd/MM/yyyy').format(_issueDate!),
              ),
              onTap: () => _selectDate(
                context,
                initial: _issueDate ?? DateTime.now(),
                onSelected: (d) => setState(() => _issueDate = d),
              ),
            ),
          ),
          Expanded(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_available_outlined),
              title: Text(
                _expiryDate == null
                    ? 'Valid Until *'
                    : DateFormat('dd/MM/yyyy').format(_expiryDate!),
              ),
              onTap: () => _selectDate(
                context,
                initial:
                    _expiryDate ??
                    DateTime.now().add(const Duration(days: 365 * 10)),
                onSelected: (d) => setState(() => _expiryDate = d),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.sm),
      TextFormField(
        controller: _authorityController,
        decoration: const InputDecoration(
          labelText: 'Issuing Authority / RTO *',
          hintText: 'e.g. RTO Delhi Central',
          prefixIcon: Icon(Icons.account_balance_outlined),
        ),
        validator: (v) => v == null || v.trim().isEmpty
            ? 'Issuing authority is required'
            : null,
      ),
      const SizedBox(height: AppSpacing.sm),
      TextFormField(
        controller: _stateController,
        decoration: const InputDecoration(
          labelText: 'State / Union Territory *',
          hintText: 'e.g. Delhi, Maharashtra',
          prefixIcon: Icon(Icons.map_outlined),
        ),
        validator: (v) =>
            v == null || v.trim().isEmpty ? 'State is required' : null,
      ),
      const SizedBox(height: AppSpacing.sm),
      const Text(
        'Authorized Vehicle Classes:',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
      Wrap(
        spacing: 8,
        children: ['MCWG', 'MCWOG', 'LMV', 'HMV', 'TRANS'].map((cls) {
          final isSelected = _selectedVehicleClasses.contains(cls);
          return FilterChip(
            label: Text(cls),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                if (selected) {
                  _selectedVehicleClasses.add(cls);
                } else {
                  _selectedVehicleClasses.remove(cls);
                }
              });
            },
          );
        }).toList(),
      ),
    ];
  }

  // --- PASSPORT FIELDS ---
  List<Widget> _buildPassportFields() {
    return [
      TextFormField(
        controller: _nameController,
        decoration: const InputDecoration(
          labelText: 'Full Name *',
          hintText: 'Given name + Surname',
          prefixIcon: Icon(Icons.person_outline_rounded),
        ),
        validator: (v) =>
            v == null || v.trim().isEmpty ? 'Full name is required' : null,
      ),
      const SizedBox(height: AppSpacing.sm),
      TextFormField(
        controller: _numberController,
        textCapitalization: TextCapitalization.characters,
        inputFormatters: [LengthLimitingTextInputFormatter(8)],
        decoration: const InputDecoration(
          labelText: 'Passport Number *',
          hintText: 'e.g. J1234567',
          prefixIcon: Icon(Icons.flight_takeoff_rounded),
        ),
        validator: (v) {
          final pass = v?.trim().toUpperCase() ?? '';
          if (!RegExp(r'^[A-Z][0-9]{7}$').hasMatch(pass)) {
            return 'Enter a valid passport number (1 letter followed by 7 digits)';
          }
          return null;
        },
      ),
      const SizedBox(height: AppSpacing.sm),
      TextFormField(
        controller: _nationalityController,
        decoration: const InputDecoration(
          labelText: 'Nationality *',
          prefixIcon: Icon(Icons.flag_outlined),
        ),
        validator: (v) =>
            v == null || v.trim().isEmpty ? 'Nationality is required' : null,
      ),
      const SizedBox(height: AppSpacing.sm),
      Row(
        children: [
          Expanded(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined),
              title: Text(
                _issueDate == null
                    ? 'Issue Date *'
                    : DateFormat('dd/MM/yyyy').format(_issueDate!),
              ),
              onTap: () => _selectDate(
                context,
                initial: _issueDate ?? DateTime.now(),
                onSelected: (d) => setState(() => _issueDate = d),
              ),
            ),
          ),
          Expanded(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_available_outlined),
              title: Text(
                _expiryDate == null
                    ? 'Expiry Date *'
                    : DateFormat('dd/MM/yyyy').format(_expiryDate!),
              ),
              onTap: () => _selectDate(
                context,
                initial:
                    _expiryDate ??
                    DateTime.now().add(const Duration(days: 365 * 10)),
                onSelected: (d) => setState(() => _expiryDate = d),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.sm),
      TextFormField(
        controller: _pobController,
        decoration: const InputDecoration(
          labelText: 'Place of Birth *',
          hintText: 'City, State',
          prefixIcon: Icon(Icons.location_city_rounded),
        ),
        validator: (v) =>
            v == null || v.trim().isEmpty ? 'Place of birth is required' : null,
      ),
      const SizedBox(height: AppSpacing.sm),
      TextFormField(
        controller: _poiController,
        decoration: const InputDecoration(
          labelText: 'Place of Issue *',
          hintText: 'e.g. RPO Delhi',
          prefixIcon: Icon(Icons.apartment_rounded),
        ),
        validator: (v) =>
            v == null || v.trim().isEmpty ? 'Place of issue is required' : null,
      ),
    ];
  }

  // --- PAYMENT CARD (DEBIT / CREDIT) FIELDS ---
  List<Widget> _buildPaymentCardFields() {
    return [
      // Privacy Notice Banner
      Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(20),
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.primary.withAlpha(60)),
        ),
        child: const Row(
          children: [
            Icon(Icons.shield_outlined, color: AppColors.primary),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Security Assurance: Spendz never asks for, collects, or stores your CVV or PIN.',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      SizedBox(
        width: double.infinity,
        child: SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'debit_card',
              label: Text('Debit Card'),
              icon: Icon(Icons.credit_card_rounded),
            ),
            ButtonSegment(
              value: 'credit_card',
              label: Text('Credit Card'),
              icon: Icon(Icons.credit_score_rounded),
            ),
          ],
          selected: {
            _selectedCategory == 'credit_card' ? 'credit_card' : 'debit_card',
          },
          onSelectionChanged: (val) =>
              setState(() => _selectedCategory = val.first),
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      TextFormField(
        controller: _nameController,
        decoration: const InputDecoration(
          labelText: 'Cardholder Name *',
          hintText: 'Name as on card',
          prefixIcon: Icon(Icons.person_outline_rounded),
        ),
        validator: (v) => v == null || v.trim().isEmpty
            ? 'Cardholder name is required'
            : null,
      ),
      const SizedBox(height: AppSpacing.sm),
      TextFormField(
        controller: _bankController,
        decoration: const InputDecoration(
          labelText: 'Bank / Issuer Name *',
          hintText: 'e.g. HDFC Bank, SBI, ICICI',
          prefixIcon: Icon(Icons.account_balance_rounded),
        ),
        validator: (v) =>
            v == null || v.trim().isEmpty ? 'Bank name is required' : null,
      ),
      const SizedBox(height: AppSpacing.sm),
      DropdownButtonFormField<String>(
        initialValue: _cardNetwork,
        decoration: const InputDecoration(
          labelText: 'Card Network *',
          prefixIcon: Icon(Icons.network_check_rounded),
        ),
        items: const [
          DropdownMenuItem(value: 'Visa', child: Text('Visa')),
          DropdownMenuItem(value: 'Mastercard', child: Text('Mastercard')),
          DropdownMenuItem(value: 'RuPay', child: Text('RuPay')),
          DropdownMenuItem(
            value: 'American Express',
            child: Text('American Express'),
          ),
          DropdownMenuItem(value: 'Diners Club', child: Text('Diners Club')),
        ],
        onChanged: (v) => setState(() => _cardNetwork = v ?? 'Visa'),
      ),
      const SizedBox(height: AppSpacing.sm),
      TextFormField(
        controller: _numberController,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(19),
        ],
        decoration: const InputDecoration(
          labelText: 'Card Number (16 Digits) *',
          hintText: '4821000012345678',
          prefixIcon: Icon(Icons.credit_card_rounded),
        ),
        validator: (v) {
          final digits = v?.replaceAll(RegExp(r'\s+'), '') ?? '';
          if (digits.length < 13 || digits.length > 19) {
            return 'Enter a valid card number (13-19 digits)';
          }
          return null;
        },
      ),
      const SizedBox(height: AppSpacing.sm),
      Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<int>(
              initialValue: _expiryMonth,
              decoration: const InputDecoration(labelText: 'Expiry Month *'),
              items: List.generate(12, (i) => i + 1).map((m) {
                return DropdownMenuItem(
                  value: m,
                  child: Text(m.toString().padLeft(2, '0')),
                );
              }).toList(),
              onChanged: (v) => setState(() {
                _expiryMonth = v ?? 1;
                _expiryDate = DateTime(_expiryYear, _expiryMonth, 1);
              }),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: DropdownButtonFormField<int>(
              initialValue: _expiryYear,
              decoration: const InputDecoration(labelText: 'Expiry Year *'),
              items: List.generate(15, (i) => DateTime.now().year + i).map((y) {
                return DropdownMenuItem(value: y, child: Text(y.toString()));
              }).toList(),
              onChanged: (v) => setState(() {
                _expiryYear = v ?? DateTime.now().year;
                _expiryDate = DateTime(_expiryYear, _expiryMonth, 1);
              }),
            ),
          ),
        ],
      ),
    ];
  }

  // --- INSURANCE FIELDS ---
  List<Widget> _buildInsuranceFields() {
    return [
      TextFormField(
        controller: _providerController,
        decoration: const InputDecoration(
          labelText: 'Insurance Provider *',
          hintText: 'e.g. Star Health, HDFC ERGO, LIC',
          prefixIcon: Icon(Icons.business_rounded),
        ),
        validator: (v) =>
            v == null || v.trim().isEmpty ? 'Provider name is required' : null,
      ),
      const SizedBox(height: AppSpacing.sm),
      TextFormField(
        controller: _nameController,
        decoration: const InputDecoration(
          labelText: 'Policyholder Name *',
          hintText: 'Primary Insured Person',
          prefixIcon: Icon(Icons.person_outline_rounded),
        ),
        validator: (v) => v == null || v.trim().isEmpty
            ? 'Policyholder name is required'
            : null,
      ),
      const SizedBox(height: AppSpacing.sm),
      TextFormField(
        controller: _numberController,
        decoration: const InputDecoration(
          labelText: 'Policy Number *',
          hintText: 'e.g. POL-9876543210',
          prefixIcon: Icon(Icons.tag_rounded),
        ),
        validator: (v) =>
            v == null || v.trim().isEmpty ? 'Policy number is required' : null,
      ),
      const SizedBox(height: AppSpacing.sm),
      DropdownButtonFormField<String>(
        initialValue: _policyType,
        decoration: const InputDecoration(
          labelText: 'Policy Type *',
          prefixIcon: Icon(Icons.shield_outlined),
        ),
        items: const [
          DropdownMenuItem(
            value: 'Health Insurance',
            child: Text('Health Insurance'),
          ),
          DropdownMenuItem(
            value: 'Motor Insurance',
            child: Text('Motor Insurance'),
          ),
          DropdownMenuItem(
            value: 'Life Insurance',
            child: Text('Life Insurance'),
          ),
          DropdownMenuItem(
            value: 'Term Insurance',
            child: Text('Term Insurance'),
          ),
          DropdownMenuItem(
            value: 'Travel Insurance',
            child: Text('Travel Insurance'),
          ),
          DropdownMenuItem(
            value: 'Home Insurance',
            child: Text('Home Insurance'),
          ),
        ],
        onChanged: (v) => setState(() => _policyType = v ?? 'Health Insurance'),
      ),
      const SizedBox(height: AppSpacing.sm),
      Row(
        children: [
          Expanded(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined),
              title: Text(
                _issueDate == null
                    ? 'Start Date *'
                    : DateFormat('dd/MM/yyyy').format(_issueDate!),
              ),
              onTap: () => _selectDate(
                context,
                initial: _issueDate ?? DateTime.now(),
                onSelected: (d) => setState(() => _issueDate = d),
              ),
            ),
          ),
          Expanded(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_available_outlined),
              title: Text(
                _expiryDate == null
                    ? 'Expiry Date *'
                    : DateFormat('dd/MM/yyyy').format(_expiryDate!),
              ),
              onTap: () => _selectDate(
                context,
                initial:
                    _expiryDate ??
                    DateTime.now().add(const Duration(days: 365)),
                onSelected: (d) => setState(() => _expiryDate = d),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.sm),
      TextFormField(
        controller: _coverageController,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'Coverage Amount (Sum Insured)',
          hintText: 'e.g. 1000000',
          prefixIcon: Icon(Icons.currency_rupee_rounded),
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      TextFormField(
        controller: _contactController,
        decoration: const InputDecoration(
          labelText: 'Helpline / Contact Phone (Optional)',
          prefixIcon: Icon(Icons.phone_in_talk_outlined),
        ),
      ),
    ];
  }

  // --- OTHER DOCUMENTS FIELDS ---
  List<Widget> _buildOtherDocumentFields() {
    return [
      TextFormField(
        controller: _nameController,
        decoration: const InputDecoration(
          labelText: 'Document Title *',
          hintText: 'e.g. Vehicle RC, College ID, Birth Certificate',
          prefixIcon: Icon(Icons.title_rounded),
        ),
        validator: (v) =>
            v == null || v.trim().isEmpty ? 'Document title is required' : null,
      ),
      const SizedBox(height: AppSpacing.sm),
      TextFormField(
        controller: _holderController,
        decoration: const InputDecoration(
          labelText: 'Issuing Organisation / Holder Name',
          hintText: 'e.g. Ministry of Transport / John Doe',
          prefixIcon: Icon(Icons.business_outlined),
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      TextFormField(
        controller: _numberController,
        decoration: const InputDecoration(
          labelText: 'Reference / Document Number',
          hintText: 'e.g. REG-12345678',
          prefixIcon: Icon(Icons.tag_rounded),
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      Row(
        children: [
          Expanded(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined),
              title: Text(
                _issueDate == null
                    ? 'Issue Date'
                    : DateFormat('dd/MM/yyyy').format(_issueDate!),
              ),
              onTap: () => _selectDate(
                context,
                initial: _issueDate ?? DateTime.now(),
                onSelected: (d) => setState(() => _issueDate = d),
              ),
            ),
          ),
          Expanded(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_available_outlined),
              title: Text(
                _expiryDate == null
                    ? 'Expiry Date'
                    : DateFormat('dd/MM/yyyy').format(_expiryDate!),
              ),
              onTap: () => _selectDate(
                context,
                initial:
                    _expiryDate ??
                    DateTime.now().add(const Duration(days: 365)),
                onSelected: (d) => setState(() => _expiryDate = d),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.sm),
      TextFormField(
        controller: _notesController,
        maxLines: 2,
        decoration: const InputDecoration(
          labelText: 'Notes / Additional Information',
          prefixIcon: Icon(Icons.notes_rounded),
        ),
      ),
    ];
  }

  // --- ATTACHMENT SECTION ---
  Widget _buildAttachmentSection() {
    final hasAttachment = _attachmentPayload != null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Original Document Attachment',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (hasAttachment)
                TextButton.icon(
                  onPressed: () => setState(() => _attachmentPayload = null),
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: Colors.redAccent,
                  ),
                  label: const Text(
                    'Remove',
                    style: TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            hasAttachment
                ? 'Original scanned copy attached (${_attachmentPayload!.fileName}, ${_attachmentPayload!.pageCount} page(s)).'
                : 'Attach a camera scan, photo, or PDF copy of the original physical document. (Optional)',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.getTextSecondary(context),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (hasAttachment) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(15),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.primary.withAlpha(60)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              (_attachmentPayload!.isPdf
                                      ? Colors.redAccent
                                      : AppColors.primary)
                                  .withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _attachmentPayload!.isPdf
                              ? Icons.picture_as_pdf_rounded
                              : Icons.photo_rounded,
                          color: _attachmentPayload!.isPdf
                              ? Colors.redAccent
                              : AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _attachmentPayload!.fileName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_attachmentPayload!.pageCount} Page(s) • ${DocumentScannerService.formatFileSize(_attachmentPayload!.calculatedSize)} • Ready to encrypt',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.getTextSecondary(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: _openAttachmentScanner,
                        icon: const Icon(Icons.edit_note_rounded, size: 16),
                        label: const Text(
                          'Edit / Replace',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                    ),
                    onPressed: _openAttachmentScanner,
                    icon: const Icon(Icons.document_scanner_rounded, size: 18),
                    label: const Text('Scan Document'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                    ),
                    onPressed: _attachExistingPdf,
                    icon: const Icon(Icons.folder_open_rounded, size: 18),
                    label: const Text('Attach PDF'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // --- STEP 3: LIVE PREVIEW & SAVE ---
  Widget _buildPreviewStep() {
    final title = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : '${_selectedCategory.replaceAll('_', ' ').toUpperCase()} Document';

    final holder = _holderController.text.trim().isNotEmpty
        ? _holderController.text.trim()
        : null;
    final rawNumber = _numberController.text.trim();
    final masked = _computeMaskedIdentifier(rawNumber);

    // Build preview document model
    final previewDoc = WalletDocumentModel(
      id: widget.documentToEdit?.id ?? 'preview_id',
      documentName: title,
      category: _selectedCategory,
      holderName: holder,
      maskedIdentifier: masked,
      issueDate: _issueDate,
      expiryDate: _expiryDate,
      isFavorite: widget.documentToEdit?.isFavorite ?? false,
      encryptedFilePath: _attachmentPayload != null
          ? 'has_attachment'
          : (widget.documentToEdit?.encryptedFilePath ?? ''),
      mimeType:
          _attachmentPayload?.mimeType ??
          (widget.documentToEdit?.mimeType ?? 'image/jpeg'),
      description:
          'Holder: ${holder ?? ''}\nNumber: $masked\nBank: ${_bankController.text.trim()}\nNetwork: $_cardNetwork\nProvider: ${_providerController.text.trim()}\nType: $_policyType',
      createdAt: widget.documentToEdit?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text(
          'Virtual Card Preview',
          style: AppTextStyles.headingSmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Review how your document appears in your Spendz Digital Wallet before saving.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.getTextSecondary(context),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Live Virtual Document Card
        VirtualDocumentCard(document: previewDoc, showShadow: true),
        const SizedBox(height: AppSpacing.lg),

        // Summary Information Card
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Document Details',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(),
                _summaryRow(
                  'Type',
                  _selectedCategory.replaceAll('_', ' ').toUpperCase(),
                ),
                _summaryRow('Document Title', title),
                if (holder != null) _summaryRow('Holder', holder),
                if (masked.isNotEmpty) _summaryRow('Masked ID', masked),
                if (_issueDate != null)
                  _summaryRow(
                    'Issue Date',
                    DateFormat('dd MMM yyyy').format(_issueDate!),
                  ),
                if (_expiryDate != null)
                  _summaryRow(
                    'Expiry Date',
                    DateFormat('dd MMM yyyy').format(_expiryDate!),
                  ),
                _summaryRow(
                  'Attachment',
                  _attachmentPayload != null
                      ? 'Attached (${_attachmentPayload!.fileName})'
                      : (widget.documentToEdit?.hasAttachment == true
                            ? 'Retaining existing attachment'
                            : 'No attachment copy'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Buttons: Edit Details or Save to Vault
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep = 1),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
                child: const Text('Back / Edit Form'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _saveDocument,
                icon: const Icon(Icons.lock_rounded, size: 18),
                label: Text(
                  widget.documentToEdit != null
                      ? 'Update Vault'
                      : 'Save to Vault',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.getTextSecondary(context),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
