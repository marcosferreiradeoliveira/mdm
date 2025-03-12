import 'package:admin/blocs/admin_bloc.dart';
import 'package:admin/models/exposicao.dart';
import 'package:admin/utils/dialog.dart';
import 'package:admin/utils/empty.dart';
import 'package:admin/utils/styles.dart';
import 'package:admin/utils/toast.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';

class ExposicoesPage extends StatefulWidget {
  const ExposicoesPage({Key? key}) : super(key: key);

  @override
  _ExposicoesPageState createState() => _ExposicoesPageState();
}

class _ExposicoesPageState extends State<ExposicoesPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  ScrollController? controller;
  DocumentSnapshot? _lastVisible;
  late bool _isLoading;
  List<DocumentSnapshot> _snap = [];
  List<StateModel> _data = [];
  final scaffoldKey = GlobalKey<ScaffoldState>();
  String collectionName = 'exposições';

  late bool _descending;
  late String _orderBy;
  String? _sortByText;
  bool? _hasData;
  var formKey = GlobalKey<FormState>();
  var nameCtrl = TextEditingController();
  var thumbnailCtrl = TextEditingController();
  var descricaoCtrl = TextEditingController();
  var curadorCtrl = TextEditingController();
  var subtituloCtrl = TextEditingController();
  var librasCtrl = TextEditingController();
  var audiodescricaoCtrl = TextEditingController();
  var nameEnCtrl = TextEditingController();
  var descricaoEnCtrl = TextEditingController();
  var subtituloEnCtrl = TextEditingController();
  DateTime? dataInicio;
  DateTime? dataFim;
  String? timestamp;

  bool isUploading = false;
  XFile? _imageFile;
  Uint8List? _webImage;

  @override
  void initState() {
    controller = ScrollController()..addListener(_scrollListener);
    super.initState();
    _isLoading = true;
    _getData();
  }

  void _scrollListener() {
    if (!_isLoading &&
        controller!.position.pixels == controller!.position.maxScrollExtent) {
      setState(() => _isLoading = true);
      _getData();
    }
  }

  void handleDelete(String timestamp) {
    final AdminBloc ab = Provider.of<AdminBloc>(context, listen: false);
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            contentPadding: EdgeInsets.all(50),
            elevation: 0,
            children: <Widget>[
              Text('Apagar?',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.w900)),
              SizedBox(height: 10),
              Text('Você quer apagar?',
                  style: TextStyle(
                      color: Colors.grey[900],
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              SizedBox(height: 30),
              Center(
                  child: Row(
                children: <Widget>[
                  TextButton(
                    style: buttonStyle(Colors.redAccent),
                    child: Text('Sim',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    onPressed: () async {
                      if (ab.userType == 'tester') {
                        Navigator.pop(context);
                        openDialog(context, 'Você é um testador',
                            'Só admins podem deletar conteúdo');
                      } else {
                        await ab
                            .deleteContent(timestamp, collectionName)
                            .then((value) => ab.getStates())
                            .then((value) => ab.decreaseCount('states_count'))
                            .then((value) =>
                                openToast(context, 'Apagado com sucesso'));
                        refreshData();
                        Navigator.pop(context);
                      }
                    },
                  ),
                  SizedBox(width: 10),
                  TextButton(
                    style: buttonStyle(Colors.deepPurpleAccent),
                    child: Text('Não',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ))
            ],
          );
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
      final Reference ref = storage.ref().child('exposicoes/$fileName');

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

  void openEditDialog(StateModel exposicao) {
    nameCtrl.text = exposicao.name ?? '';
    thumbnailCtrl.text = exposicao.thumbnailUrl ?? '';
    descricaoCtrl.text = exposicao.descricao ?? '';
    curadorCtrl.text = exposicao.curador ?? '';
    subtituloCtrl.text = exposicao.subtitulo ?? '';
    librasCtrl.text = exposicao.urlLibras ?? '';
    audiodescricaoCtrl.text = exposicao.urlAudiodescricao ?? '';
    nameEnCtrl.text = exposicao.nameEn ?? '';
    descricaoEnCtrl.text = exposicao.descricaoEn ?? '';
    subtituloEnCtrl.text = exposicao.subtituloEn ?? '';
    dataInicio = exposicao.dataInicio;
    dataFim = exposicao.dataFim;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SimpleDialog(
              contentPadding: EdgeInsets.all(20),
              children: <Widget>[
                Text('Editar Exposição',
                    style:
                        TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
                SizedBox(height: 20),
                Form(
                  key: formKey,
                  child: Column(
                    children: <Widget>[
                      TextFormField(
                        controller: nameCtrl,
                        decoration:
                            InputDecoration(labelText: 'Nome da Exposição'),
                      ),
                      SizedBox(height: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Imagem da Exposição',
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
                            child: thumbnailCtrl.text.isNotEmpty
                                ? Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          thumbnailCtrl.text,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Center(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.error,
                                                      color: Colors.red),
                                                  SizedBox(height: 10),
                                                  Text(
                                                      'Erro ao carregar imagem'),
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
                                            color:
                                                Colors.black.withOpacity(0.5),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: IconButton(
                                            icon: Icon(Icons.close,
                                                color: Colors.white),
                                            onPressed: () {
                                              setModalState(() {
                                                thumbnailCtrl.clear();
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                              onPressed: () async {
                                await _pickImage();
                                if (_imageFile != null || _webImage != null) {
                                  setModalState(() {
                                    isUploading = true;
                                  });

                                  String? imageUrl = await _uploadImage();

                                  if (imageUrl != null) {
                                    setModalState(() {
                                      thumbnailCtrl.text = imageUrl;
                                      isUploading = false;
                                      _imageFile = null;
                                      _webImage = null;
                                    });
                                  } else {
                                    setModalState(() {
                                      isUploading = false;
                                    });
                                    openDialog(context, 'Erro',
                                        'Falha ao fazer upload da imagem');
                                  }
                                }
                              },
                              icon: Icon(Icons.photo_camera),
                              label: Text(thumbnailCtrl.text.isNotEmpty
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
                      SizedBox(height: 20),
                      TextFormField(
                        controller: descricaoCtrl,
                        decoration: InputDecoration(
                            labelText: 'Descrição da Exposição'),
                        maxLines: 5,
                      ),
                      TextFormField(
                        controller: curadorCtrl,
                        decoration: InputDecoration(labelText: 'Curador'),
                      ),
                      TextFormField(
                        controller: subtituloCtrl,
                        decoration: InputDecoration(
                            labelText: 'Subtítulo da Exposição'),
                      ),
                      TextFormField(
                        controller: librasCtrl,
                        decoration: InputDecoration(labelText: 'URL de Libras'),
                      ),
                      TextFormField(
                        controller: audiodescricaoCtrl,
                        decoration:
                            InputDecoration(labelText: 'URL de Audiodescrição'),
                      ),
                      TextFormField(
                        controller: nameEnCtrl,
                        decoration:
                            InputDecoration(labelText: 'Título em Inglês'),
                      ),
                      TextFormField(
                        controller: descricaoEnCtrl,
                        decoration:
                            InputDecoration(labelText: 'Descrição em Inglês'),
                        maxLines: 5,
                      ),
                      TextFormField(
                        controller: subtituloEnCtrl,
                        decoration:
                            InputDecoration(labelText: 'Subtítulo em Inglês'),
                      ),
                      ListTile(
                        title: Text(dataInicio == null
                            ? 'Selecionar Data de Início'
                            : DateFormat('dd/MM/yyyy').format(dataInicio!)),
                        trailing: Icon(Icons.calendar_today),
                        onTap: () async {
                          DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: dataInicio ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100));
                          if (picked != null) {
                            setState(() {
                              dataInicio = picked;
                            });
                          }
                        },
                      ),
                      ListTile(
                        title: Text(dataFim == null
                            ? 'Selecionar Data de Fim'
                            : DateFormat('dd/MM/yyyy').format(dataFim!)),
                        trailing: Icon(Icons.calendar_today),
                        onTap: () async {
                          DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: dataFim ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100));
                          if (picked != null) {
                            setState(() {
                              dataFim = picked;
                            });
                          }
                        },
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            style: buttonStyle(Colors.deepPurpleAccent),
                            child: Text('Salvar',
                                style: TextStyle(color: Colors.white)),
                            onPressed: () async {
                              await firestore
                                  .collection(collectionName)
                                  .doc(exposicao.timestamp)
                                  .update({
                                'name': nameCtrl.text,
                                'thumbnail': thumbnailCtrl.text,
                                'descricao': descricaoCtrl.text,
                                'curador': curadorCtrl.text,
                                'subtitulo': subtituloCtrl.text,
                                'url_libras': librasCtrl.text,
                                'url_audiodescricao': audiodescricaoCtrl.text,
                                'titulo_en': nameEnCtrl.text,
                                'descricao_en': descricaoEnCtrl.text,
                                'subtitulo_en': subtituloEnCtrl.text,
                                'data_inicio': dataInicio,
                                'data_fim': dataFim,
                              });
                              refreshData();
                              Navigator.pop(context);
                            },
                          ),
                          TextButton(
                            style: buttonStyle(Colors.redAccent),
                            child: Text('Cancelar',
                                style: TextStyle(color: Colors.white)),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void openAddDialog() {
    clearFields();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SimpleDialog(
              contentPadding: EdgeInsets.all(20),
              children: <Widget>[
                Text('Adicionar Exposição',
                    style:
                        TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
                SizedBox(height: 20),
                Form(
                  key: formKey,
                  child: Column(
                    children: <Widget>[
                      TextFormField(
                        controller: nameCtrl,
                        decoration:
                            InputDecoration(labelText: 'Nome da Exposição'),
                      ),
                      SizedBox(height: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Imagem da Exposição',
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
                            child: thumbnailCtrl.text.isNotEmpty
                                ? Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          thumbnailCtrl.text,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Center(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.error,
                                                      color: Colors.red),
                                                  SizedBox(height: 10),
                                                  Text(
                                                      'Erro ao carregar imagem'),
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
                                            color:
                                                Colors.black.withOpacity(0.5),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: IconButton(
                                            icon: Icon(Icons.close,
                                                color: Colors.white),
                                            onPressed: () {
                                              setModalState(() {
                                                thumbnailCtrl.clear();
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                              onPressed: () async {
                                await _pickImage();
                                if (_imageFile != null || _webImage != null) {
                                  setModalState(() {
                                    isUploading = true;
                                  });

                                  String? imageUrl = await _uploadImage();

                                  if (imageUrl != null) {
                                    setModalState(() {
                                      thumbnailCtrl.text = imageUrl;
                                      isUploading = false;
                                      _imageFile = null;
                                      _webImage = null;
                                    });
                                  } else {
                                    setModalState(() {
                                      isUploading = false;
                                    });
                                    openDialog(context, 'Erro',
                                        'Falha ao fazer upload da imagem');
                                  }
                                }
                              },
                              icon: Icon(Icons.photo_camera),
                              label: Text(thumbnailCtrl.text.isNotEmpty
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
                      SizedBox(height: 20),
                      TextFormField(
                        controller: descricaoCtrl,
                        decoration: InputDecoration(
                            labelText: 'Descrição da Exposição'),
                        maxLines: 5,
                      ),
                      TextFormField(
                        controller: curadorCtrl,
                        decoration: InputDecoration(labelText: 'Curador'),
                      ),
                      TextFormField(
                        controller: subtituloCtrl,
                        decoration: InputDecoration(
                            labelText: 'Subtítulo da Exposição'),
                      ),
                      TextFormField(
                        controller: librasCtrl,
                        decoration: InputDecoration(labelText: 'URL de Libras'),
                      ),
                      TextFormField(
                        controller: audiodescricaoCtrl,
                        decoration:
                            InputDecoration(labelText: 'URL de Audiodescrição'),
                      ),
                      TextFormField(
                        controller: nameEnCtrl,
                        decoration:
                            InputDecoration(labelText: 'Título em Inglês'),
                      ),
                      TextFormField(
                        controller: descricaoEnCtrl,
                        decoration:
                            InputDecoration(labelText: 'Descrição em Inglês'),
                        maxLines: 5,
                      ),
                      TextFormField(
                        controller: subtituloEnCtrl,
                        decoration:
                            InputDecoration(labelText: 'Subtítulo em Inglês'),
                      ),
                      ListTile(
                        title: Text(dataInicio == null
                            ? 'Selecionar Data de Início'
                            : DateFormat('dd/MM/yyyy').format(dataInicio!)),
                        trailing: Icon(Icons.calendar_today),
                        onTap: () async {
                          DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: dataInicio ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100));
                          if (picked != null) {
                            setModalState(() {
                              dataInicio = picked;
                            });
                          }
                        },
                      ),
                      ListTile(
                        title: Text(dataFim == null
                            ? 'Selecionar Data de Fim'
                            : DateFormat('dd/MM/yyyy').format(dataFim!)),
                        trailing: Icon(Icons.calendar_today),
                        onTap: () async {
                          DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: dataFim ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100));
                          if (picked != null) {
                            setModalState(() {
                              dataFim = picked;
                            });
                          }
                        },
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            style: buttonStyle(Colors.deepPurpleAccent),
                            child: Text('Salvar',
                                style: TextStyle(color: Colors.white)),
                            onPressed: () async {
                              final AdminBloc ab = Provider.of<AdminBloc>(
                                  context,
                                  listen: false);
                              if (ab.userType == 'tester') {
                                Navigator.pop(context);
                                openDialog(context, 'Você é um testador',
                                    'Só admins podem adicionar conteúdo');
                              } else {
                                if (formKey.currentState!.validate()) {
                                  await saveToDatabase();
                                  refreshData();
                                  Navigator.pop(context);
                                  openDialog(
                                      context, 'Adicionado com sucesso!', '');
                                  clearFields();
                                }
                              }
                            },
                          ),
                          TextButton(
                            style: buttonStyle(Colors.redAccent),
                            child: Text('Cancelar',
                                style: TextStyle(color: Colors.white)),
                            onPressed: () {
                              Navigator.pop(context);
                              clearFields();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _getData() async {
    setState(() => _isLoading = true);
    QuerySnapshot querySnapshot = await firestore
        .collection(collectionName)
        .orderBy('timestamp', descending: true)
        .limit(10)
        .get();
    if (querySnapshot.docs.isNotEmpty) {
      setState(() {
        _snap = querySnapshot.docs;
        _data = _snap.map((doc) => StateModel.fromFirestore(doc)).toList();
        _isLoading = false;
        _hasData = true;
      });
    } else {
      setState(() {
        _isLoading = false;
        _hasData = false;
      });
    }
  }

  Future<void> refreshData() async {
    setState(() {
      _data.clear();
      _snap.clear();
      _lastVisible = null;
    });
    await _getData();
  }

  Future<void> saveToDatabase() async {
    await firestore.collection(collectionName).add({
      'name': nameCtrl.text,
      'thumbnail': thumbnailCtrl.text,
      'descricao': descricaoCtrl.text,
      'curador': curadorCtrl.text,
      'subtitulo': subtituloCtrl.text,
      'url_libras': librasCtrl.text,
      'url_audiodescricao': audiodescricaoCtrl.text,
      'titulo_en': nameEnCtrl.text,
      'descricao_en': descricaoEnCtrl.text,
      'subtitulo_en': subtituloEnCtrl.text,
      'data_inicio': dataInicio,
      'data_fim': dataFim,
      'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
    });
  }

  void clearFields() {
    nameCtrl.clear();
    thumbnailCtrl.clear();
    descricaoCtrl.clear();
    curadorCtrl.clear();
    subtituloCtrl.clear();
    librasCtrl.clear();
    audiodescricaoCtrl.clear();
    nameEnCtrl.clear();
    descricaoEnCtrl.clear();
    subtituloEnCtrl.clear();
    setState(() {
      dataInicio = null;
      dataFim = null;
      _imageFile = null;
      _webImage = null;
    });
  }

  Widget dataList(StateModel exposicao) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CachedNetworkImage(
            imageUrl: exposicao.thumbnailUrl ?? '',
            placeholder: (context, url) =>
                Center(child: CircularProgressIndicator()),
            errorWidget: (context, url, error) => Icon(Icons.error),
            width: double.infinity,
            height: 180,
            fit: BoxFit.cover,
          ),
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exposicao.name ?? '',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
                Text(
                  exposicao.subtitulo ?? '',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                SizedBox(height: 10),
                if (exposicao.urlLibras != null)
                  Text(
                    'URL de Libras: ${exposicao.urlLibras}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                  ),
                if (exposicao.urlAudiodescricao != null)
                  Text(
                    'URL de Audiodescrição: ${exposicao.urlAudiodescricao}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => openEditDialog(exposicao),
                      child: Text('Editar'),
                    ),
                    TextButton(
                      onPressed: () => handleDelete(exposicao.timestamp!),
                      child:
                          Text('Excluir', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.05),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Exposições',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
              TextButton.icon(
                onPressed: openAddDialog,
                icon: Icon(LineIcons.list),
                label: Text('Adicionar Exposição'),
              ),
            ],
          ),
          Expanded(
            child: _hasData == false
                ? EmptyPage(
                    icon: Icons.content_paste,
                    message: 'Nenhuma exposição encontrada')
                : RefreshIndicator(
                    onRefresh: refreshData,
                    child: ListView.builder(
                      controller: controller,
                      itemCount: _data.length,
                      itemBuilder: (context, index) {
                        return dataList(_data[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
