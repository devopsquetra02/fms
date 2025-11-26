import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fms/data/models/response/get_job_history__response_model.dart';

import 'job_navigation_page.dart';
import 'job_report_page.dart';

/// A page displaying details of a completed job from history.
class JobHistoryDetailPage extends StatelessWidget {
  final Data job;
  const JobHistoryDetailPage({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final latitude = job.latitude;
    final longitude = job.longitude;
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

    return Scaffold(
      appBar: AppBar(
        title: Text(job.jobName ?? 'Job History Details'),
        // actions: [
        //   IconButton(
        //     tooltip: 'More',
        //     icon: const Icon(Icons.more_vert),
        //     onPressed: () {},
        //   ),
        // ],
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
                                child: const Icon(
                                  Icons.history,
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
                                      'Completed job record',
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
                                'Status: Completed',
                                icon: Icons.verified_outlined,
                                foreground: Colors.white,
                                background: const Color(
                                  0xFF34C759,
                                ).withValues(alpha: 0.25),
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

                const SizedBox(height: 12),

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
                            Row(
                              children: [
                                const Icon(
                                  Icons.phone,
                                  color: Color(0xFF1E58FF),
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
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

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
                            onPressed: latitude != null && longitude != null
                                ? () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => JobNavigationPage(
                                          latitude: latitude,
                                          longitude: longitude,
                                          jobName:
                                              job.jobName ?? 'Job Destination',
                                          address: job.address,
                                        ),
                                      ),
                                    );
                                  }
                                : () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Coordinates not available',
                                        ),
                                      ),
                                    );
                                  },
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

                const SizedBox(height: 12),

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
                        colors: [Color(0xFFFFFFFF), Color(0xFFEAF1FF)],
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
                          if (job.assignWhen != null) ...[
                            const SizedBox(height: 12),
                            _InfoRow(
                              label: 'Assigned At',
                              value: _formatDate(job.assignWhen),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

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
                        colors: [Color(0xFFFFFFFF), Color(0xFFF6F8FF)],
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
                            icon: Icons.work_outline,
                            title: 'Work Details',
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Job completed successfully. All electrical connections have been restored and tested.',
                            style: textTheme.bodyMedium?.copyWith(height: 1.5),
                          ),
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
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => JobReportPage(job: job),
                      ),
                    );
                  },
                  icon: const Icon(Icons.description_outlined),
                  label: const Text('View Report'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    side: BorderSide(
                      color: colorScheme.primary.withValues(alpha: 0.4),
                    ),
                    foregroundColor: colorScheme.primary,
                    overlayColor: colorScheme.primary.withValues(alpha: 0.08),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Expanded(
              //   child: ElevatedButton.icon(
              //     onPressed: () {
              //       ScaffoldMessenger.of(context).showSnackBar(
              //         const SnackBar(content: Text('Similar job created')),
              //       );
              //     },
              //     icon: const Icon(Icons.add),
              //     label: const Text('Similar Job'),
              //     style: ElevatedButton.styleFrom(
              //       padding: const EdgeInsets.symmetric(vertical: 14),
              //       shape: RoundedRectangleBorder(
              //         borderRadius: BorderRadius.circular(16),
              //       ),
              //       backgroundColor: colorScheme.primary,
              //       foregroundColor: colorScheme.onPrimary,
              //       shadowColor: colorScheme.primary.withValues(alpha:0.4),
              //       overlayColor: colorScheme.primary.withValues(alpha:0.12),
              //     ),
              //   ),
              // ),
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
      case 4:
        return 'Disconnection';
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
