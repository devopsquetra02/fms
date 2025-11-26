import 'dart:convert';

/// Response model for fetching user profile.
class ProfileResponseModel {
  final bool? success;
  final Data? data;

  ProfileResponseModel({this.success, this.data});

  factory ProfileResponseModel.fromJson(String str) =>
      ProfileResponseModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory ProfileResponseModel.fromMap(Map<String, dynamic> json) =>
      ProfileResponseModel(
        success: json["Success"],
        data: json["Data"] == null ? null : Data.fromMap(json["Data"]),
      );

  Map<String, dynamic> toMap() => {"Success": success, "Data": data?.toMap()};
}

/// Data object containing user profile details.
class Data {
  final String? fullname;
  final String? email;
  final String? phoneNumber;

  Data({this.fullname, this.email, this.phoneNumber});

  factory Data.fromJson(String str) => Data.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory Data.fromMap(Map<String, dynamic> json) => Data(
    fullname: json["Fullname"],
    email: json["Email"],
    phoneNumber: json["PhoneNumber"],
  );

  Map<String, dynamic> toMap() => {
    "Fullname": fullname,
    "Email": email,
    "PhoneNumber": phoneNumber,
  };
}
