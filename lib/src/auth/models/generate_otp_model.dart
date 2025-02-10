import 'dart:convert';

GenerateOtpModel generateOtpModelFromJson(String str) => GenerateOtpModel.fromJson(json.decode(str));

String generateOtpModelToJson(GenerateOtpModel data) => json.encode(data.toJson());

class GenerateOtpModel {
    String message;
    String otp;

    GenerateOtpModel({
        required this.message,
        required this.otp,
    });

    factory GenerateOtpModel.fromJson(Map<String, dynamic> json) => GenerateOtpModel(
        message: json["message"],
        otp: json["otp"],
    );

    Map<String, dynamic> toJson() => {
        "message": message,
        "otp": otp,
    };
}