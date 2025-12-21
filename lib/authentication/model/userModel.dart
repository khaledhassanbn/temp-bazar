// lib/authentication/model/userModel.dart

class UserModel {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;

  UserModel({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
  });

  /// لحفظ في Firestore / تحويل لكائن JSON
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
    };
  }

  /// alias لو في كود يستدعي toMap
  Map<String, dynamic> toMap() => toJson();

  /// إنشاء كائن من خريطة (Map) مرجعة من Firestore
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: (json['uid'] ?? json['id'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      firstName: (json['firstName'] ?? json['first_name'] ?? '') as String,
      lastName: (json['lastName'] ?? json['last_name'] ?? '') as String,
    );
  }

  /// alias لو في كود قديم بيستدعي fromMap
  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel.fromJson(map);
}
