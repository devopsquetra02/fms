import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fms/data/datasource/cancel_job_datasource.dart';
import 'package:fms/data/datasource/driver_get_job_datasource.dart';
import 'package:fms/data/datasource/finish_job_datasource.dart';
import 'package:fms/data/datasource/get_job_datasource.dart';
import 'package:fms/data/datasource/get_job_history_datasource.dart';
import 'package:fms/data/datasource/get_job_ongoing_datasource.dart';
import 'package:fms/data/datasource/reschedule_job_datasource.dart';
import 'package:fms/data/datasource/traxroot_datasource.dart';
import 'package:fms/data/models/response/cancel_job_response_model.dart';
import 'package:fms/data/models/response/driver_get_job_response_model.dart';
import 'package:fms/data/models/response/finish_job_response_model.dart';
import 'package:fms/data/models/response/get_job_response_model.dart';
import 'package:fms/data/models/response/get_job_ongoing_response_model.dart'
    as ongoing;
import 'package:fms/data/models/response/get_job_history__response_model.dart'
    as history;
import 'package:fms/data/models/response/reschedule_job_response_model.dart';
import 'package:fms/data/models/traxroot_object_status_model.dart';

/// Controller for managing job lists (all, ongoing, history) and job actions.
class JobsController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final Rx<GetJobResponseModel?> allJobsResponse = Rx<GetJobResponseModel?>(
    null,
  );

  final RxnString errorAllJobs = RxnString();
  final RxnString errorHistoryJobs = RxnString();
  final RxnString errorOngoingJobs = RxnString();
  final Rx<history.GetJobHistoryResponseModel?> historyJobsResponse =
      Rx<history.GetJobHistoryResponseModel?>(null);

  final RxBool isLoadingAllJobs = true.obs;
  final RxBool isLoadingHistoryJobs = true.obs;
  final RxBool isLoadingOngoingJobs = true.obs;
  final Rx<ongoing.GetJobOngoingResponseModel?> ongoingJobsResponse =
      Rx<ongoing.GetJobOngoingResponseModel?>(null);

  final RxMap<int, DateTime> rescheduledJobs = <int, DateTime>{}.obs;
  late TabController tabController;

  final _getJobDatasource = GetJobDatasource();
  final _getJobHistoryDatasource = GetJobHistoryDatasource();
  final _getJobOngoingDatasource = GetJobOngoingDatasource();
  final _driverGetJobDatasource = DriverGetJobDatasource();
  final _finishJobDatasource = FinishJobDatasource();
  final _rescheduleJobDatasource = RescheduleJobDatasource();
  final _cancelJobDatasource = CancelJobDatasource();
  final _traxrootObjectsDatasource = TraxrootObjectsDatasource(
    TraxrootAuthDatasource(),
  );

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 3, vsync: this);
    fetchAllJobs();
    fetchOngoingJobs();
    fetchHistoryJobs();
  }

  /// Fetches the list of all jobs.
  Future<void> fetchAllJobs() async {
    try {
      isLoadingAllJobs.value = true;
      errorAllJobs.value = null;
      allJobsResponse.value = await _getJobDatasource.getJob();
    } catch (e) {
      errorAllJobs.value = e.toString();
    } finally {
      isLoadingAllJobs.value = false;
    }
  }

  /// Fetches the history of completed jobs.
  Future<void> fetchHistoryJobs() async {
    try {
      isLoadingHistoryJobs.value = true;
      errorHistoryJobs.value = null;
      historyJobsResponse.value = await _getJobHistoryDatasource
          .getJobHistory();
    } catch (e) {
      errorHistoryJobs.value = e.toString();
    } finally {
      isLoadingHistoryJobs.value = false;
    }
  }

  /// Fetches the list of ongoing jobs.
  Future<void> fetchOngoingJobs() async {
    try {
      isLoadingOngoingJobs.value = true;
      errorOngoingJobs.value = null;
      ongoingJobsResponse.value = await _getJobOngoingDatasource
          .getOngoingJobs();
      final jobs = ongoingJobsResponse.value?.data ?? [];
      final activeIds = jobs.map((job) => job.jobId).whereType<int>().toSet();
      rescheduledJobs.removeWhere((jobId, _) => !activeIds.contains(jobId));
    } catch (e) {
      errorOngoingJobs.value = e.toString();
    } finally {
      isLoadingOngoingJobs.value = false;
    }
  }

  /// Refreshes all job lists.
  Future<void> refresh() async {
    await Future.wait([fetchAllJobs(), fetchOngoingJobs(), fetchHistoryJobs()]);
  }

  /// Marks a job as rescheduled locally.
  void markJobRescheduled(int jobId, DateTime scheduledDate) {
    rescheduledJobs[jobId] = scheduledDate;
  }

  /// Clears the rescheduled status of a job locally.
  void clearJobRescheduled(int jobId) {
    rescheduledJobs.remove(jobId);
  }

  /// Starts a job (driver claims it).
  Future<DriverGetJobResponseModel> startJob(int jobId) {
    return _driverGetJobDatasource.driverGetJob(jobId: jobId);
  }

  /// Finishes a job with optional images and notes.
  Future<FinishJobResponseModel> finishJob({
    required int jobId,
    required List<String> imagesBase64,
    String? notes,
  }) {
    return _finishJobDatasource.finishJob(
      jobId: jobId,
      imagesBase64: imagesBase64,
      notes: notes,
    );
  }

  /// Reschedules a job to a new date.
  Future<RescheduleJobResponseModel> rescheduleJob({
    required int jobId,
    required DateTime newDate,
    String? notes,
  }) {
    return _rescheduleJobDatasource.rescheduleJob(
      jobId: jobId,
      newDate: newDate,
      notes: notes,
    );
  }

  /// Cancels a job with a reason.
  Future<CancelJobResponseModel> cancelJob({
    required int jobId,
    required String reason,
  }) {
    return _cancelJobDatasource.cancelJob(jobId: jobId, reason: reason);
  }

  /// Gets the Traxroot status for a specific object/vehicle.
  Future<TraxrootObjectStatusModel> getObjectStatusForJob(int objectId) {
    return _traxrootObjectsDatasource.getObjectStatus(objectId: objectId);
  }
}
