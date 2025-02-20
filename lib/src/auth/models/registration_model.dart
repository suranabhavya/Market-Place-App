import 'dart:convert';

RegistrationModel registrationModelFromJson(String str) => RegistrationModel.fromJson(json.decode(str));

String registrationModelToJson(RegistrationModel data) => json.encode(data.toJson());

class RegistrationModel {
    String email;
    String username;
    String name;
    String password;
    String confirm_password;

    RegistrationModel({
        required this.email,
        required this.username,
        required this.name,
        required this.password,
        required this.confirm_password,
    });

    factory RegistrationModel.fromJson(Map<String, dynamic> json) => RegistrationModel(
        email: json["email"],
        username: json["username"],
        name: json["name"],
        password: json["password"],
        confirm_password: json["confirm_password"],
    );

    Map<String, dynamic> toJson() => {
        "email": email,
        "username": username,
        "name": name,
        "password": password,
        "confirm_password": confirm_password,
    };
}