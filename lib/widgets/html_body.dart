import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../services/app_service.dart';
import 'package:firebase_storage/firebase_storage.dart';

class HtmlBodyWidget extends StatelessWidget {
  const HtmlBodyWidget({Key? key, required this.htmlDescription})
      : super(key: key);

  final String htmlDescription;

  Future<String> _getImageUrl(String imageUrl) async {
    try {
      // Se já for uma URL do Firebase Storage, usa diretamente
      if (imageUrl.contains('firebasestorage.googleapis.com')) {
        return imageUrl;
      }

      // Se for um caminho do Firebase Storage
      if (imageUrl.startsWith('gs://') ||
          (!imageUrl.startsWith('http') && !imageUrl.startsWith('https'))) {
        final ref = FirebaseStorage.instance.ref().child(imageUrl);
        // Adiciona um timestamp para evitar cache
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final downloadUrl = await ref.getDownloadURL();
        return '$downloadUrl&t=$timestamp';
      }

      // Para outras URLs
      return imageUrl;
    } catch (e) {
      print('Error getting image URL: $e');
      return imageUrl;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Html(
      data: '''$htmlDescription''',
      onLinkTap: (url, _, __) {
        AppService().openLink(context, url!);
      },
      style: {
        "body": Style(
            margin: Margins.zero,
            padding: HtmlPaddings.zero,
            fontSize: FontSize.large,
            fontWeight: FontWeight.normal,
            fontFamily: '',
            color: Colors.grey[700]),

        "figure": Style(margin: Margins.zero, padding: HtmlPaddings.zero),

        //Disable this line to disable full width picture/video support
        //"p,h1,h2,h3,h4,h5,h6": Style(margin: Margins.all(20)),
      },
      extensions: [
        TagExtension(
            tagsToExtend: {"img"},
            builder: (ExtensionContext eContext) {
              String imageUrl = eContext.attributes['src'].toString();
              return FutureBuilder<String>(
                future: _getImageUrl(imageUrl),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error, color: Colors.red, size: 20),
                          Text(
                            'Erro ao carregar imagem',
                            style: TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  }
                  return Image.network(
                    snapshot.data!,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      print('Error loading image: $error');
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error, color: Colors.red, size: 20),
                            Text(
                              'Erro ao carregar imagem',
                              style: TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            }),
        TagExtension(
            tagsToExtend: {"iframe"},
            builder: (ExtensionContext eContext) {
              final String videoSource = eContext.attributes['src'].toString();
              return InkWell(
                  onTap: () => AppService().openLink(context, videoSource),
                  child: Container(
                    color: Colors.grey.shade200,
                    height: 200,
                    width: 400,
                    child: Icon(
                      Icons.play_circle_fill,
                      color: Colors.grey,
                    ),
                  ));
            }),
        TagExtension(
            tagsToExtend: {"video"},
            builder: (ExtensionContext eContext) {
              final String videoSource = eContext.attributes['src'].toString();
              return InkWell(
                  onTap: () => AppService().openLink(context, videoSource),
                  child: Container(
                    color: Colors.grey.shade200,
                    height: 200,
                    width: 400,
                    child: Icon(
                      Icons.play_circle_fill,
                      color: Colors.grey,
                    ),
                  ));
            }),
      ],
    );
  }
}
