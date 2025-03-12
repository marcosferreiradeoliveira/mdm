import 'package:admin/blocs/admin_bloc.dart';
import 'package:admin/utils/dialog.dart';
import 'package:admin/widgets/blog_preview.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';

class UploadBlog extends StatefulWidget {
  UploadBlog({Key? key}) : super(key: key);

  @override
  _UploadBlogState createState() => _UploadBlogState();
}

class _UploadBlogState extends State<UploadBlog> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  var formKey = GlobalKey<FormState>();
  var titleCtrl = TextEditingController();
  var titleEnCtrl = TextEditingController();
  var imageUrlCtrl = TextEditingController();
  var descriptionCtrl = TextEditingController();
  var descriptionEnCtrl = TextEditingController();
  var scaffoldKey = GlobalKey<ScaffoldState>();

  bool notifyUsers = true;
  bool isUploading = false;
  String? _timestamp;
  String? _date;
  var _blogData;
  XFile? _imageFile;
  Uint8List? _webImage;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('pt_BR', null);
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
      final Reference ref = storage.ref().child('blogs/$fileName');

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

  void handleSubmit() async {
    final AdminBloc ab = Provider.of<AdminBloc>(context, listen: false);
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      if (ab.userType == 'tester') {
        openDialog(context, 'Você é um Testador',
            'Somente Admin pode fazer upload, deletar e modificar conteúdos');
      } else {
        setState(() => isUploading = true);

        String? imageUrl;
        if (_imageFile != null || _webImage != null) {
          imageUrl = await _uploadImage();
          if (imageUrl != null) {
            imageUrlCtrl.text = imageUrl;
          }
        }

        await getDate().then((_) async {
          await saveToDatabase().then((value) =>
              context.read<AdminBloc>().increaseCount('blogs_count'));
          setState(() => isUploading = false);
          openDialog(context, 'Upload realizado com sucesso', '');
          clearTextFields();
        });
      }
    }
  }

  Future getDate() async {
    DateTime now = DateTime.now();
    String _d = DateFormat('dd/MM/yyyy').format(now);
    String _t = DateFormat('yyyyMMddHHmmss').format(now);
    setState(() {
      _timestamp = _t;
      _date = _d;
    });
  }

  Future saveToDatabase() async {
    final DocumentReference ref = firestore.collection('blogs').doc(_timestamp);
    _blogData = {
      'title': titleCtrl.text,
      'title_en': titleEnCtrl.text,
      'description': descriptionCtrl.text,
      'description_en': descriptionEnCtrl.text,
      'image url': imageUrlCtrl.text,
      'loves': 0,
      'date': _date,
      'timestamp': _timestamp
    };
    await ref.set(_blogData);
  }

  clearTextFields() {
    titleCtrl.clear();
    titleEnCtrl.clear();
    descriptionCtrl.clear();
    descriptionEnCtrl.clear();
    imageUrlCtrl.clear();
    setState(() {
      _imageFile = null;
      _webImage = null;
    });
    FocusScope.of(context).unfocus();
  }

  handlePreview() async {
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      await getDate().then((_) async {
        await showBlogPreview(context, titleCtrl.text, descriptionCtrl.text,
            imageUrlCtrl.text, 0, '', 'Agora');
      });
    }
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
              SizedBox(
                height: h * 0.10,
              ),
              Text(
                'Detalhes da Atualização',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
              ),
              SizedBox(
                height: 20,
              ),
              TextFormField(
                decoration:
                    inputDecoration('Digite o Título', 'Título', titleCtrl),
                controller: titleCtrl,
                validator: (value) {
                  if (value!.isEmpty) return 'O valor está vazio';
                  return null;
                },
              ),
              SizedBox(
                height: 20,
              ),
              TextFormField(
                decoration: inputDecoration(
                    'Digite o Título em Inglês', 'Título EN', titleEnCtrl),
                controller: titleEnCtrl,
                validator: (value) {
                  if (value!.isEmpty) return 'O valor está vazio';
                  return null;
                },
              ),
              SizedBox(
                height: 20,
              ),
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
                        : imageUrlCtrl.text.isNotEmpty
                            ? Image.network(imageUrlCtrl.text,
                                fit: BoxFit.cover)
                            : Center(
                                child: Text('Nenhuma imagem selecionada'),
                              ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: Icon(Icons.image),
                        label: Text('Selecionar Imagem'),
                      ),
                      if (_imageFile != null ||
                          _webImage != null ||
                          imageUrlCtrl.text.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _imageFile = null;
                                _webImage = null;
                                imageUrlCtrl.clear();
                              });
                            },
                            icon: Icon(Icons.delete),
                            label: Text('Remover Imagem'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              SizedBox(
                height: 20,
              ),
              TextFormField(
                decoration: InputDecoration(
                  hintText: 'Digite a Descrição (Html ou Texto Normal)',
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
                          descriptionCtrl.clear();
                        },
                      ),
                    ),
                  ),
                ),
                textAlignVertical: TextAlignVertical.top,
                minLines: 5,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                controller: descriptionCtrl,
                validator: (value) {
                  if (value!.isEmpty) return 'O valor está vazio';
                  return null;
                },
              ),
              SizedBox(
                height: 20,
              ),
              TextFormField(
                decoration: InputDecoration(
                  hintText:
                      'Digite a Descrição em Inglês (Html ou Texto Normal)',
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
                          descriptionEnCtrl.clear();
                        },
                      ),
                    ),
                  ),
                ),
                textAlignVertical: TextAlignVertical.top,
                minLines: 5,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                controller: descriptionEnCtrl,
                validator: (value) {
                  if (value!.isEmpty) return 'O valor está vazio';
                  return null;
                },
              ),
              SizedBox(
                height: 100,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  TextButton.icon(
                      icon: Icon(
                        Icons.remove_red_eye,
                        size: 25,
                        color: Colors.blueAccent,
                      ),
                      label: Text(
                        'Pré-visualizar',
                        style: TextStyle(
                            fontWeight: FontWeight.w400, color: Colors.black),
                      ),
                      onPressed: () {
                        handlePreview();
                      })
                ],
              ),
              SizedBox(
                height: 10,
              ),
              Container(
                  color: Colors.deepPurpleAccent,
                  height: 45,
                  child: isUploading == true
                      ? Center(
                          child: Container(
                              height: 30,
                              width: 30,
                              child: CircularProgressIndicator()),
                        )
                      : TextButton(
                          child: Text(
                            'Criar Atualização',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600),
                          ),
                          onPressed: () async {
                            handleSubmit();
                          })),
              SizedBox(
                height: 200,
              ),
            ],
          )),
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
              }),
        ),
      ),
    );
  }
}
