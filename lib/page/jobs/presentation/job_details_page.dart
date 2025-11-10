import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/permissions/permission_helper.dart';
import '../../../data/datasource/cancel_job_datasource.dart';
import '../../../data/datasource/finish_job_datasource.dart';
import '../../../data/datasource/reschedule_job_datasource.dart';
import '../../../data/datasource/traxroot_datasource.dart';
import '../../../core/models/geo.dart';
import '../../profile/presentation/profile_page.dart';

import 'package:fms/data/datasource/driver_get_job_datasource.dart';
import 'package:fms/data/models/response/driver_get_job_response_model.dart';

import 'job_navigation_page.dart';

class JobDetailsPage extends StatefulWidget {
  final dynamic job;
  final bool isOngoing;
  //is ongoing = false
  const JobDetailsPage({super.key, required this.job, this.isOngoing = false});
  @override
  State<JobDetailsPage> createState() => _JobDetailsPageState();
}

class _JobDetailsPageState extends State<JobDetailsPage> {
  final TextEditingController _cancelReasonController = TextEditingController();
  final TextEditingController _rescheduleNotesController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _cancelReasonController.dispose();
    _rescheduleNotesController.dispose();
    super.dispose();
  }

  void _shareJobDetails() {
    final job = widget.job;
    final buffer = StringBuffer()
      ..writeln('Job: ${job.jobName ?? 'N/A'}')
      ..writeln('Status: ${widget.isOngoing ? 'Ongoing' : 'Open'}')
      ..writeln('Job Type: ${_getJobTypeString(job.typeJob)}');

    if (job.jobDate != null) {
      buffer.writeln('Date: ${_formatDate(job.jobDate)}');
    }

    if (job.customerName != null) {
      buffer.writeln('Customer: ${job.customerName}');
    }

    if (job.address != null) {
      buffer.writeln('Address: ${job.address}');
    }

    Share.share(
      buffer.toString().trim(),
      subject: job.jobName ?? 'Job Details',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final job = widget.job;
    final isOngoing = widget.isOngoing;

    Widget buildPill(
      String label, {
      IconData? icon,
      Color? background,
      Color? foreground,
      Color? borderColor,
    }) {
      final pillForeground = foreground ?? colorScheme.primary;
      final pillBackground =
          background ??
          colorScheme.primaryContainer.withValues(
            alpha: foreground == null ? 0.18 : 0.22,
          );

      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: pillBackground,
          border: Border.all(
            color: (borderColor ?? pillForeground).withValues(alpha: 0.24),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: pillForeground),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: pillForeground,
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget buildSectionHeader({required IconData icon, required String title}) {
      return Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF4C8DFF), Color(0xFF1E58FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x2200185C),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      );
    }

    const sectionSpacing = 12.0;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(job.jobName ?? 'Job Details'),
        actions: [
          // IconButton(
          //   tooltip: 'More',
          //   icon: const Icon(Icons.more_vert),
          //   onPressed: () {
          //     // Show more options
          //     showModalBottomSheet(
          //       context: context,
          //       builder: (context) => Column(
          //         mainAxisSize: MainAxisSize.min,
          //         children: [
          //           ListTile(
          //             leading: const Icon(Icons.share),
          //             title: const Text('Share'),
          //             onTap: () {
          //               Navigator.pop(context);
          //               _shareJobDetails();
          //             },
          //           ),
          //           // ListTile(
          //           //   leading: const Icon(Icons.report),
          //           //   title: const Text('Report'),
          //           //   onTap: () {
          //           //     Navigator.pop(context);
          //           //     // Implement report functionality
          //           //   },
          //           // ),
          //         ],
          //       ),
          //     );
          //   },
          // ),
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 0,
                  color: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF7BD6FF),
                          Color(0xFF5AB6FF),
                          Color(0xFF3E8BFF),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: const Color(0x59FFFFFF),
                        width: 1.2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x332D6BFF),
                          blurRadius: 32,
                          offset: Offset(0, 18),
                        ),
                        BoxShadow(
                          color: Color(0x1AFFFFFF),
                          blurRadius: 12,
                          offset: Offset(-6, -6),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 62,
                                height: 62,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0x66FFFFFF),
                                      Color(0x33FFFFFF),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  border: Border.all(
                                    color: const Color(0x80FFFFFF),
                                  ),
                                ),
                                child: Icon(
                                  Icons.assignment_turned_in,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      job.jobName ?? 'Job',
                                      style: textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _getJobTypeString(job.typeJob),
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: Colors.white.withValues(
                                          alpha: 0.86,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              buildPill(
                                isOngoing ? 'Status: Ongoing' : 'Status: Open',
                                icon: isOngoing
                                    ? Icons.timelapse
                                    : Icons.event_available,
                                foreground: Colors.white,
                                background: isOngoing
                                    ? Colors.orange.withValues(alpha: 0.28)
                                    : Colors.white.withValues(alpha: 0.22),
                                borderColor: Colors.white,
                              ),
                              if (job.jobDate != null)
                                buildPill(
                                  'Date: ${_formatDate(job.jobDate)}',
                                  icon: Icons.calendar_today_outlined,
                                  foreground: Colors.white,
                                  background: Colors.white.withValues(
                                    alpha: 0.22,
                                  ),
                                  borderColor: Colors.white,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: sectionSpacing),

                Card(
                  elevation: 0,
                  color: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFFFFF), Color(0xFFF4F7FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(color: const Color(0x2132638F)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1432638F),
                          blurRadius: 24,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          buildSectionHeader(
                            icon: Icons.person,
                            title: 'Customer',
                          ),
                          const SizedBox(height: 16),
                          Text(
                            job.customerName ?? 'N/A',
                            style: textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (job.phoneNumber != null) ...[
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () => _callPhone(job.phoneNumber!),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.phone,
                                    color: colorScheme.primary,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      job.phoneNumber!,
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: sectionSpacing),

                Card(
                  elevation: 0,
                  color: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFFFFF), Color(0xFFF2F6FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(color: const Color(0x2E3A4CFF)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1432638F),
                          blurRadius: 24,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          buildSectionHeader(
                            icon: Icons.place,
                            title: 'Address',
                          ),
                          const SizedBox(height: 16),
                          Text(
                            job.address ?? 'N/A',
                            style: textTheme.bodyMedium?.copyWith(height: 1.5),
                          ),
                          const SizedBox(height: 16),
                          TextButton.icon(
                            onPressed: () => _navigateToJob(context),
                            icon: const Icon(Icons.map_outlined),
                            style: TextButton.styleFrom(
                              foregroundColor: colorScheme.primary,
                              padding: EdgeInsets.zero,
                              textStyle: textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              overlayColor: colorScheme.primary.withValues(
                                alpha: 0.08,
                              ),
                            ),
                            label: const Text('Open in Map'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: sectionSpacing),

                Card(
                  elevation: 0,
                  color: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFFFFF), Color(0xFFEFF3FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(color: const Color(0x2132638F)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1432638F),
                          blurRadius: 24,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          buildSectionHeader(
                            icon: Icons.info_outline,
                            title: 'Job Information',
                          ),
                          const SizedBox(height: 16),
                          _InfoRow(
                            label: 'Job Type',
                            value: _getJobTypeString(job.typeJob),
                          ),
                          const SizedBox(height: 12),
                          _InfoRow(
                            label: 'Created By',
                            value: job.createdBy?.toString() ?? 'N/A',
                          ),
                          if (job.createdAt != null) ...[
                            const SizedBox(height: 12),
                            _InfoRow(
                              label: 'Created At',
                              value: _formatDate(job.createdAt),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isOngoing)
                Row(
                  children: [
                    // Expanded(
                    //   child: OutlinedButton.icon(
                    //     onPressed: () {
                    //       ScaffoldMessenger.of(context).showSnackBar(
                    //         const SnackBar(
                    //           content: Text('Postpone feature coming soon'),
                    //         ),
                    //       );
                    //     },
                    //     icon: const Icon(Icons.schedule),
                    //     label: const Text('Postpone'),
                    //     style: OutlinedButton.styleFrom(
                    //       padding: const EdgeInsets.symmetric(vertical: 14),
                    //       shape: RoundedRectangleBorder(
                    //         borderRadius: BorderRadius.circular(16),
                    //       ),
                    //       side: BorderSide(
                    //         color: colorScheme.primary.withValues(alpha:0.4),
                    //       ),
                    //       foregroundColor: colorScheme.primary,
                    //     ),
                    //   ),
                    // ),
                    // const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _navigateToJob(context),
                        icon: const Icon(Icons.navigation_outlined),
                        label: const Text('Navigate'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: BorderSide(
                            color: colorScheme.primary.withValues(alpha: 0.4),
                          ),
                          foregroundColor: colorScheme.primary,
                          overlayColor: colorScheme.primary.withValues(
                            alpha: 0.08,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              if (isOngoing) const SizedBox(height: 12),
              Row(
                children: [
                  if (isOngoing) Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _cancelJob(context);
                      },
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: BorderSide(
                          color: colorScheme.error.withValues(alpha: 0.35),
                        ),
                        foregroundColor: colorScheme.error,
                        overlayColor: colorScheme.error.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        isOngoing ? _finishJob(context) : _startJob(context);
                      },
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(isOngoing ? 'Finish Job' : 'Start Job'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        shadowColor: colorScheme.primary.withValues(alpha: 0.4),
                        overlayColor: colorScheme.primary.withValues(
                          alpha: 0.12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getJobTypeString(int? type) {
    switch (type) {
      case 1:
        return 'Line Interruption';
      case 2:
        return 'Reconnection';
      case 3:
        return 'Short Circuit';
      default:
        return 'Other';
    }
  }

  String _formatDate(dynamic value) {
    final dateTime = _parseDate(value);
    if (dateTime == null) return 'N/A';
    return DateFormat('EEE, dd MMM yyyy').format(dateTime);
  }

  Future<void> _callPhone(String rawNumber) async {
    final sanitized = rawNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri(scheme: 'tel', path: sanitized);
    final launched = await launchUrl(uri);
    if (!launched && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cannot open phone dialer')));
    }
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return null;
  }

  Future<void> _startJob(BuildContext context) async {
    final jobId = widget.job.jobId as int?;
    if (jobId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Job ID not found',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Tampilkan loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final datasource = DriverGetJobDatasource();
      final DriverGetJobResponseModel response = await datasource.driverGetJob(
        jobId: jobId,
      );

      if (context.mounted) {
        Navigator.of(context).pop(); // close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text(
              response.message ?? 'Success Driver Get The Job',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
        // Return with special flag to navigate to ongoing tab
        Navigator.pop(context, {'refresh': true, 'navigateToOngoing': true});
      }
    } catch (e) {
      if (context.mounted) {
        log('Failed to start job: ${e.toString()}');
        Navigator.of(context).pop(); // close loading
        
        // Extract error message from exception
        String errorMessage = 'Failed to start job';
        final exceptionMessage = e.toString();
        if (exceptionMessage.startsWith('Exception: ')) {
          errorMessage = exceptionMessage.substring('Exception: '.length);
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _finishJob(BuildContext context) async {
    final jobId = widget.job.jobId as int?;
    if (jobId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Job ID not found')));
      return;
    }

    final granted = await AppPermission.ensurePhotosPermission(context);
    if (!granted || !mounted) return;

    final source = await _showImageSourceSheet(context);
    if (!mounted || source == null) {
      return;
    }

    final picker = ImagePicker();
    final images = await _pickImages(context, picker, source);

    if (images.isEmpty || images.length < 2) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select minimum 2 photos')));
      return;
    }

    final approved = await _showImagePreview(context, images);
    if (!approved) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Upload canceled')));
      return;
    }

    final notesResult = await _askForNotes(context);
    if (!mounted) return;
    if (notesResult == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Finish job canceled')));
      return;
    }

    final trimmedNotes = notesResult.trim();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final List<String> imagesBase64 = [];
      for (final x in images) {
        final bytes = await x.readAsBytes();
        imagesBase64.add(base64Encode(bytes));
      }

      final datasource = FinishJobDatasource();
      final response = await datasource.finishJob(
        jobId: jobId,
        imagesBase64: imagesBase64,
        notes: trimmedNotes.isEmpty ? null : trimmedNotes,
      );

      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.message ?? 'Success Finish The Job',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (context.mounted) {
        log(e.toString());
        Navigator.of(context).pop();
        
        // Extract error message from exception
        String errorMessage = 'Failed to finish job';
        final exceptionMessage = e.toString();
        if (exceptionMessage.startsWith('Exception: ')) {
          errorMessage = exceptionMessage.substring('Exception: '.length);
        }
        
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<ImageSource?> _showImageSourceSheet(BuildContext context) async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () =>
                    Navigator.of(sheetContext).pop(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<List<XFile>> _pickImages(
    BuildContext context,
    ImagePicker picker,
    ImageSource source,
  ) async {
    if (source == ImageSource.gallery) {
      return await picker.pickMultiImage(imageQuality: 85, maxWidth: 1600);
    }

    final capturedImages = <XFile>[];

    while (capturedImages.length < 2) {
      final image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1600,
      );

      if (image == null) {
        break;
      }

      capturedImages.add(image);
    }

    while (capturedImages.isNotEmpty) {
      final addMore = await _askCaptureMore(context);
      if (!addMore) {
        break;
      }

      final image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1600,
      );

      if (image == null) {
        break;
      }

      capturedImages.add(image);
    }

    return capturedImages;
  }

  Future<bool> _askCaptureMore(BuildContext context) async {
    if (!mounted) return false;

    final result =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Add More'),
            content: const Text('Do you want to take more photos?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Done'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Add'),
              ),
            ],
          ),
        ) ??
        false;

    return result;
  }

  Future<bool> _showImagePreview(
    BuildContext context,
    List<XFile> images,
  ) async {
    if (images.isEmpty) return false;

    return (await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Preview Images'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: images
                      .map(
                        (image) => ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(image.path),
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Take Again'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Upload'),
              ),
            ],
          ),
        )) ??
        false;
  }

  Future<String?> _askForNotes(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Job Notes'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Add an optional note for this job',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(''),
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<String?> _askCancelReason(BuildContext context) async {
    final suggestions = <String>[
      'Customer not available',
      'Wrong address',
      'Vehicle issue',
      'Weather issue',
      'Other',
    ];
    final controller = _cancelReasonController;
    controller.clear();
    int selectedIndex = -1;

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Cancel Reason'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (int i = 0; i < suggestions.length; i++)
                      ChoiceChip(
                        label: Text(suggestions[i]),
                        selected: selectedIndex == i,
                        onSelected: (val) {
                          setState(() => selectedIndex = val ? i : -1);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Type additional details (optional)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                String reason = '';
                if (selectedIndex >= 0) {
                  reason = suggestions[selectedIndex];
                }
                final note = controller.text.trim();
                if (note.isNotEmpty) {
                  reason = reason.isEmpty ? note : '$reason — $note';
                }
                if (reason.trim().isEmpty) {
                  return;
                }
                Navigator.of(dialogContext).pop(reason.trim());
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
    controller.clear();
    return result;
  }

  Future<void> _showRescheduleDialog(BuildContext context) async {
    final jobId = widget.job.jobId as int?;
    if (jobId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Job ID not found',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = TimeOfDay.now();
    final notesController = _rescheduleNotesController;
    notesController.clear();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFF)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Text(
                        'Think About\nRescheduling',
                        textAlign: TextAlign.center,
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Date Time Picker
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colorScheme.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            // Date Selector
                            InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: dialogContext,
                                  initialDate: selectedDate,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 365),
                                  ),
                                );
                                if (picked != null) {
                                  setState(() => selectedDate = picked);
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          DateFormat('EEE MMM d')
                                              .format(selectedDate),
                                          style: textTheme.bodyLarge?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: colorScheme.primary,
                                          ),
                                        ),
                                        Text(
                                          DateFormat('yyyy').format(selectedDate),
                                          style: textTheme.bodySmall?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Icon(
                                      Icons.calendar_today,
                                      color: colorScheme.primary,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Divider(
                              height: 1,
                              color: colorScheme.primary.withValues(alpha: 0.1),
                            ),
                            // Time Selector
                            InkWell(
                              onTap: () async {
                                final picked = await showTimePicker(
                                  context: dialogContext,
                                  initialTime: selectedTime,
                                );
                                if (picked != null) {
                                  setState(() => selectedTime = picked);
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      selectedTime.format(dialogContext),
                                      style: textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                    Icon(
                                      Icons.access_time,
                                      color: colorScheme.primary,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Notes TextField
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colorScheme.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: TextField(
                          controller: notesController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Leave notes here',
                            hintStyle: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.6,
                              ),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(null),
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                backgroundColor: colorScheme.error,
                                foregroundColor: Colors.white,
                                elevation: 0,
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                final scheduledDateTime = DateTime(
                                  selectedDate.year,
                                  selectedDate.month,
                                  selectedDate.day,
                                  selectedTime.hour,
                                  selectedTime.minute,
                                );
                                Navigator.of(dialogContext).pop({
                                  'date': scheduledDateTime,
                                  'notes': notesController.text.trim(),
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                backgroundColor: const Color(0xFFFF9800),
                                foregroundColor: Colors.white,
                                elevation: 0,
                              ),
                              child: const Text(
                                'Reschedule',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );

    if (result == null || !mounted) {
      return;
    }

    // Process reschedule
    final scheduledDate = result['date'] as DateTime;
    final notes = result['notes'] as String?;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final datasource = RescheduleJobDatasource();
      final response = await datasource.rescheduleJob(
        jobId: jobId,
        newDate: scheduledDate,
        notes: notes,
      );

      if (!mounted) return;

      Navigator.of(context).pop(); // Close loading

      final success = response.success == true;
      final message = response.message ??
          (success ? 'Job rescheduled successfully' : 'Failed to reschedule');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.white)),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

      if (success) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      log('Failed to reschedule job: ${e.toString()}');
      Navigator.of(context).pop(); // Close loading

      // Extract error message
      String errorMessage = 'Failed to reschedule job';
      final exceptionMessage = e.toString();
      if (exceptionMessage.startsWith('Exception: ')) {
        errorMessage = exceptionMessage.substring('Exception: '.length);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMessage,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _cancelJob(BuildContext context) async {
    final jobId = widget.job.jobId as int?;
    if (jobId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Job ID not found',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // First, show reschedule dialog
    await _showRescheduleDialog(context);
    
    // If user returns from reschedule dialog without rescheduling,
    // they might want to proceed with cancel
    if (!mounted) return;
    
    // Ask for confirmation to cancel
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Cancel Job'),
            content: const Text('Are you sure you want to cancel this job?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('No'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Yes, Cancel'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed || !mounted) {
      return;
    }

    final reason = await _askCancelReason(context);
    if (!mounted) return;
    if (reason == null || reason.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please provide a reason',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final datasource = CancelJobDatasource();
      final response = await datasource.cancelJob(
        jobId: jobId,
        reason: reason.trim(),
      );

      if (!mounted) return;

      Navigator.of(context).pop();

      final success = response.success == true;
      final message =
          response.message ??
          (success ? 'Success Cancel Job' : 'Failed to cancel job');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.white)),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

      if (success) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      log('Failed to cancel job: ${e.toString()}');
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to cancel job',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _navigateToJob(BuildContext context) async {
    final coordinates = _extractJobCoordinates(widget.job);

    if (coordinates != null) {
      if (widget.isOngoing) {
        final launched = await _launchExternalNavigation(context, coordinates);
        if (!launched && mounted) {
          await _openInternalMap(context, coordinates);
        }
      } else {
        await _openInternalMap(context, coordinates);
      }
      return;
    }

    await _fallbackNavigateUsingDatasource(context);
  }

  Future<void> _fallbackNavigateUsingDatasource(BuildContext context) async {
    final objectId = _extractJobId();
    if (objectId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Job ID not found')));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final datasource = TraxrootObjectsDatasource(TraxrootAuthDatasource());
      final status = await datasource.getObjectStatus(objectId: objectId);
      final entry = _extractCoordinateEntry(status);

      if (entry == null) {
        throw Exception('Destination coordinate not found');
      }

      final coordinate = _parseCoordinateEntry(entry);

      if (coordinate == null) {
        throw Exception('Invalid coordinate format');
      }

      if (!mounted) return;
      Navigator.of(context).pop();

      if (widget.isOngoing) {
        final launched = await _launchExternalNavigation(context, coordinate);
        if (!launched && mounted) {
          await _openInternalMap(context, coordinate);
        }
      } else {
        await _openInternalMap(context, coordinate);
      }
    } catch (e) {
      if (!mounted) return;
      log('Failed to open navigation: ${e.toString()}');
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to open navigation',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openInternalMap(
    BuildContext context,
    GeoPoint coordinate,
  ) async {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => JobNavigationPage(
          latitude: coordinate.lat,
          longitude: coordinate.lng,
          jobName: widget.job.jobName ?? 'Job Destination',
          address: widget.job.address,
        ),
      ),
    );
  }

  Future<bool> _launchExternalNavigation(
    BuildContext context,
    GeoPoint coordinate,
  ) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${coordinate.lat},${coordinate.lng}',
    );

    final canLaunchUri = await canLaunchUrl(uri);
    if (!canLaunchUri) {
      return false;
    }

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tidak dapat membuka Google Maps: ${e.toString()}'),
          ),
        );
      }
      return false;
    }
  }

  GeoPoint? _extractJobCoordinates(dynamic job) {
    final latitude = _parseCoordinate(job?.latitude ?? job?.lat);
    final longitude = _parseCoordinate(job?.longitude ?? job?.lng ?? job?.lon);
    if (latitude == null || longitude == null) {
      return null;
    }
    return GeoPoint(latitude, longitude);
  }

  int? _extractJobId() {
    final id = widget.job.jobId;
    if (id is int) return id;
    if (id is String) return int.tryParse(id);
    return null;
  }

  GeoPoint? _parseCoordinateEntry(Map<String, dynamic> entry) {
    final latitude = _parseCoordinate(
      entry['Latitude'] ?? entry['latitude'] ?? entry['Lat'] ?? entry['lat'],
    );
    final longitude = _parseCoordinate(
      entry['Longitude'] ??
          entry['longitude'] ??
          entry['Lon'] ??
          entry['lon'] ??
          entry['Lng'] ??
          entry['lng'],
    );
    if (latitude == null || longitude == null) {
      return null;
    }
    return GeoPoint(latitude, longitude);
  }

  Map<String, dynamic>? _extractCoordinateEntry(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      if (_hasCoordinateKeys(payload)) {
        return payload;
      }

      final data = payload['Data'] ?? payload['data'];
      if (data is List) {
        for (final item in data) {
          final extracted = _extractCoordinateEntry(item);
          if (extracted != null) {
            return extracted;
          }
        }
      }

      final result = payload['Result'] ?? payload['result'];
      if (result is List) {
        for (final item in result) {
          final extracted = _extractCoordinateEntry(item);
          if (extracted != null) {
            return extracted;
          }
        }
      }
    } else if (payload is List) {
      for (final item in payload) {
        final extracted = _extractCoordinateEntry(item);
        if (extracted != null) {
          return extracted;
        }
      }
    }

    return null;
  }

  bool _hasCoordinateKeys(Map<String, dynamic> payload) {
    final lowerKeys = payload.keys.map((k) => k.toLowerCase()).toSet();
    return lowerKeys.contains('latitude') || lowerKeys.contains('lat');
  }

  double? _parseCoordinate(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
