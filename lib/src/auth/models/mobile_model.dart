import 'dart:convert';

MobileModel mobileModelFromJson(String str) => MobileModel.fromJson(json.decode(str));

String mobileModelToJson(MobileModel data) => json.encode(data.toJson());

class MobileModel {
    String mobile_number;

    MobileModel({
        required this.mobile_number,
    });

    factory MobileModel.fromJson(Map<String, dynamic> json) => MobileModel(
        mobile_number: json["mobile_number"],
    );

    Map<String, dynamic> toJson() => {
        "mobile_number": mobile_number,
    };
}