import 'dart:convert';

/// Response model for reschedule job requests.
class RescheduleJobResponseModel {
  final bool? success;
  final String? message;

  RescheduleJobResponseModel({this.success, this.message});

  factory RescheduleJobResponseModel.fromJson(String str) =>
      RescheduleJobResponseModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory RescheduleJobResponseModel.fromMap(Map<String, dynamic> json) =>
      RescheduleJobResponseModel(
        success: json['Success'] == true || json['success'] == true,
        message: (json['Message'] ?? json['message'])?.toString(),
      );

  Map<String, dynamic> toMap() => {'Success': success, 'Message': message};
}
