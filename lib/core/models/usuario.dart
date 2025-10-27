import 'package:cloud_firestore/cloud_firestore.dart';

class Usuario {
  final String id;
  final String? fcmToken;

  Usuario({required this.id, this.fcmToken});

  factory Usuario.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Usuario(id: doc.id, fcmToken: data['fcmToken']);
  }

  Map<String, dynamic> toFirestore() {
    return {if (fcmToken != null) 'fcmToken': fcmToken};
  }
}
