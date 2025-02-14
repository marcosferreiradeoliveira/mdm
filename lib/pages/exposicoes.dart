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

class ExposicoesPage extends StatefulWidget {
  const ExposicoesPage({Key? key}) : super(key: key);

  @override
  _ExposicoesPageState createState() => _ExposicoesPageState();
}

class _ExposicoesPageState extends State<ExposicoesPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
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
  DateTime? dataInicio;
  DateTime? dataFim;
  String? timestamp;

  @override
  void initState() {
    controller = ScrollController()..addListener(_scrollListener);
    super.initState();
    _isLoading = true;
    _getData();
  }

  void openAddDialog() {
    nameCtrl.clear();
    thumbnailCtrl.clear();
    descricaoCtrl.clear();
    curadorCtrl.clear();
    subtituloCtrl.clear();
    dataInicio = null;
    dataFim = null;

    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          contentPadding: EdgeInsets.all(20),
          children: <Widget>[
            Text('Adicionar Exposição',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
            SizedBox(height: 20),
            Form(
              key: formKey,
              child: Column(
                children: <Widget>[
                  TextFormField(
                    controller: nameCtrl,
                    decoration: InputDecoration(labelText: 'Nome da Exposição'),
                  ),
                  TextFormField(
                    controller: thumbnailCtrl,
                    decoration: InputDecoration(labelText: 'URL do Thumbnail'),
                    maxLines: 2,
                  ),
                  TextFormField(
                    controller: descricaoCtrl,
                    decoration:
                        InputDecoration(labelText: 'Descrição da Exposição'),
                    maxLines: 5,
                  ),
                  TextFormField(
                    controller: curadorCtrl,
                    decoration: InputDecoration(labelText: 'Curador'),
                  ),
                  TextFormField(
                    controller: subtituloCtrl,
                    decoration:
                        InputDecoration(labelText: 'Subtítulo da Exposição'),
                  ),
                  ListTile(
                    title: Text(dataInicio == null
                        ? 'Selecionar Data de Início'
                        : DateFormat('dd/MM/yyyy').format(dataInicio!)),
                    trailing: Icon(Icons.calendar_today),
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
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
                          initialDate: DateTime.now(),
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
                          final AdminBloc ab =
                              Provider.of<AdminBloc>(context, listen: false);
                          if (ab.userType == 'tester') {
                            Navigator.pop(context);
                            openDialog(context, 'Você é um testador',
                                'Só admins podem adicionar conteúdo');
                          } else {
                            await firestore
                                .collection(collectionName)
                                .add({
                                  'name': nameCtrl.text,
                                  'thumbnail': thumbnailCtrl.text,
                                  'descricao': descricaoCtrl.text,
                                  'curador': curadorCtrl.text,
                                  'subtitulo': subtituloCtrl.text,
                                  'data_inicio': dataInicio,
                                  'data_fim': dataFim,
                                  'timestamp': DateTime.now()
                                      .millisecondsSinceEpoch
                                      .toString(),
                                })
                                .then(
                                    (value) => ab.increaseCount('states_count'))
                                .then((value) => openToast(
                                    context, 'Adicionado com sucesso'));
                            refreshData();
                            Navigator.pop(context);
                          }
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
  }

  Future<void> _getData() async {
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

    if (data.docs.isNotEmpty) {
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
      setState(() {
        _isLoading = false;
        _hasData = _lastVisible != null;
      });
      if (_lastVisible != null) {
        openToast(context, 'Nenhum conteúdo encontrado');
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
    controller!.dispose();
  }

  void _scrollListener() {
    if (!_isLoading &&
        controller!.position.pixels == controller!.position.maxScrollExtent) {
      setState(() => _isLoading = true);
      _getData();
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

  void handleDelete(String timestamp1) {
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

  void openEditDialog(StateModel exposicao) {
    nameCtrl.text = exposicao.name ?? '';
    thumbnailCtrl.text = exposicao.thumbnailUrl ?? '';
    descricaoCtrl.text = exposicao.descricao ?? '';
    curadorCtrl.text = exposicao.curador ?? '';
    subtituloCtrl.text = exposicao.subtitulo ?? '';
    dataInicio = exposicao.dataInicio;
    dataFim = exposicao.dataFim;

    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          contentPadding: EdgeInsets.all(20),
          children: <Widget>[
            Text('Editar Exposição',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
            SizedBox(height: 20),
            Form(
              key: formKey,
              child: Column(
                children: <Widget>[
                  TextFormField(
                    controller: nameCtrl,
                    decoration: InputDecoration(labelText: 'Nome da Exposição'),
                  ),
                  TextFormField(
                    controller: thumbnailCtrl,
                    decoration: InputDecoration(labelText: 'URL do Thumbnail'),
                    maxLines: 2,
                  ),
                  TextFormField(
                    controller: descricaoCtrl,
                    decoration:
                        InputDecoration(labelText: 'Descrição da Exposição'),
                    maxLines: 5,
                  ),
                  TextFormField(
                    controller: curadorCtrl,
                    decoration: InputDecoration(labelText: 'Curador'),
                  ),
                  TextFormField(
                    controller: subtituloCtrl,
                    decoration:
                        InputDecoration(labelText: 'Subtítulo da Exposição'),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.05),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Exposições',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
            Container(
              width: 300,
              height: 40,
              padding: EdgeInsets.symmetric(horizontal: 15),
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
          margin: EdgeInsets.symmetric(vertical: 10),
          height: 3,
          width: 50,
          decoration: BoxDecoration(
              color: Colors.indigoAccent,
              borderRadius: BorderRadius.circular(15)),
        ),
        Expanded(
          child: _hasData == false
              ? EmptyPage(
                  icon: Icons.content_paste,
                  message:
                      'Nenhuma exposição encontrada,\nCadastre exposições primeiro')
              : RefreshIndicator(
                  onRefresh: refreshData,
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    controller: controller,
                    physics: AlwaysScrollableScrollPhysics(),
                    itemCount: _data.length,
                    itemBuilder: (context, index) {
                      return dataList(_data[index]);
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
