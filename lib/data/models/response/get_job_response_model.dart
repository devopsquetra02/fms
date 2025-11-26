import 'dart:convert';

/// Response model for fetching available jobs.
class GetJobResponseModel {
  final bool? success;
  final List<Data>? data;

  GetJobResponseModel({this.success, this.data});

  factory GetJobResponseModel.fromJson(String str) =>
      GetJobResponseModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory GetJobResponseModel.fromMap(Map<String, dynamic> json) =>
      GetJobResponseModel(
        success: json["Success"],
        data: json["Data"] == null
            ? []
            : List<Data>.from(json["Data"]!.map((x) => Data.fromMap(x))),
      );

  Map<String, dynamic> toMap() => {
    "Success": success,
    "Data": data == null ? [] : List<dynamic>.from(data!.map((x) => x.toMap())),
  };
}

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

/// Data object representing an available job.
class Data {
  final int? jobId;
  final String? jobName;
  final dynamic userId;
  final int? customerId;
  final int? typeJob;
  final String? createdBy;
  final DateTime? jobDate;
  final DateTime? createdAt;
  final dynamic assignWhen;
  final String? customerName;
  final String? phoneNumber;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? typeJobName;

  Data({
    this.jobId,
    this.jobName,
    this.userId,
    this.customerId,
    this.typeJob,
    this.createdBy,
    this.jobDate,
    this.createdAt,
    this.assignWhen,
    this.customerName,
    this.phoneNumber,
    this.address,
    this.latitude,
    this.longitude,
    this.typeJobName,
  });

  factory Data.fromJson(String str) => Data.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory Data.fromMap(Map<String, dynamic> json) => Data(
    jobId: json["JobID"],
    jobName: json["JobName"],
    userId: json["UserID"],
    customerId: json["CustomerID"],
    typeJob: json["TypeJob"],
    createdBy: json["CreatedBy"],
    jobDate: json["JobDate"] == null ? null : DateTime.parse(json["JobDate"]),
    createdAt: json["created_at"] == null
        ? null
        : DateTime.parse(json["created_at"]),
    assignWhen: json["AssignWhen"],
    customerName: json["CustomerName"],
    phoneNumber: json["PhoneNumber"],
    address: json["Address"],
    latitude: _parseDouble(json["Latitude"]),
    longitude: _parseDouble(json["Longitude"]),
    typeJobName: json["TypeJobName"],
  );

  Map<String, dynamic> toMap() => {
    "JobID": jobId,
    "JobName": jobName,
    "UserID": userId,
    "CustomerID": customerId,
    "TypeJob": typeJob,
    "CreatedBy": createdBy,
    "JobDate":
        "${jobDate!.year.toString().padLeft(4, '0')}-${jobDate!.month.toString().padLeft(2, '0')}-${jobDate!.day.toString().padLeft(2, '0')}",
    "created_at": createdAt?.toIso8601String(),
    "AssignWhen": assignWhen,
    "CustomerName": customerName,
    "PhoneNumber": phoneNumber,
    "Address": address,
    "Latitude": latitude,
    "Longitude": longitude,
    "TypeJobName": typeJobName,
  };
}
