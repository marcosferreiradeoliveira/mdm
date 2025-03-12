import 'package:admin/blocs/admin_bloc.dart';
import 'package:admin/models/item.dart';
import 'package:admin/utils/dialog.dart';
import 'package:admin/widgets/cover_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';

class UpdateItem extends StatefulWidget {
  final Item itemData;
  UpdateItem({Key? key, required this.itemData}) : super(key: key);

  @override
  _UpdateItemState createState() => _UpdateItemState();
}

class _UpdateItemState extends State<UpdateItem> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  var formKey = GlobalKey<FormState>();
  var scaffoldKey = GlobalKey<ScaffoldState>();
  final String collectionName = 'Item';

  var exposicaoCtrl = TextEditingController();
  var tituloCtrl = TextEditingController();
  var imagemCtrl = TextEditingController();
  var descricaoCtrl = TextEditingController();
  var librasCtrl = TextEditingController();
  var audiodescricaoCtrl = TextEditingController();

  bool isUploading = false;
  XFile? _imageFile;
  Uint8List? _webImage;

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

  void _showUploadModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Selecionar Imagem',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    if (imagemCtrl.text.isNotEmpty) ...[
                      Text(
                        'Imagem atual:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Image.network(
                          imagemCtrl.text,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                                child: Text('Erro ao carregar imagem'));
                          },
                        ),
                      ),
                      SizedBox(height: 20),
                    ],
                    if (_imageFile != null || _webImage != null) ...[
                      Text(
                        'Nova imagem:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: kIsWeb
                            ? Image.memory(_webImage!, fit: BoxFit.cover)
                            : Image.file(File(_imageFile!.path),
                                fit: BoxFit.cover),
                      ),
                      SizedBox(height: 20),
                    ],
                    if (!isUploading)
                      ElevatedButton.icon(
                        onPressed: () async {
                          await _pickImage();
                          setModalState(() {});
                        },
                        icon: Icon(Icons.photo_library),
                        label: Text(
                          _imageFile != null || _webImage != null
                              ? 'Trocar Imagem'
                              : 'Selecionar Imagem',
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    if (isUploading) ...[
                      Center(child: CircularProgressIndicator()),
                      SizedBox(height: 10),
                      Center(child: Text('Fazendo upload...')),
                    ],
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: isUploading
                              ? null
                              : () {
                                  Navigator.of(context).pop();
                                  setState(() {
                                    _imageFile = null;
                                    _webImage = null;
                                  });
                                },
                          child: Text('Cancelar'),
                        ),
                        SizedBox(width: 10),
                        if (_imageFile != null || _webImage != null)
                          ElevatedButton(
                            onPressed: isUploading
                                ? null
                                : () async {
                                    setModalState(() {
                                      isUploading = true;
                                    });

                                    String? imageUrl = await _uploadImage();

                                    if (imageUrl != null) {
                                      setState(() {
                                        imagemCtrl.text = imageUrl;
                                      });
                                      Navigator.of(context).pop();
                                      openDialog(
                                        context,
                                        'Sucesso',
                                        'Imagem atualizada com sucesso!',
                                      );
                                    } else {
                                      openDialog(
                                        context,
                                        'Erro',
                                        'Falha ao fazer upload da imagem',
                                      );
                                    }

                                    setModalState(() {
                                      isUploading = false;
                                    });
                                    setState(() {
                                      _imageFile = null;
                                      _webImage = null;
                                    });
                                  },
                            child: Text('Confirmar'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  clearFields() {
    exposicaoCtrl.clear();
    tituloCtrl.clear();
    imagemCtrl.clear();
    descricaoCtrl.clear();
    librasCtrl.clear();
    audiodescricaoCtrl.clear();
    setState(() {
      _imageFile = null;
      _webImage = null;
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
        await saveToDatabase();
        setState(() => isUploading = false);
        openDialog(context, 'Atualizado com sucesso', '');
        clearFields();
      }
    }
  }

  Future saveToDatabase() async {
    final DocumentReference ref =
        firestore.collection(collectionName).doc(widget.itemData.timestamp);

    var _itemData = {
      'exposicaoId': exposicaoCtrl.text,
      'titulo': tituloCtrl.text,
      'imagem': imagemCtrl.text,
      'descricao': descricaoCtrl.text,
      'url_libras': librasCtrl.text,
      'url_audiodescricao': audiodescricaoCtrl.text,
    };

    await ref.update(_itemData);
  }

  initData() {
    exposicaoCtrl.text = widget.itemData.exposicaoId!;
    tituloCtrl.text = widget.itemData.titulo!;
    imagemCtrl.text = widget.itemData.imagem!;
    descricaoCtrl.text = widget.itemData.descricao!;
    librasCtrl.text = widget.itemData.urlLibras ?? '';
    audiodescricaoCtrl.text = widget.itemData.urlAudiodescricao ?? '';
  }

  @override
  void initState() {
    super.initState();
    initData();
  }

  @override
  Widget build(BuildContext context) {
    double h = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(),
      backgroundColor: Colors.grey[200],
      key: scaffoldKey,
      body: CoverWidget(
        widget: Form(
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
              TextFormField(
                decoration: inputDecoration(
                    'ID da Exposição', 'Exposição', exposicaoCtrl),
                controller: exposicaoCtrl,
                validator: (value) {
                  if (value!.isEmpty) return 'Campo vazio';
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                decoration:
                    inputDecoration('Título do Item', 'Título', tituloCtrl),
                controller: tituloCtrl,
                validator: (value) {
                  if (value!.isEmpty) return 'Campo vazio';
                  return null;
                },
              ),
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Imagem do Item',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 10),
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: imagemCtrl.text.isNotEmpty
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    imagemCtrl.text,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.error,
                                                color: Colors.red),
                                            SizedBox(height: 10),
                                            Text('Erro ao carregar imagem'),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: IconButton(
                                      icon: Icon(Icons.close,
                                          color: Colors.white),
                                      onPressed: () {
                                        setState(() {
                                          imagemCtrl.clear();
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image_outlined,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'Nenhuma imagem selecionada',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                    SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _showUploadModal,
                        icon: Icon(Icons.photo_camera),
                        label: Text(imagemCtrl.text.isNotEmpty
                            ? 'Alterar Imagem'
                            : 'Selecionar Imagem'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: Colors.deepPurpleAccent,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
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
                  if (value!.isEmpty) return 'Campo vazio';
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
              TextFormField(
                decoration: inputDecoration('URL de Audiodescrição',
                    'Audiodescrição', audiodescricaoCtrl),
                controller: audiodescricaoCtrl,
                validator: (value) {
                  return null;
                },
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
                          'Atualizar Item',
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
