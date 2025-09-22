import 'dart:convert';

class DriverGetJobResponseModel {
  final bool? success;
  final String? message;

  DriverGetJobResponseModel({this.success, this.message});

  factory DriverGetJobResponseModel.fromJson(String str) =>
      DriverGetJobResponseModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory DriverGetJobResponseModel.fromMap(Map<String, dynamic> json) =>
      DriverGetJobResponseModel(
        success: json['Success'],
        message: json['Message'],
      );

  Map<String, dynamic> toMap() => {
        'Success': success,
        'Message': message,
      };
}
