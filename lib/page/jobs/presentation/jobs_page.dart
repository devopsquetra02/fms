import 'package:flutter/material.dart';
import 'package:fms/data/datasource/get_job_datasource.dart';
import 'package:fms/data/datasource/get_job_history_datasource.dart';
import 'package:fms/data/models/response/get_job_response_model.dart';
import 'package:fms/page/jobs/presentation/job_details_page.dart';
import 'package:fms/data/datasource/get_job_ongoing_datasource.dart';

import '../../../data/models/response/get_job_history__response_model.dart'
    as history;
import 'job_history_detail_page.dart';

class JobsPage extends StatefulWidget {
  const JobsPage({super.key});

  @override
  State<JobsPage> createState() => _JobsPageState();
}

class _JobsPageState extends State<JobsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoadingAllJobs = true;
  bool _isLoadingHistoryJobs = true;
  bool _isLoadingOngoingJobs = true;
  GetJobResponseModel? _allJobsResponse;
  history.GetJobHistoryResponseModel? _historyJobsResponse;
  GetJobResponseModel? _ongoingJobsResponse;
  String? _errorAllJobs;
  String? _errorHistoryJobs;
  String? _errorOngoingJobs;

  final GetJobDatasource _getJobDatasource = GetJobDatasource();
  final GetJobHistoryDatasource _getJobHistoryDatasource =
      GetJobHistoryDatasource();
  final GetJobOngoingDatasource _getJobOngoingDatasource =
      GetJobOngoingDatasource();

  Future<void> _fetchAllJobs() async {
    try {
      if (mounted) {
        setState(() {
          _isLoadingAllJobs = true;
          _errorAllJobs = null;
        });
      }
      _allJobsResponse = await _getJobDatasource.getJob();
    } catch (e) {
      _errorAllJobs = e.toString();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAllJobs = false;
        });
      }
    }
  }

  Future<void> _fetchHistoryJobs() async {
    try {
      if (mounted) {
        setState(() {
          _isLoadingHistoryJobs = true;
          _errorHistoryJobs = null;
        });
      }
      _historyJobsResponse = await _getJobHistoryDatasource.getJobHistory();
    } catch (e) {
      _errorHistoryJobs = e.toString();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingHistoryJobs = false;
        });
      }
    }
  }

  Future<void> _fetchOngoingJobs() async {
    try {
      if (mounted) {
        setState(() {
          _isLoadingOngoingJobs = true;
          _errorOngoingJobs = null;
        });
      }
      _ongoingJobsResponse = await _getJobOngoingDatasource.getOngoingJobs();
    } catch (e) {
      _errorOngoingJobs = e.toString();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingOngoingJobs = false;
        });
      }
    }
  }

  Future<void> _refresh() async {
    await Future.wait([
      _fetchAllJobs(),
      _fetchOngoingJobs(),
      _fetchHistoryJobs(),
    ]);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchAllJobs();
    _fetchOngoingJobs();
    _fetchHistoryJobs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // title: const Text(
        //   'Activity',
        //   style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        // ),
        bottom: TabBar(
          controller: _tabController,
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
        controller: _tabController,
        children: [_getAllJob(), _getOngoingJob(), _getHistoryJob()],
      ),
    );
  }

  Widget _getAllJob() {
    if (_isLoadingAllJobs) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorAllJobs != null) {
      return Center(child: Text('Error: $_errorAllJobs'));
    }
    if (_allJobsResponse?.data == null || _allJobsResponse!.data!.isEmpty) {
      return const Center(child: Text('No jobs found'));
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _allJobsResponse!.data!.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final job = _allJobsResponse!.data![index];
          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => JobDetailsPage(job: job),
                ),
              );
            },
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.jobName ?? '',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    // Customer and Date row
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            job.customerName ?? 'Unknown Customer',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                        if (job.jobDate != null) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            job.jobDate!.toString().split(' ')[0],
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Address row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            job.address ?? 'No address',
                            style: Theme.of(context).textTheme.bodyMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Job Type and Status chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _buildJobTypeChip(context, job.typeJob),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Open',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => JobDetailsPage(job: job),
                            ),
                          );
                          if (result == true) {
                            _refresh();
                          }
                        },
                        child: const Text('DETAILS'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _getOngoingJob() {
    if (_isLoadingOngoingJobs) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorOngoingJobs != null) {
      return Center(child: Text('Error: $_errorOngoingJobs'));
    }
    if (_ongoingJobsResponse?.data == null ||
        _ongoingJobsResponse!.data!.isEmpty) {
      return const Center(child: Text('No ongoing jobs found'));
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _ongoingJobsResponse!.data!.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final job = _ongoingJobsResponse!.data![index];
          return InkWell(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      JobDetailsPage(job: job, isOngoing: true),
                ),
              );
              if (result == true) {
                _refresh();
              }
            },
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.jobName ?? '',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            job.customerName ?? 'Unknown Customer',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                        if (job.jobDate != null) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            job.jobDate!.toString().split(' ')[0],
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            job.address ?? 'No address',
                            style: Theme.of(context).textTheme.bodyMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _buildJobTypeChip(context, job.typeJob),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'On Going',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Colors.orange.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  JobDetailsPage(job: job, isOngoing: true),
                            ),
                          );
                          if (result == true) {
                            _refresh();
                          }
                        },
                        child: const Text('DETAILS'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _getHistoryJob() {
    if (_isLoadingHistoryJobs) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorHistoryJobs != null) {
      return Center(child: Text('Error: $_errorHistoryJobs'));
    }
    if (_historyJobsResponse?.data == null ||
        _historyJobsResponse!.data!.isEmpty) {
      return const Center(child: Text('No history jobs found'));
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _historyJobsResponse!.data!.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final job = _historyJobsResponse!.data![index];
          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => JobHistoryDetailPage(job: job),
                ),
              );
            },
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.jobName ?? '',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    // Customer and Date row
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            job.customerName ?? 'Unknown Customer',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                        if (job.jobDate != null) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            job.jobDate!.toString().split(' ')[0],
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Address row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            job.address ?? 'No address',
                            style: Theme.of(context).textTheme.bodyMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Job Type and Status chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _buildJobTypeChip(context, job.typeJob),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Completed',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  JobHistoryDetailPage(job: job),
                            ),
                          );
                        },
                        child: const Text('DETAILS'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
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

  Widget _buildJobTypeChip(BuildContext context, int? type) {
    final typeString = _getJobTypeString(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        typeString,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
