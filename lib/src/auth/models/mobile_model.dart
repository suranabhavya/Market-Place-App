import 'dart:convert';

MobileModel mobileModelFromJson(String str) => MobileModel.fromJson(json.decode(str));

String mobileModelToJson(MobileModel data) => json.encode(data.toJson());

class MobileModel {
    String mobile;

    MobileModel({
        required this.mobile,
    });

    factory MobileModel.fromJson(Map<String, dynamic> json) => MobileModel(
        mobile: json["mobile"],
    );

    Map<String, dynamic> toJson() => {
        "mobile": mobile,
    };
}