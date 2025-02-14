import 'package:cloud_firestore/cloud_firestore.dart';

class StateModel {
  String? name;
  String? thumbnailUrl;
  String? descricao;
  String? timestamp;
  String? curador;
  String? subtitulo;
  DateTime? dataInicio;
  DateTime? dataFim;

  StateModel({
    this.name,
    this.thumbnailUrl,
    this.descricao,
    this.timestamp,
    this.curador,
    this.subtitulo,
    this.dataInicio,
    this.dataFim,
  });

  factory StateModel.fromFirestore(DocumentSnapshot snapshot) {
    Map<String, dynamic> d = snapshot.data() as Map<String, dynamic>;
    return StateModel(
      name: d['name'],
      thumbnailUrl: d['thumbnail'],
      descricao: d['descricao'],
      timestamp: d['timestamp'],
      curador: d['curador'],
      subtitulo: d['subtitulo'],
      dataInicio: (d['data_inicio'] != null)
          ? (d['data_inicio'] as Timestamp).toDate()
          : null,
      dataFim: (d['data_fim'] != null)
          ? (d['data_fim'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'thumbnail': thumbnailUrl,
      'descricao': descricao,
      'timestamp': timestamp,
      'curador': curador,
      'subtitulo': subtitulo,
      'data_inicio': dataInicio,
      'data_fim': dataFim,
    };
  }
}
