import 'dart:io';
import 'package:admin/blocs/admin_bloc.dart';
import 'package:admin/utils/dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class UploadItem extends StatefulWidget {
  UploadItem({Key? key}) : super(key: key);

  @override
  _UploadItemState createState() => _UploadItemState();
}

class _UploadItemState extends State<UploadItem> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;

  var formKey = GlobalKey<FormState>();
  var scaffoldKey = GlobalKey<ScaffoldState>();
  final String collectionName = 'Item';

  var tituloCtrl = TextEditingController();
  var descricaoCtrl = TextEditingController();
  var librasCtrl = TextEditingController();
  var audiodescricaoCtrl = TextEditingController();

  String? _timestamp;
  String? _date;
  String? _imageUrl;
  List<DropdownMenuItem<String>> exposicoesDropdownItems = [];
  String? selectedExposicaoId;
  File? _imageFile;

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

  clearFields() {
    tituloCtrl.clear();
    descricaoCtrl.clear();
    librasCtrl.clear();
    audiodescricaoCtrl.clear();
    selectedExposicaoId = null;
    _imageFile = null;
    _imageUrl = null;
    FocusScope.of(context).unfocus();
  }

  bool uploadStarted = false;

  void handleSubmit() async {
    final AdminBloc ab = Provider.of<AdminBloc>(context, listen: false);

    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      if (ab.userType == 'tester') {
        openDialog(context, 'Você é um testador',
            'Só admins podem adicionar conteúdo');
      } else {
        setState(() => uploadStarted = true);
        await getDate().then((_) async {
          if (_imageFile != null) {
            await uploadImageToStorage();
          }
          await saveToDatabase().then(
              (value) => context.read<AdminBloc>().increaseCount('item_count'));
          setState(() => uploadStarted = false);
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

  Future uploadImageToStorage() async {
    final ref = storage.ref().child('items').child('$_timestamp.jpg');
    await ref.putFile(_imageFile!);
    _imageUrl = await ref.getDownloadURL();
  }

  Future saveToDatabase() async {
    final DocumentReference ref =
        firestore.collection(collectionName).doc(_timestamp);

    var _itemData = {
      'exposicaoId': selectedExposicaoId,
      'titulo': tituloCtrl.text,
      'imagem': _imageUrl,
      'descricao': descricaoCtrl.text,
      'url_libras': librasCtrl.text,
      'url_audiodescricao': audiodescricaoCtrl.text,
      'timestamp': _timestamp,
      'date': _date,
    };

    await ref.set(_itemData);
  }

  Future pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    setState(() {
      if (pickedFile != null) {
        _imageFile = File(pickedFile.path);
      }
    });
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
                'Detalhes do Item',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
              ),
              SizedBox(
                height: 20,
              ),
              exposicoesDropdown(),
              SizedBox(
                height: 20,
              ),
              TextFormField(
                decoration:
                    inputDecoration('Título do Item', 'Título', tituloCtrl),
                controller: tituloCtrl,
                validator: (value) {
                  if (value!.isEmpty) return 'Campo está vazio';
                  return null;
                },
              ),
              SizedBox(
                height: 20,
              ),
              GestureDetector(
                onTap: pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _imageFile == null
                      ? Center(child: Text('Selecionar Imagem'))
                      : Image.file(_imageFile!, fit: BoxFit.cover),
                ),
              ),
              SizedBox(
                height: 20,
              ),
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
                            }),
                      ),
                    )),
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
              SizedBox(
                height: 20,
              ),
              TextFormField(
                decoration:
                    inputDecoration('URL de Libras', 'Libras', librasCtrl),
                controller: librasCtrl,
                validator: (value) {
                  return null;
                },
              ),
              SizedBox(
                height: 20,
              ),
              TextFormField(
                decoration: inputDecoration('URL de Audiodescrição',
                    'Audiodescrição', audiodescricaoCtrl),
                controller: audiodescricaoCtrl,
                validator: (value) {
                  return null;
                },
              ),
              SizedBox(
                height: 50,
              ),
              Container(
                  color: Colors.deepPurpleAccent,
                  height: 45,
                  child: uploadStarted == true
                      ? Center(
                          child: Container(
                              height: 30,
                              width: 30,
                              child: CircularProgressIndicator()),
                        )
                      : TextButton(
                          child: Text(
                            'Cadastrar Item',
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

  Widget exposicoesDropdown() {
    return Container(
        height: 50,
        padding: EdgeInsets.only(left: 15, right: 15),
        decoration: BoxDecoration(
            color: Colors.grey[200],
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(30)),
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
            items: exposicoesDropdownItems));
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
