import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/permissions/permission_helper.dart';
import '../../../data/datasource/finish_job_datasource.dart';
import '../../../data/datasource/traxroot_datasource.dart';
import '../../../core/models/geo.dart';
import '../../profile/presentation/profile_page.dart';
import '../widget/chip_job_detail.dart';

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
  @override
  void initState() {
    super.initState();
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
    final job = widget.job;
    final isOngoing = widget.isOngoing;
    return Scaffold(
      appBar: AppBar(
        title: Text(job.jobName ?? 'Job Details'),
        actions: [
          IconButton(
            tooltip: 'More',
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Show more options
              showModalBottomSheet(
                context: context,
                builder: (context) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.share),
                      title: const Text('Share'),
                      onTap: () {
                        Navigator.pop(context);
                        _shareJobDetails();
                      },
                    ),
                    // ListTile(
                    //   leading: const Icon(Icons.report),
                    //   title: const Text('Report'),
                    //   onTap: () {
                    //     Navigator.pop(context);
                    //     // Implement report functionality
                    //   },
                    // ),
                  ],
                ),
              );
            },
          ),
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
                // Header Card
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.assignment_turned_in,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                job.jobName ?? 'Job',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  ChipJobDetail(
                                    color: isOngoing
                                        ? Colors.orange
                                        : Colors.grey,
                                    label: isOngoing
                                        ? 'Status: Ongoing'
                                        : 'Status: Open',
                                  ),
                                  if (job.jobDate != null)
                                    ChipJobDetail(
                                      label:
                                          'Date: ${_formatDate(job.jobDate)}',
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Customer Information
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Customer',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          job.customerName ?? 'N/A',
                          style: theme.textTheme.bodyMedium,
                        ),
                        if (job.phoneNumber != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.phone,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                job.phoneNumber!,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Address
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.place, color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Address',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          job.address ?? 'N/A',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => _navigateToJob(context),
                          icon: const Icon(Icons.map_outlined),
                          label: const Text('Open in Map'),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Job Information
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Job Information',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _InfoRow(
                          label: 'Job Type',
                          value: _getJobTypeString(job.typeJob),
                        ),
                        _InfoRow(
                          label: 'Created By',
                          value: job.createdBy?.toString() ?? 'N/A',
                        ),
                        if (job.createdAt != null)
                          _InfoRow(
                            label: 'Created At',
                            value: _formatDate(job.createdAt),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 100), // for bottom action spacing
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
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Postpone feature coming soon'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.schedule),
                        label: const Text('Postpone'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Cancel feature coming soon'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('Cancel'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              if (isOngoing) const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _navigateToJob(context),
                      icon: const Icon(Icons.navigation_outlined),
                      label: const Text('Navigate'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
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
        // Kembali ke halaman sebelumnya dan minta refresh
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (context.mounted) {
        log('Failed to start job: ${e.toString()}');
        Navigator.of(context).pop(); // close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to start job',
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to finish job')));
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
