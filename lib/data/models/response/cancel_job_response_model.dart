import 'dart:convert';

/// Response model for cancel job requests.
class CancelJobResponseModel {
  final bool? success;
  final String? message;

  CancelJobResponseModel({this.success, this.message});

  factory CancelJobResponseModel.fromJson(String str) =>
      CancelJobResponseModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory CancelJobResponseModel.fromMap(Map<String, dynamic> json) =>
      CancelJobResponseModel(
        success: json['Success'] == true || json['success'] == true,
        message: (json['Message'] ?? json['message'])?.toString(),
      );

  Map<String, dynamic> toMap() => {'Success': success, 'Message': message};
}
