import 'package:admin/blocs/admin_bloc.dart';
import 'package:admin/utils/dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

class UploadItem extends StatefulWidget {
  UploadItem({Key? key}) : super(key: key);

  @override
  _UploadItemState createState() => _UploadItemState();
}

class _UploadItemState extends State<UploadItem> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  var formKey = GlobalKey<FormState>();
  var scaffoldKey = GlobalKey<ScaffoldState>();
  final String collectionName = 'Item';

  var tituloCtrl = TextEditingController();
  var tituloEnCtrl = TextEditingController();
  var descricaoCtrl = TextEditingController();
  var descricaoEnCtrl = TextEditingController();
  var imagemUrlCtrl = TextEditingController();
  var librasCtrl = TextEditingController();
  var audiodescricaoCtrl = TextEditingController();

  String? _timestamp;
  String? _date;
  String? _imageUrl;
  bool isUploading = false;
  List<DropdownMenuItem<String>> exposicoesDropdownItems = [];
  String? selectedExposicaoId;
  XFile? _imageFile;
  Uint8List? _webImage;
  XFile? _audioFile;
  bool isUploadingAudio = false;
  double _uploadProgress = 0;

  @override
  void initState() {
    super.initState();
    _loadExposicoes();
  }

  Future<void> _loadExposicoes() async {
    QuerySnapshot data = await firestore.collection('exposições').get();
    List<DropdownMenuItem<String>> items = data.docs.map((doc) {
      return DropdownMenuItem<String>(
        value: doc.id,
        child: Text(doc['name']),
      );
    }).toList();

    setState(() {
      exposicoesDropdownItems = items;
    });
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        if (kIsWeb) {
          var bytes = await pickedFile.readAsBytes();
          setState(() {
            _webImage = bytes;
            _imageFile = pickedFile;
          });
        } else {
          setState(() {
            _imageFile = pickedFile;
          });
        }
      }
    } catch (e) {
      print('Erro ao selecionar imagem: $e');
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null && _webImage == null) return null;

    try {
      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${_imageFile!.name}';
      final Reference ref = storage.ref().child('items/$fileName');

      UploadTask uploadTask;
      if (kIsWeb) {
        uploadTask = ref.putData(_webImage!);
      } else {
        uploadTask = ref.putFile(File(_imageFile!.path));
      }

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Erro ao fazer upload da imagem: $e');
      return null;
    }
  }

  Future<void> _pickAudioFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3'],
        allowMultiple: false,
      );

      if (result != null) {
        PlatformFile file = result.files.first;

        if (file.size > 20 * 1024 * 1024) {
          // 20MB limit
          throw Exception('O arquivo é muito grande. O tamanho máximo é 20MB.');
        }

        if (kIsWeb) {
          setState(() {
            _audioFile = XFile.fromData(
              result.files.first.bytes!,
              name: result.files.first.name,
            );
          });
        } else {
          setState(() {
            _audioFile = XFile(result.files.single.path!);
          });
        }
      }
    } catch (e) {
      print('Erro ao selecionar arquivo de áudio: $e');
      openDialog(context, 'Erro', e.toString());
    }
  }

  Future<String?> _uploadAudioFile() async {
    if (_audioFile == null) return null;

    try {
      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${_audioFile!.name}';
      final Reference ref = storage.ref().child('audiodescricao/$fileName');

      UploadTask uploadTask;
      if (kIsWeb) {
        final bytes = await _audioFile!.readAsBytes();
        uploadTask = ref.putData(
          bytes,
          SettableMetadata(
            contentType: 'audio/mpeg',
            customMetadata: {
              'fileName': _audioFile!.name,
              'uploadedAt': DateTime.now().toString(),
            },
          ),
        );
      } else {
        uploadTask = ref.putFile(
          File(_audioFile!.path),
          SettableMetadata(
            contentType: 'audio/mpeg',
            customMetadata: {
              'fileName': _audioFile!.name,
              'uploadedAt': DateTime.now().toString(),
            },
          ),
        );
      }

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        setState(() {
          _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
        });
      });

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Erro ao fazer upload do arquivo de áudio: $e');
      return null;
    }
  }

  clearFields() {
    tituloCtrl.clear();
    tituloEnCtrl.clear();
    descricaoCtrl.clear();
    descricaoEnCtrl.clear();
    imagemUrlCtrl.clear();
    librasCtrl.clear();
    audiodescricaoCtrl.clear();
    selectedExposicaoId = null;
    setState(() {
      _imageFile = null;
      _webImage = null;
      _audioFile = null;
      _uploadProgress = 0;
    });
    FocusScope.of(context).unfocus();
  }

  void handleSubmit() async {
    final AdminBloc ab = Provider.of<AdminBloc>(context, listen: false);

    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      if (ab.userType == 'tester') {
        openDialog(context, 'Você é um testador',
            'Só admins podem adicionar conteúdo');
      } else {
        setState(() => isUploading = true);

        String? imageUrl;
        if (_imageFile != null || _webImage != null) {
          imageUrl = await _uploadImage();
          if (imageUrl != null) {
            imagemUrlCtrl.text = imageUrl;
          }
        }

        String? audioUrl;
        if (_audioFile != null) {
          setState(() => isUploadingAudio = true);
          audioUrl = await _uploadAudioFile();
          if (audioUrl != null) {
            audiodescricaoCtrl.text = audioUrl;
          }
          setState(() => isUploadingAudio = false);
        }

        await getDate().then((_) async {
          await saveToDatabase().then(
              (value) => context.read<AdminBloc>().increaseCount('item_count'));
          setState(() {
            isUploading = false;
            isUploadingAudio = false;
          });
          openDialog(context, 'Upload realizado com sucesso', '');
          clearFields();
        });
      }
    }
  }

  Future getDate() async {
    DateTime now = DateTime.now();
    String _d = DateFormat('dd MMMM yy').format(now);
    String _t = DateFormat('yyyyMMddHHmmss').format(now);
    setState(() {
      _timestamp = _t;
      _date = _d;
    });
  }

  Future saveToDatabase() async {
    final DocumentReference ref =
        firestore.collection(collectionName).doc(_timestamp);

    var _itemData = {
      'exposicaoId': selectedExposicaoId,
      'titulo': tituloCtrl.text,
      'titulo_en': tituloEnCtrl.text,
      'imagem': imagemUrlCtrl.text,
      'descricao': descricaoCtrl.text,
      'descricao_en': descricaoEnCtrl.text,
      'url_libras': librasCtrl.text,
      'url_audiodescricao': audiodescricaoCtrl.text,
      'timestamp': _timestamp,
      'date': _date,
    };

    await ref.set(_itemData);
  }

  @override
  Widget build(BuildContext context) {
    double h = MediaQuery.of(context).size.height;
    return Scaffold(
      key: scaffoldKey,
      body: Form(
        key: formKey,
        child: ListView(
          controller: ScrollController(),
          children: <Widget>[
            SizedBox(height: h * 0.10),
            Text(
              'Detalhes do Item',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 20),
            exposicoesDropdown(),
            SizedBox(height: 20),
            TextFormField(
              decoration:
                  inputDecoration('Título do Item', 'Título', tituloCtrl),
              controller: tituloCtrl,
              validator: (value) {
                if (value!.isEmpty) return 'Campo está vazio';
                return null;
              },
            ),
            SizedBox(height: 20),
            TextFormField(
              decoration: inputDecoration(
                  'Título do Item em Inglês', 'Título EN', tituloEnCtrl),
              controller: tituloEnCtrl,
              validator: (value) {
                if (value!.isEmpty) return 'Campo está vazio';
                return null;
              },
            ),
            SizedBox(height: 20),
            // Campo de imagem com preview
            Column(
              children: [
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _imageFile != null || _webImage != null
                      ? kIsWeb
                          ? Image.memory(_webImage!, fit: BoxFit.cover)
                          : Image.file(File(_imageFile!.path),
                              fit: BoxFit.cover)
                      : Center(
                          child: Text('Nenhuma imagem selecionada'),
                        ),
                ),
                SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: Icon(Icons.image),
                  label: Text('Selecionar Imagem'),
                ),
              ],
            ),
            SizedBox(height: 20),
            TextFormField(
              decoration: InputDecoration(
                hintText: 'Descrição do Item',
                border: OutlineInputBorder(),
                labelText: 'Descrição',
                contentPadding:
                    EdgeInsets.only(right: 0, left: 10, top: 15, bottom: 5),
                suffixIcon: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    radius: 15,
                    backgroundColor: Colors.grey[300],
                    child: IconButton(
                      icon: Icon(Icons.close, size: 15),
                      onPressed: () {
                        descricaoCtrl.clear();
                      },
                    ),
                  ),
                ),
              ),
              textAlignVertical: TextAlignVertical.top,
              minLines: 5,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              controller: descricaoCtrl,
              validator: (value) {
                if (value!.isEmpty) return 'Campo está vazio';
                return null;
              },
            ),
            SizedBox(height: 20),
            TextFormField(
              decoration: InputDecoration(
                hintText: 'Descrição do Item em Inglês',
                border: OutlineInputBorder(),
                labelText: 'Descrição EN',
                contentPadding:
                    EdgeInsets.only(right: 0, left: 10, top: 15, bottom: 5),
                suffixIcon: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    radius: 15,
                    backgroundColor: Colors.grey[300],
                    child: IconButton(
                      icon: Icon(Icons.close, size: 15),
                      onPressed: () {
                        descricaoEnCtrl.clear();
                      },
                    ),
                  ),
                ),
              ),
              textAlignVertical: TextAlignVertical.top,
              minLines: 5,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              controller: descricaoEnCtrl,
              validator: (value) {
                if (value!.isEmpty) return 'Campo está vazio';
                return null;
              },
            ),
            SizedBox(height: 20),
            TextFormField(
              decoration:
                  inputDecoration('URL de Libras', 'Libras', librasCtrl),
              controller: librasCtrl,
              validator: (value) {
                return null;
              },
            ),
            SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Audiodescrição (MP3)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 10),
                Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (audiodescricaoCtrl.text.isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(Icons.audiotrack,
                                color: Colors.deepPurpleAccent),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Arquivo de áudio atual',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    audiodescricaoCtrl.text.split('/').last,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  audiodescricaoCtrl.clear();
                                  _audioFile = null;
                                });
                              },
                            ),
                          ],
                        ),
                      ] else
                        Text(
                          'Nenhum arquivo de áudio selecionado',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      if (isUploadingAudio) ...[
                        SizedBox(height: 10),
                        Column(
                          children: [
                            LinearProgressIndicator(
                              value: _uploadProgress,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.deepPurpleAccent,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Enviando: ${(_uploadProgress * 100).toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isUploadingAudio
                        ? null
                        : () async {
                            await _pickAudioFile();
                            if (_audioFile != null) {
                              setState(() {
                                isUploadingAudio = true;
                                _uploadProgress = 0;
                              });

                              String? audioUrl = await _uploadAudioFile();

                              if (audioUrl != null) {
                                setState(() {
                                  audiodescricaoCtrl.text = audioUrl;
                                  isUploadingAudio = false;
                                  _audioFile = null;
                                  _uploadProgress = 0;
                                });
                              } else {
                                setState(() {
                                  isUploadingAudio = false;
                                  _uploadProgress = 0;
                                });
                                openDialog(context, 'Erro',
                                    'Falha ao fazer upload do arquivo de áudio');
                              }
                            }
                          },
                    icon: Icon(isUploadingAudio
                        ? Icons.hourglass_empty
                        : Icons.upload_file),
                    label: Text(isUploadingAudio
                        ? 'Enviando...'
                        : audiodescricaoCtrl.text.isNotEmpty
                            ? 'Alterar Arquivo de Áudio'
                            : 'Selecionar Arquivo de Áudio'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.deepPurpleAccent,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[300],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 50),
            Container(
              color: Colors.deepPurpleAccent,
              height: 45,
              child: isUploading
                  ? Center(
                      child: Container(
                        height: 30,
                        width: 30,
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    )
                  : TextButton(
                      child: Text(
                        'Cadastrar Item',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: handleSubmit,
                    ),
            ),
            SizedBox(height: 200),
          ],
        ),
      ),
    );
  }

  Widget exposicoesDropdown() {
    return Container(
      height: 50,
      padding: EdgeInsets.only(left: 15, right: 15),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(30),
      ),
      child: DropdownButtonFormField<String>(
        itemHeight: 50,
        decoration: InputDecoration(border: InputBorder.none),
        onChanged: (value) {
          setState(() {
            selectedExposicaoId = value;
          });
        },
        value: selectedExposicaoId,
        hint: Text('Selecione exposição'),
        items: exposicoesDropdownItems,
        validator: (value) {
          if (value == null) return 'Por favor, selecione uma exposição';
          return null;
        },
      ),
    );
  }

  InputDecoration inputDecoration(
      String hint, String label, TextEditingController controller) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(),
      labelText: label,
      contentPadding: EdgeInsets.only(right: 0, left: 10, top: 15, bottom: 5),
      suffixIcon: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          radius: 15,
          backgroundColor: Colors.grey[300],
          child: IconButton(
            icon: Icon(Icons.close, size: 15),
            onPressed: () {
              controller.clear();
            },
          ),
        ),
      ),
    );
  }
}
