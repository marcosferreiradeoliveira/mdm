import 'package:cloud_firestore/cloud_firestore.dart';

class Blog {
  String? title;
  String? titleEn;
  String? description;
  String? descriptionEn;
  String? thumbnailImagelUrl;
  int? loves;
  String? sourceUrl;
  String? date;
  String? timestamp;

  Blog({
    this.title,
    this.titleEn,
    this.description,
    this.descriptionEn,
    this.thumbnailImagelUrl,
    this.loves,
    this.sourceUrl,
    this.date,
    this.timestamp,
  });

  factory Blog.fromFirestore(DocumentSnapshot snapshot) {
    Map d = snapshot.data() as Map<dynamic, dynamic>;
    return Blog(
      title: d['title'],
      titleEn: d['title_en'],
      description: d['description'],
      descriptionEn: d['description_en'],
      thumbnailImagelUrl: d['image url'],
      loves: d['loves'],
      sourceUrl: d['source'],
      date: d['date'],
      timestamp: d['timestamp'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'title_en': titleEn,
      'description': description,
      'description_en': descriptionEn,
      'image url': thumbnailImagelUrl,
      'loves': loves,
      'source': sourceUrl,
      'date': date,
      'timestamp': timestamp,
    };
  }
}
