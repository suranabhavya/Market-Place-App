import 'dart:convert';

CheckEmailModel checkEmailModelFromJson(String str) => CheckEmailModel.fromJson(json.decode(str));

String checkEmailModelToJson(CheckEmailModel data) => json.encode(data.toJson());

class CheckEmailModel {
    final String? message;
    final String email;
    final String? error;
    final String? authProvider;

    CheckEmailModel({
        this.message,
        required this.email,
        this.error,
        this.authProvider,
    });

    factory CheckEmailModel.fromJson(Map<String, dynamic> json) => CheckEmailModel(
        message: json["message"],
        email: json["email"],
        error: json["error"],
        authProvider: json["auth_provider"],
    );

    Map<String, dynamic> toJson() => {
        "message": message,
        "email": email,
        "error": error,
        "auth_provider": authProvider,
    };
}