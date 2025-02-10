import 'package:cloud_firestore/cloud_firestore.dart';

class StateModel {
  String? name;
  String? thumbnailUrl;
  String? descricao;
  String? timestamp;

  StateModel({this.name, this.thumbnailUrl, this.descricao, this.timestamp});

  factory StateModel.fromFirestore(DocumentSnapshot snapshot) {
    Map d = snapshot.data() as Map<dynamic, dynamic>;
    return StateModel(
      name: d['name'],
      thumbnailUrl: d['thumbnail'],
      descricao: d['descricao'],
      timestamp: d['timestamp'],
    );
  }
}
