import 'package:admin/blocs/admin_bloc.dart';
import 'package:admin/models/state.dart';
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

class States extends StatefulWidget {
  const States({Key? key}) : super(key: key);

  @override
  _CitiesPageState createState() => _CitiesPageState();
}

class _CitiesPageState extends State<States> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  ScrollController? controller;
  DocumentSnapshot? _lastVisible;
  late bool _isLoading;
  List<DocumentSnapshot> _snap = [];
  List<StateModel> _data = [];
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final String collectionName = 'exposições';
  bool? _hasData;

  @override
  void initState() {
    controller = new ScrollController()..addListener(_scrollListener);
    super.initState();
    _isLoading = true;
    _getData();
  }

  Future<Null> _getData() async {
    QuerySnapshot data;
    if (_lastVisible == null)
      data = await firestore
          .collection(collectionName)
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();
    else
      data = await firestore
          .collection(collectionName)
          .orderBy('timestamp', descending: true)
          .startAfter([_lastVisible!['timestamp']])
          .limit(10)
          .get();

    if (data.docs.length > 0) {
      _lastVisible = data.docs[data.docs.length - 1];
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasData = true;
          _snap.addAll(data.docs);
          _data = _snap.map((e) => StateModel.fromFirestore(e)).toList();
        });
      }
    } else {
      if (_lastVisible == null) {
        setState(() {
          _isLoading = false;
          _hasData = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _hasData = true;
        });
        openToast(context, 'Nenhum conteúdo encontrado');
      }
    }
    return null;
  }

  @override
  void dispose() {
    super.dispose();
    controller!.dispose();
  }

  void _scrollListener() {
    if (!_isLoading) {
      if (controller!.position.pixels == controller!.position.maxScrollExtent) {
        setState(() => _isLoading = true);
        _getData();
      }
    }
  }

  refreshData() async {
    setState(() {
      _data.clear();
      _snap.clear();
      _lastVisible = null;
    });
    await _getData();
  }

  handleDelete(timestamp1) {
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
              SizedBox(
                height: 10,
              ),
              Text('Você quer apagar?',
                  style: TextStyle(
                      color: Colors.grey[900],
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              SizedBox(
                height: 30,
              ),
              Center(
                  child: Row(
                children: <Widget>[
                  TextButton(
                    style: buttonStyle(Colors.redAccent),
                    child: Text(
                      'Sim',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600),
                    ),
                    onPressed: () async {
                      if (ab.userType == 'tester') {
                        Navigator.pop(context);
                        openDialog(context, 'Você é um testador',
                            'Só admins podem deletar conteúdo');
                      } else {
                        await ab
                            .deleteContent(timestamp1, collectionName)
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
                    child: Text(
                      'Não',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ))
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.05,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Exposições',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
            ),
            Container(
              width: 300,
              height: 40,
              padding: EdgeInsets.only(left: 15, right: 15),
              decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(30)),
              child: TextButton.icon(
                  onPressed: () {
                    openAddDialog();
                  },
                  icon: Icon(LineIcons.list),
                  label: Text('Adicionar Exposição')),
            ),
          ],
        ),
        Container(
          margin: EdgeInsets.only(top: 5, bottom: 10),
          height: 3,
          width: 50,
          decoration: BoxDecoration(
              color: Colors.indigoAccent,
              borderRadius: BorderRadius.circular(15)),
        ),
        SizedBox(
          height: 30,
        ),
        Expanded(
          child: _hasData == false
              ? EmptyPage(
                  icon: Icons.content_paste,
                  message:
                      'Nenhuma exposição encontrada,\nCadastre exposições primeiro')
              : RefreshIndicator(
                  child: ListView.separated(
                    padding: EdgeInsets.only(top: 30, bottom: 20),
                    controller: controller,
                    physics: AlwaysScrollableScrollPhysics(),
                    itemCount: _data.length + 1,
                    separatorBuilder: (BuildContext context, int index) =>
                        SizedBox(
                      height: 10,
                    ),
                    itemBuilder: (_, int index) {
                      if (index < _data.length) {
                        return dataList(_data[index]);
                      }
                      return Center(
                        child: new Opacity(
                          opacity: _isLoading ? 1.0 : 0.0,
                          child: new SizedBox(
                              width: 32.0,
                              height: 32.0,
                              child: new CircularProgressIndicator()),
                        ),
                      );
                    },
                  ),
                  onRefresh: () async {
                    refreshData();
                  },
                ),
        ),
      ],
    );
  }

  Widget dataList(StateModel d) {
    return Container(
      height: 130,
      padding: EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),
      decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
          image: DecorationImage(
              image: CachedNetworkImageProvider(d.thumbnailUrl!),
              fit: BoxFit.cover)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Spacer(),
          Text(
            d.name!,
            style: TextStyle(
                fontSize: 30, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          Spacer(),
          InkWell(
            child: Container(
                height: 35,
                width: 35,
                decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.edit, size: 16, color: Colors.grey[800])),
            onTap: () => openEditDialog(
                d.name!, d.thumbnailUrl!, d.descricao!, d.timestamp!),
          ),
          SizedBox(
            width: 10,
          ),
          InkWell(
            child: Container(
                height: 35,
                width: 35,
                decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.delete, size: 16, color: Colors.grey[800])),
            onTap: () => handleDelete(d.timestamp),
          )
        ],
      ),
    );
  }

  // add/upload states

  var formKey = GlobalKey<FormState>();
  var nameCtrl = TextEditingController();
  var thumbnailCtrl = TextEditingController();
  var descricaoCtrl = TextEditingController();
  String? timestamp;

  Future addState() async {
    final DocumentReference ref =
        firestore.collection(collectionName).doc(timestamp);
    await ref.set({
      'name': nameCtrl.text,
      'thumbnail': thumbnailCtrl.text,
      'timestamp': timestamp,
      'descricao': descricaoCtrl.text,
    });
  }

  handleAddState() async {
    final AdminBloc ab = Provider.of<AdminBloc>(context, listen: false);
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      if (ab.userType == 'tester') {
        Navigator.pop(context);
        openDialog(context, 'Você é um testador',
            'Só admins podem adicionar conteúdo');
      } else {
        await getTimestamp()
            .then((value) => addState())
            .then((value) =>
                context.read<AdminBloc>().increaseCount('states_count'))
            .then((value) => openToast(context, 'Adiciobnado com sucesso'))
            .then((value) => ab.getStates());
        refreshData();
        Navigator.pop(context);
      }
    }
  }

  clearTextfields() {
    nameCtrl.clear();
    thumbnailCtrl.clear();
    descricaoCtrl.clear();
  }

  Future getTimestamp() async {
    DateTime now = DateTime.now();
    String _timestamp = DateFormat('yyyyMMddHHmmss').format(now);
    setState(() {
      timestamp = _timestamp;
    });
  }

  openAddDialog() {
    showDialog(
        context: context,
        builder: (context) {
          return SimpleDialog(
            contentPadding: EdgeInsets.all(100),
            children: <Widget>[
              Text(
                'Adicionar Exposição',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
              ),
              SizedBox(
                height: 50,
              ),
              Form(
                  key: formKey,
                  child: Column(
                    children: <Widget>[
                      TextFormField(
                        decoration: inputDecoration('Ponha o Nome da Exposição',
                            'Nome da Exposição', nameCtrl),
                        controller: nameCtrl,
                        validator: (value) {
                          if (value!.isEmpty)
                            return 'Nome da Exposição está vazio';
                          return null;
                        },
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      TextFormField(
                        decoration: inputDecoration('Ponha a URL do Thumbnail',
                            'Endereço do Thumbnail', thumbnailCtrl),
                        controller: thumbnailCtrl,
                        validator: (value) {
                          if (value!.isEmpty) return 'Thumbnail está vazio';
                          return null;
                        },
                      ),
                      SizedBox(
                        height: 50,
                      ),
                      TextFormField(
                        decoration: inputDecoration('Descrição da Exposição',
                            'Descrição da Exposição', descricaoCtrl),
                        controller: descricaoCtrl,
                        validator: (value) {
                          if (value!.isEmpty)
                            return 'escrição da Exposição está vazio';
                          return null;
                        },
                      ),
                      SizedBox(
                        height: 50,
                      ),
                      Center(
                          child: Row(
                        children: <Widget>[
                          TextButton(
                            style: buttonStyle(Colors.deepPurpleAccent),
                            child: Text(
                              'Adicionar Exposição',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600),
                            ),
                            onPressed: () async {
                              await handleAddState();
                              clearTextfields();
                            },
                          ),
                          SizedBox(width: 10),
                          TextButton(
                            style: buttonStyle(Colors.redAccent),
                            child: Text(
                              'Cancelar',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600),
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ))
                    ],
                  ))
            ],
          );
        });
  }

  //update/edit states

  var nameCtrl1 = TextEditingController();
  var thumbnailCtrl1 = TextEditingController();
  var descricaoCtrl1 = TextEditingController();
  var formKey1 = GlobalKey<FormState>();

  Future _updateState(String stateTimestamp) async {
    final DocumentReference ref =
        firestore.collection(collectionName).doc(stateTimestamp);
    await ref.update({
      'name': nameCtrl1.text,
      'thumbnail': thumbnailCtrl1.text,
      'descricao': descricaoCtrl1.text,
    });
  }

  Future _handleUpdateState(String stateTimestamp) async {
    final AdminBloc ab = Provider.of<AdminBloc>(context, listen: false);
    if (formKey1.currentState!.validate()) {
      formKey1.currentState!.save();
      if (ab.userType == 'tester') {
        Navigator.pop(context);
        openDialog(context, 'Você é um testador',
            'Só admins podem atualizar exposições');
      } else {
        await _updateState(stateTimestamp)
            .then((value) => openToast(context, 'Atualizado com sucesso'))
            .then((value) => ab.getStates());
        refreshData();
        Navigator.pop(context);
      }
    }
  }

  void openEditDialog(String oldStateName, String oldThumbnailUrl,
      String oldDescricao, String stateTimestamp) {
    showDialog(
      context: context,
      builder: (context) {
        nameCtrl1.text = oldStateName;
        thumbnailCtrl1.text = oldThumbnailUrl;
        descricaoCtrl1.text = oldDescricao;

        return SimpleDialog(
          contentPadding: EdgeInsets.all(100),
          children: <Widget>[
            Text(
              'Edite Exposição',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
            ),
            SizedBox(
              height: 50,
            ),
            Form(
              key: formKey1,
              child: Column(
                children: <Widget>[
                  TextFormField(
                    decoration: inputDecoration('Ponha o nome da Exposição',
                        'Nome da Exposição', nameCtrl1),
                    controller: nameCtrl1,
                    validator: (value) {
                      if (value!.isEmpty) return 'Nome está vazio';
                      return null;
                    },
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  TextFormField(
                    decoration: inputDecoration('Endereço do Thumbnail',
                        'Endereço do Thumbnail', thumbnailCtrl1),
                    controller: thumbnailCtrl1,
                    validator: (value) {
                      if (value!.isEmpty) return 'Thumbnail está vazio';
                      return null;
                    },
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  TextFormField(
                    decoration: inputDecoration('Descrição da Exposição',
                        'Descrição da Exposição', descricaoCtrl1),
                    controller: descricaoCtrl1,
                    validator: (value) {
                      if (value!.isEmpty) return 'Descrição está vazia';
                      return null;
                    },
                  ),
                  SizedBox(
                    height: 50,
                  ),
                  Center(
                    child: Row(
                      children: <Widget>[
                        TextButton(
                          style: buttonStyle(Colors.purpleAccent),
                          child: Text(
                            'Atualizar Exposição',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600),
                          ),
                          onPressed: () async =>
                              _handleUpdateState(stateTimestamp),
                        ),
                        SizedBox(width: 10),
                        TextButton(
                          style: buttonStyle(Colors.redAccent),
                          child: Text(
                            'Cancelar',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600),
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
