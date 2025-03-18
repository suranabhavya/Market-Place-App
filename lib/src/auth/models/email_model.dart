import 'dart:convert';

// Simplified functions for JSON conversion
String emailModelToJson(EmailModel data) => json.encode({'email': data.email});

class EmailModel {
  final String email;

  // Use const constructor for immutability
  const EmailModel({required this.email});
  
  // Factory constructor from JSON
  factory EmailModel.fromJson(Map<String, dynamic> json) => EmailModel(
    email: json["email"],
  );
  
  // Simple toJson method
  Map<String, dynamic> toJson() => {'email': email};
}