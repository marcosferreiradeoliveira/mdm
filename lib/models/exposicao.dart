import 'package:cloud_firestore/cloud_firestore.dart';

class StateModel {
  String? name;
  String? nameEn;
  String? thumbnailUrl;
  String? descricao;
  String? descricaoEn;
  String? timestamp;
  String? curador;
  String? curadorEn;
  String? subtitulo;
  String? subtituloEn;
  String? urlLibras;
  String? urlAudiodescricao;
  DateTime? dataInicio;
  DateTime? dataFim;

  StateModel({
    this.name,
    this.nameEn,
    this.thumbnailUrl,
    this.descricao,
    this.descricaoEn,
    this.timestamp,
    this.curador,
    this.curadorEn,
    this.subtitulo,
    this.subtituloEn,
    this.urlLibras,
    this.urlAudiodescricao,
    this.dataInicio,
    this.dataFim,
  });

  factory StateModel.fromFirestore(DocumentSnapshot snapshot) {
    Map<String, dynamic> d = snapshot.data() as Map<String, dynamic>;
    return StateModel(
      name: d['name'],
      nameEn: d['name_en'],
      thumbnailUrl: d['thumbnail'],
      descricao: d['descricao'],
      descricaoEn: d['descricao_en'],
      timestamp: d['timestamp'],
      curador: d['curador'],
      curadorEn: d['curador_en'],
      subtitulo: d['subtitulo'],
      subtituloEn: d['subtitulo_en'],
      urlLibras: d['url_libras'],
      urlAudiodescricao: d['url_audiodescricao'],
      dataInicio: (d['data_inicio'] != null)
          ? (d['data_inicio'] as Timestamp).toDate()
          : null,
      dataFim: (d['data_fim'] != null)
          ? (d['data_fim'] as Timestamp).toDate()
          : null,
    );
  }
}
