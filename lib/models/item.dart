import 'package:cloud_firestore/cloud_firestore.dart';

class Item {
  String? exposicaoId;
  String? titulo;
  String? imagem;
  String? descricao;
  String? timestamp;
  String? urlLibras;
  String? urlAudiodescricao;

  Item({
    this.exposicaoId,
    this.titulo,
    this.imagem,
    this.descricao,
    this.timestamp,
    this.urlLibras,
    this.urlAudiodescricao,
  });

  factory Item.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return Item(
      exposicaoId: data['exposicaoId'] ?? '',
      titulo: data['titulo'] ?? '',
      imagem: data['imagem'] ?? '',
      descricao: data['descricao'] ?? '',
      timestamp: data['timestamp'] ?? '',
      urlLibras: data['url_libras'] ?? '',
      urlAudiodescricao: data['url_audiodescricao'] ?? '',
    );
  }
}
