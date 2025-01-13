import 'dart:convert';

CheckEmailModel checkEmailModelFromJson(String str) => CheckEmailModel.fromJson(json.decode(str));

String checkEmailModelToJson(CheckEmailModel data) => json.encode(data.toJson());

class CheckEmailModel {
    String message;
    String email;

    CheckEmailModel({
        required this.message,
        required this.email,
    });

    factory CheckEmailModel.fromJson(Map<String, dynamic> json) => CheckEmailModel(
        message: json["message"],
        email: json["email"],
    );

    Map<String, dynamic> toJson() => {
        "message": message,
        "email": email,
    };
}