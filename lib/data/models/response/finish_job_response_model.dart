import 'dart:convert';

/// Response model for finish job requests.
class FinishJobResponseModel {
  final bool? success;
  final String? message;

  FinishJobResponseModel({this.success, this.message});

  factory FinishJobResponseModel.fromJson(String str) =>
      FinishJobResponseModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory FinishJobResponseModel.fromMap(Map<String, dynamic> json) =>
      FinishJobResponseModel(
        success: json['Success'] == true || json['success'] == true,
        message: (json['Message'] ?? json['message'])?.toString(),
      );

  Map<String, dynamic> toMap() => {'Success': success, 'Message': message};
}
