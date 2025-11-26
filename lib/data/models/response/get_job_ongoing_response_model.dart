import 'dart:convert';

/// Response model for fetching ongoing jobs.
class GetJobOngoingResponseModel {
  final bool? success;
  final List<Data>? data;

  GetJobOngoingResponseModel({this.success, this.data});

  factory GetJobOngoingResponseModel.fromJson(String str) =>
      GetJobOngoingResponseModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory GetJobOngoingResponseModel.fromMap(Map<String, dynamic> json) =>
      GetJobOngoingResponseModel(
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

/// Data object representing an ongoing job.
class Data {
  final int? jobId;
  final String? jobName;
  final int? userId;
  final int? customerId;
  final int? companyId;
  final int? typeJob;
  final String? createdBy;
  final DateTime? jobDate;
  final int? status; //1 or 3
  final dynamic notes;
  final DateTime? createdAt;
  final DateTime? assignWhen;
  final dynamic finishWhen;
  final int? listCompanyId;
  final String? customerName;
  final String? customerEmail;
  final String? phoneNumber;
  final String? address;
  final String? latitude;
  final String? longitude;
  final String? typeJobName;

  Data({
    this.jobId,
    this.jobName,
    this.userId,
    this.customerId,
    this.companyId,
    this.typeJob,
    this.createdBy,
    this.jobDate,
    this.status,
    this.notes,
    this.createdAt,
    this.assignWhen,
    this.finishWhen,
    this.listCompanyId,
    this.customerName,
    this.customerEmail,
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
    companyId: json["CompanyID"],
    typeJob: json["TypeJob"],
    createdBy: json["CreatedBy"],
    jobDate: json["JobDate"] == null ? null : DateTime.parse(json["JobDate"]),
    status: json["Status"], //1 or 3
    notes: json["Notes"],
    createdAt: json["created_at"] == null
        ? null
        : DateTime.parse(json["created_at"]),
    assignWhen: json["AssignWhen"] == null
        ? null
        : DateTime.parse(json["AssignWhen"]),
    finishWhen: json["FinishWhen"],
    listCompanyId: json["ListCompanyID"],
    customerName: json["CustomerName"],
    customerEmail: json["CustomerEmail"],
    phoneNumber: json["PhoneNumber"],
    address: json["Address"],
    latitude: json["Latitude"],
    longitude: json["Longitude"],
    typeJobName: json["TypeJobName"],
  );

  Map<String, dynamic> toMap() => {
    "JobID": jobId,
    "JobName": jobName,
    "UserID": userId,
    "CustomerID": customerId,
    "CompanyID": companyId,
    "TypeJob": typeJob,
    "CreatedBy": createdBy,
    "JobDate": jobDate?.toIso8601String(),
    "Status": status,
    "Notes": notes,
    "created_at": createdAt?.toIso8601String(),
    "AssignWhen": assignWhen?.toIso8601String(),
    "FinishWhen": finishWhen,
    "ListCompanyID": listCompanyId,
    "CustomerName": customerName,
    "CustomerEmail": customerEmail,
    "PhoneNumber": phoneNumber,
    "Address": address,
    "Latitude": latitude,
    "Longitude": longitude,
    "TypeJobName": typeJobName,
  };
}
