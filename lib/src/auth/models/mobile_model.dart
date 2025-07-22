import 'dart:convert';

MobileModel mobileModelFromJson(String str) => MobileModel.fromJson(json.decode(str));

String mobileModelToJson(MobileModel data) => json.encode(data.toJson());

class MobileModel {
    String mobileNumber;

    MobileModel({
        required this.mobileNumber,
    });

    factory MobileModel.fromJson(Map<String, dynamic> json) => MobileModel(
        mobileNumber: json["mobile_number"],
    );

    Map<String, dynamic> toJson() => {
        "mobile_number": mobileNumber,
    };
}