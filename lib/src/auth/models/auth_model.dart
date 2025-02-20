import 'dart:convert';

AuthModel authModelFromJson(String str) => AuthModel.fromJson(json.decode(str));

String authModelToJson(AuthModel data) => json.encode(data.toJson());

class AuthModel {
    User user;
    String token;
    String message;

    AuthModel({
        required this.user,
        required this.token,
        required this.message,
    });

    factory AuthModel.fromJson(Map<String, dynamic> json) => AuthModel(
        user: User.fromJson(json["user"]),
        token: json["token"],
        message: json["message"],
    );

    Map<String, dynamic> toJson() => {
        "user": user.toJson(),
        "token": token,
        "message": message,
    };
}

class User {
    int id;
    String email;
    String username;
    String name;
    dynamic mobileNumber;
    dynamic profilePhoto;
    String schoolEmail;
    bool schoolEmailVerified;

    User({
        required this.id,
        required this.email,
        required this.username,
        required this.name,
        required this.mobileNumber,
        required this.profilePhoto,
        required this.schoolEmail,
        required this.schoolEmailVerified,
    });

    factory User.fromJson(Map<String, dynamic> json) => User(
        id: json["id"],
        email: json["email"],
        username: json["username"],
        name: json["name"],
        mobileNumber: json["mobile_number"],
        profilePhoto: json["profile_photo"],
        schoolEmail: json["school_email"],
        schoolEmailVerified: json["school_email_verified"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "email": email,
        "username": username,
        "name": name,
        "mobile_number": mobileNumber,
        "profile_photo": profilePhoto,
        "school_email": schoolEmail,
        "school_email_verified": schoolEmailVerified,
    };
}