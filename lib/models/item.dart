import 'package:cloud_firestore/cloud_firestore.dart';

class Item {
  String? exposicaoId;
  String? titulo;
  String? tituloEn;
  String? imagem;
  String? descricao;
  String? descricaoEn;
  String? urlLibras;
  String? urlAudiodescricao;
  String? timestamp;
  String? date;

  Item({
    this.exposicaoId,
    this.titulo,
    this.tituloEn,
    this.imagem,
    this.descricao,
    this.descricaoEn,
    this.urlLibras,
    this.urlAudiodescricao,
    this.timestamp,
    this.date,
  });

  factory Item.fromMap(Map<String, dynamic> data) {
    return Item(
      exposicaoId: data['exposicaoId'],
      titulo: data['titulo'],
      tituloEn: data['titulo_en'],
      imagem: data['imagem'],
      descricao: data['descricao'],
      descricaoEn: data['descricao_en'],
      urlLibras: data['url_libras'],
      urlAudiodescricao: data['url_audiodescricao'],
      timestamp: data['timestamp'],
      date: data['date'],
    );
  }

  factory Item.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Item(
      exposicaoId: data['exposicaoId'],
      titulo: data['titulo'],
      tituloEn: data['titulo_en'],
      imagem: data['imagem'],
      descricao: data['descricao'],
      descricaoEn: data['descricao_en'],
      urlLibras: data['url_libras'],
      urlAudiodescricao: data['url_audiodescricao'],
      timestamp: data['timestamp'],
      date: data['date'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'exposicaoId': exposicaoId,
      'titulo': titulo,
      'titulo_en': tituloEn,
      'imagem': imagem,
      'descricao': descricao,
      'descricao_en': descricaoEn,
      'url_libras': urlLibras,
      'url_audiodescricao': urlAudiodescricao,
      'timestamp': timestamp,
      'date': date,
    };
  }
}
