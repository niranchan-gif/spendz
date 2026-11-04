import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';

import '../../../app/theme/spendz_colors.dart';
import '../../../models/wallet_pass_model.dart';

/// Full Green Fintech Transit Ticket & Boarding Pass Widget.
/// Displays PNR, Seat Number, Date and Time of travel, barcode,
/// and allows uploading and opening the ticket document (PDF or image).
/// Zero plain text boxes visible on the card.
class TransitTicketCard extends StatelessWidget {
  final WalletPassModel? pass;
  final String? pnrNumber;
  final String? seatNumber;
  final DateTime? travelDate;
  final String? travelTime;
  final String? carrier;
  final String? docPath;
  final Function(String path)? onDocUploaded;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TransitTicketCard({
    super.key,
    this.pass,
    this.pnrNumber,
    this.seatNumber,
    this.travelDate,
    this.travelTime,
    this.carrier,
    this.docPath,
    this.onDocUploaded,
    this.onEdit,
    this.onDelete,
  });

  String get _effectivePnr {
    if (pnrNumber != null && pnrNumber!.isNotEmpty) return pnrNumber!;
    if (pass != null && pass!.notes != null) {
      final pnrMatch = RegExp(r'PNR:\s*([^\n,]+)').firstMatch(pass!.notes!);
      if (pnrMatch != null) return pnrMatch.group(1)?.trim() ?? '8421-950-231';
    }
    return '8421-950-231';
  }

  String get _effectiveSeat {
    if (seatNumber != null && seatNumber!.isNotEmpty) return seatNumber!;
    if (pass != null && pass!.notes != null) {
      final seatMatch = RegExp(r'Seat:\s*([^\n,]+)').firstMatch(pass!.notes!);
      if (seatMatch != null) return seatMatch.group(1)?.trim() ?? 'B3 • 42';
    }
    return 'B3 • Berth 42';
  }

  DateTime get _effectiveDate {
    if (travelDate != null) return travelDate!;
    if (pass?.validUntil != null) return pass!.validUntil!;
    return DateTime.now().add(const Duration(days: 3));
  }

  String get _effectiveTime {
    if (travelTime != null && travelTime!.isNotEmpty) return travelTime!;
    if (pass != null && pass!.notes != null) {
      final timeMatch = RegExp(r'Time:\s*([^\n,]+)').firstMatch(pass!.notes!);
      if (timeMatch != null) return timeMatch.group(1)?.trim() ?? '06:30 AM';
    }
    return '06:30 AM';
  }

  String get _effectiveCarrier {
    if (carrier != null && carrier!.isNotEmpty) return carrier!;
    if (pass?.issuer != null && pass!.issuer!.isNotEmpty) return pass!.issuer!;
    return 'INDIAN RAILWAYS / IRCTC';
  }

  String? get _effectiveDocPath {
    if (docPath != null && docPath!.isNotEmpty) return docPath;
    if (pass != null) {
      if (pass!.encryptedCodePath.isNotEmpty &&
          (pass!.encryptedCodePath.endsWith('.pdf') ||
              pass!.encryptedCodePath.endsWith('.jpg') ||
              pass!.encryptedCodePath.endsWith('.jpeg') ||
              pass!.encryptedCodePath.endsWith('.png'))) {
        return pass!.encryptedCodePath;
      }
      if (pass!.notes != null) {
        final docMatch = RegExp(r'Doc:\s*([^\n]+)').firstMatch(pass!.notes!);
        if (docMatch != null) return docMatch.group(1)?.trim();
      }
    }
    return null;
  }

  Future<void> _pickAndUploadDocument(BuildContext context) async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
        dialogTitle: 'Select Ticket Document (PDF / Image)',
      );

      if (files.isNotEmpty && files.first.path != null) {
        final path = files.first.path!;
        final name = files.first.name;
        if (onDocUploaded != null) {
          onDocUploaded!(path);
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ticket document attached: $name'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not attach document: $e'),
            backgroundColor: SpendzColors.expense,
          ),
        );
      }
    }
  }

  Future<void> _openDocument(BuildContext context, String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        final res = await OpenFilex.open(path);
        if (res.type != ResultType.done && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open file: ${res.message}'),
              backgroundColor: SpendzColors.expense,
            ),
          );
        }
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document file not found on device storage.'),
            backgroundColor: SpendzColors.expense,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening document: $e'),
            backgroundColor: SpendzColors.expense,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final formattedDate = dateFormat.format(_effectiveDate);
    final attachedPath = _effectiveDocPath;
    final hasAttachedDoc = attachedPath != null && attachedPath.isNotEmpty;
    final docFileName = hasAttachedDoc
        ? attachedPath.split(Platform.pathSeparator).last
        : '';

    return Container(
      decoration: BoxDecoration(
        // Full green vibrant emerald gradient
        gradient: const LinearGradient(
          colors: [
            Color(0xFF047857), // Deep emerald
            Color(0xFF065F46), // Forest emerald
            Color(0xFF022C22), // Midnight emerald base
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF34D399).withAlpha(70),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF047857).withAlpha(50),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. TOP HEADER: Carrier, Train/Flight Icon & Confirmed Badge
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(35),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.train_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _effectiveCarrier,
                            style: const TextStyle(
                              color: Color(0xFFD1FAE5),
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const Text(
                            'TRANSIT BOARDING PASS',
                            style: TextStyle(
                              color: Color(0xFF6EE7B7),
                              fontWeight: FontWeight.w600,
                              fontSize: 8.5,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3.5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withAlpha(60),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF34D399),
                            width: 0.8,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF34D399),
                              size: 12,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'CONFIRMED',
                              style: TextStyle(
                                color: Color(0xFFECFDF5),
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (onDelete != null) ...[
                        const SizedBox(width: 4),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(
                            Icons.more_vert_rounded,
                            color: Colors.white70,
                            size: 18,
                          ),
                          onPressed: onEdit,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // 2. MAIN TICKET BODY: PNR Number & Seat Number
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(40),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withAlpha(20),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // PNR Block
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PNR NUMBER',
                          style: TextStyle(
                            color: Color(0xFF6EE7B7),
                            fontWeight: FontWeight.w700,
                            fontSize: 9,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 2),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(
                              ClipboardData(text: _effectivePnr),
                            );
                            HapticFeedback.lightImpact();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Copied PNR: $_effectivePnr'),
                                duration: const Duration(seconds: 2),
                                backgroundColor: const Color(0xFF047857),
                              ),
                            );
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _effectivePnr,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  fontFamily: 'monospace',
                                  letterSpacing: 1.4,
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Icon(
                                Icons.copy_rounded,
                                color: Color(0xFF34D399),
                                size: 13,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Seat Number Block
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'SEAT / BERTH',
                          style: TextStyle(
                            color: Color(0xFF6EE7B7),
                            fontWeight: FontWeight.w700,
                            fontSize: 9,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withAlpha(50),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _effectiveSeat,
                            style: const TextStyle(
                              color: Color(0xFFF0FDF4),
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // 3. DATE & TIME OF TRAVEL ROW
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Date
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 14,
                            color: Color(0xFF34D399),
                          ),
                          const SizedBox(width: 6),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'DATE OF TRAVEL',
                                style: TextStyle(
                                  color: Color(0xFF6EE7B7),
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                formattedDate,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Time
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: Color(0xFF34D399),
                          ),
                          const SizedBox(width: 6),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TIME OF TRAVEL',
                                style: TextStyle(
                                  color: Color(0xFF6EE7B7),
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                _effectiveTime,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 4. PERFORATED TICKET DIVIDER WITH NOTCHES
            _buildPerforatedDivider(),

            // 5. BOTTOM SECTION: Barcode & Upload / View Document Action
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Stylized Transit Barcode Graphic
                  const _TransitBarcodeWidget(
                    code: '8421950231',
                    width: 90,
                    height: 28,
                  ),

                  const SizedBox(width: 12),

                  // Upload / View Document Button
                  Expanded(
                    child: hasAttachedDoc
                        ? Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () =>
                                      _openDocument(context, attachedPath),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                      horizontal: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF10B981,
                                      ).withAlpha(60),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFF34D399),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.file_present_rounded,
                                          color: Color(0xFFD1FAE5),
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            docFileName.isNotEmpty
                                                ? docFileName
                                                : 'View e-Ticket Doc',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: () => _pickAndUploadDocument(context),
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(20),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.upload_file_rounded,
                                    color: Color(0xFFD1FAE5),
                                    size: 14,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : InkWell(
                            onTap: () => _pickAndUploadDocument(context),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 7,
                                horizontal: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(25),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFF34D399).withAlpha(80),
                                  width: 0.8,
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.upload_file_rounded,
                                    color: Color(0xFF34D399),
                                    size: 14,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Upload Ticket Doc',
                                    style: TextStyle(
                                      color: Color(0xFFF0FDF4),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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

  Widget _buildPerforatedDivider() {
    return SizedBox(
      height: 14,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Perforated Dashed Line
          LayoutBuilder(
            builder: (context, constraints) {
              const dashWidth = 5.0;
              const dashSpace = 4.0;
              final dashCount = (constraints.maxWidth / (dashWidth + dashSpace))
                  .floor();
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(dashCount, (_) {
                  return Container(
                    width: dashWidth,
                    height: 1.0,
                    margin: const EdgeInsets.symmetric(
                      horizontal: dashSpace / 2,
                    ),
                    color: Colors.white.withAlpha(40),
                  );
                }),
              );
            },
          ),
          // Left Notch Cutout
          Positioned(
            left: -8,
            child: Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Right Notch Cutout
          Positioned(
            right: -8,
            child: Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Authentic Barcode Graphic for Transit Ticket
class _TransitBarcodeWidget extends StatelessWidget {
  final String code;
  final double width;
  final double height;

  const _TransitBarcodeWidget({
    required this.code,
    this.width = 90,
    this.height = 28,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(225),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 1.5, color: const Color(0xFF064E3B)),
                Container(width: 0.8, color: const Color(0xFF064E3B)),
                Container(width: 2.2, color: const Color(0xFF064E3B)),
                Container(width: 0.8, color: const Color(0xFF064E3B)),
                Container(width: 1.8, color: const Color(0xFF064E3B)),
                Container(width: 0.6, color: const Color(0xFF064E3B)),
                Container(width: 2.0, color: const Color(0xFF064E3B)),
                Container(width: 1.0, color: const Color(0xFF064E3B)),
                Container(width: 1.8, color: const Color(0xFF064E3B)),
                Container(width: 0.7, color: const Color(0xFF064E3B)),
                Container(width: 2.4, color: const Color(0xFF064E3B)),
                Container(width: 0.8, color: const Color(0xFF064E3B)),
                Container(width: 1.4, color: const Color(0xFF064E3B)),
              ],
            ),
          ),
          const SizedBox(height: 1),
          Text(
            code,
            style: const TextStyle(
              fontSize: 6.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF064E3B),
              letterSpacing: 0.8,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
