import 'package:cloud_firestore/cloud_firestore.dart';

class Item {
  String? exposicaoId;
  String? titulo;
  String? imagem;
  String? descricao;
  String? timestamp;

  Item({
    this.exposicaoId,
    this.titulo,
    this.imagem,
    this.descricao,
    this.timestamp,
  });

  factory Item.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return Item(
      exposicaoId: data['exposicaoId'] ?? '',
      titulo: data['titulo'] ?? '',
      imagem: data['imagem'] ?? '',
      descricao: data['descricao'] ?? '',
      timestamp: data['timestamp'] ?? '',
    );
  }
}
