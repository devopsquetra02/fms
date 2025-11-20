import 'dart:convert';

class AuthResponseModel {
  final bool? success;
  final Data? data;

  AuthResponseModel({this.success, this.data});

  factory AuthResponseModel.fromJson(String str) =>
      AuthResponseModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory AuthResponseModel.fromMap(Map<String, dynamic> json) =>
      AuthResponseModel(
        success: json["Success"],
        data: json["Data"] == null ? null : Data.fromMap(json["Data"]),
      );

  Map<String, dynamic> toMap() => {"Success": success, "Data": data?.toMap()};
}

class Data {
  final int? userId;
  final String? apiKey;
  final String? company;
  final int? companyId;
  final int? companyType;
  final String? companyLabel;
  final String? usernameTraxroot;
  final String? passwordTraxroot;

  Data({
    this.userId,
    this.apiKey,
    this.company,
    this.companyId,
    this.companyType,
    this.companyLabel,
    this.usernameTraxroot,
    this.passwordTraxroot,
  });

  factory Data.fromJson(String str) => Data.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory Data.fromMap(Map<String, dynamic> json) => Data(
    userId: json["UserID"],
    apiKey: json["ApiKey"],
    company: json["Company"],
    companyId: json["CompanyID"],
    companyType: json["CompanyType"],
    companyLabel: json["CompanyLabel"],
    usernameTraxroot: json["UsernameTraxrooot"],
    passwordTraxroot: json["PasswordTraxrooot"],
  );

  Map<String, dynamic> toMap() => {
    "UserID": userId,
    "ApiKey": apiKey,
    "Company": company,
    "CompanyID": companyId,
    "CompanyType": companyType,
    "CompanyLabel": companyLabel,
    "UsernameTraxrooot": usernameTraxroot,
    "PasswordTraxrooot": passwordTraxroot,
  };
}
