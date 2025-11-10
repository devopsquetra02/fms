import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:fms/controllers/jobs_controller.dart';
import 'package:fms/data/models/response/get_job_response_model.dart';
import 'package:fms/page/jobs/presentation/job_details_page.dart';
import 'package:fms/data/models/response/get_job_history__response_model.dart'
    as history;
import '../widget/job_summary_card.dart';
import 'job_history_detail_page.dart';

class JobsPage extends StatelessWidget {
  const JobsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(JobsController());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: controller.tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'All Job'),
            Tab(text: 'Ongoing'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: controller.tabController,
        children: [
          _getAllJob(controller, context),
          _getOngoingJob(controller, context),
          _getHistoryJob(controller, context),
        ],
      ),
    );
  }

  Widget _buildRefreshableMessage(JobsController controller, String message) {
    return RefreshIndicator(
      onRefresh: controller.refresh,
      triggerMode: RefreshIndicatorTriggerMode.anywhere,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: constraints.maxHeight,
                child: Center(child: Text(message)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _getAllJob(JobsController controller, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = colorScheme.primary;

    return Obx(() {
      if (controller.isLoadingAllJobs.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.errorAllJobs.value != null) {
        return _buildRefreshableMessage(
          controller,
          'Error: ${controller.errorAllJobs.value}',
        );
      }
      if (controller.allJobsResponse.value?.data == null ||
          controller.allJobsResponse.value!.data!.isEmpty) {
        return _buildRefreshableMessage(controller, 'No jobs found');
      }

      return RefreshIndicator(
        onRefresh: controller.refresh,
        triggerMode: RefreshIndicatorTriggerMode.anywhere,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: controller.allJobsResponse.value!.data!.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final job = controller.allJobsResponse.value!.data![index];
            return JobSummaryCard(
              title: job.jobName ?? 'Untitled Job',
              customerName: job.customerName,
              address: job.address,
              dateLabel: job.jobDate != null ? _formatDate(job.jobDate) : null,
              badges: [
                _buildJobTypeBadge(context, job.typeJob),
                _buildStatusBadge(
                  label: 'Open',
                  color: accent,
                  icon: Icons.outlined_flag,
                ),
              ],
              accentColor: accent,
              onTap: () => _openJobDetails(job),
              onDetails: () => _openJobDetails(job),
              detailsLabel: 'Details',
            );
          },
        ),
      );
    });
  }

  Widget _getOngoingJob(JobsController controller, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = colorScheme.primary;

    return Obx(() {
      if (controller.isLoadingOngoingJobs.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.errorOngoingJobs.value != null) {
        return _buildRefreshableMessage(
          controller,
          'Error: ${controller.errorOngoingJobs.value}',
        );
      }
      if (controller.ongoingJobsResponse.value?.data == null ||
          controller.ongoingJobsResponse.value!.data!.isEmpty) {
        return _buildRefreshableMessage(controller, 'No ongoing jobs found');
      }

      return RefreshIndicator(
        onRefresh: controller.refresh,
        triggerMode: RefreshIndicatorTriggerMode.anywhere,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: controller.ongoingJobsResponse.value!.data!.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final job = controller.ongoingJobsResponse.value!.data![index];
            return JobSummaryCard(
              title: job.jobName ?? 'Untitled Job',
              customerName: job.customerName,
              address: job.address,
              dateLabel: job.jobDate != null ? _formatDate(job.jobDate) : null,
              badges: [
                _buildJobTypeBadge(context, job.typeJob),
                _buildStatusBadge(
                  label: 'In Progress',
                  color: accent,
                  icon: Icons.timelapse,
                ),
              ],
              accentColor: accent,
              onTap: () => _openJobDetails(job, isOngoing: true),
              onDetails: () => _openJobDetails(job, isOngoing: true),
              detailsLabel: 'Resume',
            );
          },
        ),
      );
    });
  }

  Widget _getHistoryJob(JobsController controller, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = colorScheme.primary;

    return Obx(() {
      if (controller.isLoadingHistoryJobs.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.errorHistoryJobs.value != null) {
        return _buildRefreshableMessage(
          controller,
          'Error: ${controller.errorHistoryJobs.value}',
        );
      }
      if (controller.historyJobsResponse.value?.data == null ||
          controller.historyJobsResponse.value!.data!.isEmpty) {
        return _buildRefreshableMessage(controller, 'No history jobs found');
      }

      return RefreshIndicator(
        onRefresh: controller.refresh,
        triggerMode: RefreshIndicatorTriggerMode.anywhere,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: controller.historyJobsResponse.value!.data!.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final job = controller.historyJobsResponse.value!.data![index];
            return JobSummaryCard(
              title: job.jobName ?? 'Untitled Job',
              customerName: job.customerName,
              address: job.address,
              dateLabel: job.jobDate != null ? _formatDate(job.jobDate) : null,
              badges: [
                _buildJobTypeBadge(context, job.typeJob),
                _buildStatusBadge(
                  label: 'Completed',
                  color: Colors.green,
                  icon: Icons.verified_outlined,
                ),
              ],
              accentColor: accent,
              onTap: () => _openHistoryDetails(job),
              onDetails: () => _openHistoryDetails(job),
              detailsLabel: 'Report',
            );
          },
        ),
      );
    });
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

  JobCardBadge _buildJobTypeBadge(BuildContext context, int? type) {
    final typeString = _getJobTypeString(type);
    final accent = Theme.of(context).colorScheme.primary;
    return JobCardBadge(
      label: typeString,
      icon: Icons.work_outline,
      backgroundColor: accent.withValues(alpha: 0.22),
      foregroundColor: accent,
      borderColor: accent.withValues(alpha: 0.4),
    );
  }

  JobCardBadge _buildStatusBadge({
    required String label,
    required Color color,
    IconData? icon,
  }) {
    return JobCardBadge(
      label: label,
      icon: icon,
      backgroundColor: color.withValues(alpha: 0.14),
      foregroundColor: color,
      borderColor: color.withValues(alpha: 0.28),
    );
  }

  void _openJobDetails(Data job, {bool isOngoing = false}) async {
    final result = await Get.to(
      () => JobDetailsPage(job: job, isOngoing: isOngoing),
    );
    if (result is Map && result['refresh'] == true) {
      final controller = Get.find<JobsController>();
      await controller.refresh();
      
      // Navigate to ongoing tab if job was just accepted
      if (result['navigateToOngoing'] == true) {
        controller.tabController.animateTo(1); // Index 1 is Ongoing tab
      }
    } else if (result == true) {
      Get.find<JobsController>().refresh();
    }
  }

  void _openHistoryDetails(history.Data job) {
    Get.to(() => JobHistoryDetailPage(job: job));
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
