import 'dart:convert';

RegistrationModel registrationModelFromJson(String str) => RegistrationModel.fromJson(json.decode(str));

String registrationModelToJson(RegistrationModel data) => json.encode(data.toJson());

class RegistrationModel {
    String email;
    String username;
    String password;
    String re_password;

    RegistrationModel({
        required this.email,
        required this.username,
        required this.password,
        required this.re_password,
    });

    factory RegistrationModel.fromJson(Map<String, dynamic> json) => RegistrationModel(
        email: json["email"],
        username: json["username"],
        password: json["password"],
        re_password: json["re_password"],
    );

    Map<String, dynamic> toJson() => {
        "email": email,
        "username": username,
        "password": password,
        "re_password": re_password,
    };
}