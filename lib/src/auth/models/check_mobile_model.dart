import 'dart:convert';

CheckMobileModel checkMobileModelFromJson(String str) => CheckMobileModel.fromJson(json.decode(str));

String checkMobileModelToJson(CheckMobileModel data) => json.encode(data.toJson());

class CheckMobileModel {
    String message;
    String mobile;

    CheckMobileModel({
        required this.message,
        required this.mobile,
    });

    factory CheckMobileModel.fromJson(Map<String, dynamic> json) => CheckMobileModel(
        message: json["message"],
        mobile: json["mobile"],
    );

    Map<String, dynamic> toJson() => {
        "message": message,
        "mobile": mobile,
    };
}