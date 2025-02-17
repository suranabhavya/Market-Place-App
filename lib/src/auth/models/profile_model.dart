import 'dart:convert';

ProfileModel profileModelFromJson(String str) => ProfileModel.fromJson(json.decode(str));

String profileModelToJson(ProfileModel data) => json.encode(data.toJson());

class ProfileModel {
    String email;
    String first_name;
    String username;
    String? profile_photo;
    String? mobile_number;
    String? school_email;
    bool school_email_verified;

    ProfileModel({
        required this.email,
        required this.first_name,
        required this.username,
        this.profile_photo,
        this.mobile_number,
        required this.school_email,
        required this.school_email_verified,
    });

    factory ProfileModel.fromJson(Map<String, dynamic> json) => ProfileModel(
        email: json["email"],
        first_name: json["first_name"],
        username: json["username"],
        profile_photo: json["profile_photo"] != null
            ? extractImagePath(json["profile_photo"])
            : null,
        mobile_number: json["mobile_number"],
        school_email: json["school_email"],
        school_email_verified: json["school_email_verified"] ?? false,
    );

    Map<String, dynamic> toJson() => {
        "email": email,
        "first_name": first_name,
        "username": username,
        "profile_photo": profile_photo,
        "mobile_number": mobile_number,
        "school_email": school_email,
        "school_email_verified": school_email_verified,
    };


  static String extractImagePath(String rawValue) {
    final RegExp regex = RegExp(r"profile_photos/([^>]+)");
    final match = regex.firstMatch(rawValue);
    if (match != null) {
      return "https://homiswapbucket.s3.amazonaws.com/${match.group(0)}"; // Adjust base URL
    }
    return "";
  }
}