import 'package:admin/blocs/admin_bloc.dart';
import 'package:admin/models/item.dart';
import 'package:admin/pages/comments.dart';
import 'package:admin/utils/cached_image.dart';
import 'package:admin/utils/dialog.dart';
import 'package:admin/utils/empty.dart';
import 'package:admin/utils/next_screen.dart';
import 'package:admin/utils/styles.dart';
import 'package:admin/utils/toast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart';

class ItensPage extends StatefulWidget {
  final String exposicaoId;
  const ItensPage({Key? key, required this.exposicaoId}) : super(key: key);

  @override
  _ItensPageState createState() => _ItensPageState();
}

class _ItensPageState extends State<ItensPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  ScrollController? controller;
  DocumentSnapshot? _lastVisible;
  late bool _isLoading;
  List<DocumentSnapshot> _snap = [];
  List<Item> _data = [];
  final scaffoldKey = GlobalKey<ScaffoldState>();
  String collectionName = 'Item';

  late bool _descending;
  late String _orderBy;
  bool? _hasData;

  @override
  void initState() {
    controller = ScrollController()..addListener(_scrollListener);
    super.initState();
    _isLoading = true;
    _orderBy = 'timestamp';
    _descending = true;
    if (this.mounted) {
      _getData();
    }
  }

  Future<Null> _getData() async {
    QuerySnapshot data;
    try {
      if (_lastVisible == null) {
        data = await firestore
            .collection(collectionName)
            .orderBy(_orderBy, descending: _descending)
            .limit(10)
            .get();
      } else {
        data = await firestore
            .collection(collectionName)
            .orderBy(_orderBy, descending: _descending)
            .startAfter([_lastVisible![_orderBy]])
            .limit(10)
            .get();
      }

      if (data.docs.length > 0) {
        _lastVisible = data.docs[data.docs.length - 1];
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasData = true;
            _snap.addAll(data.docs);
            _data = _snap.map((e) => Item.fromFirestore(e)).toList();
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
    } catch (e) {
      print('Erro ao buscar dados: $e');
      setState(() {
        _isLoading = false;
        _hasData = false;
      });
    }
    return null;
  }

  refreshData() {
    setState(() {
      _isLoading = true;
      _snap.clear();
      _data.clear();
      _lastVisible = null;
    });
    _getData();
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

  navigateToReviewPage(context, timestamp, name) {
    nextScreenPopuup(
        context,
        CommentsPage(
          collectionName: collectionName,
          timestamp: timestamp,
          title: name,
        ));
  }

  handleDelete(timestamp) {
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
              Text('Você quer apagar este item do banco de dados?',
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
                            .deleteContent(timestamp, collectionName)
                            .then((value) =>
                                ab.removefromFeaturedList(context, timestamp))
                            .then((value) => ab.decreaseCount('item_count'));
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

  void openEditDialog(Item item) {
    TextEditingController tituloCtrl = TextEditingController(text: item.titulo);
    TextEditingController descricaoCtrl =
        TextEditingController(text: item.descricao);
    TextEditingController imagemCtrl = TextEditingController(text: item.imagem);
    TextEditingController librasCtrl =
        TextEditingController(text: item.urlLibras);
    TextEditingController audiodescricaoCtrl =
        TextEditingController(text: item.urlAudiodescricao);
    String? exposicaoId = item.exposicaoId;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return SimpleDialog(
              contentPadding: EdgeInsets.all(20),
              children: <Widget>[
                Text('Editar Item',
                    style:
                        TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
                SizedBox(height: 20),
                Form(
                  child: Column(
                    children: <Widget>[
                      TextFormField(
                        controller: tituloCtrl,
                        decoration: InputDecoration(labelText: 'Título'),
                      ),
                      TextFormField(
                        controller: descricaoCtrl,
                        decoration: InputDecoration(labelText: 'Descrição'),
                        maxLines: 3,
                      ),
                      TextFormField(
                        controller: imagemCtrl,
                        decoration: InputDecoration(labelText: 'URL da Imagem'),
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
                      StreamBuilder<QuerySnapshot>(
                        stream: firestore.collection('exposições').snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return CircularProgressIndicator();
                          } else {
                            List<DropdownMenuItem<String>> exposicaoItems = [];
                            for (var doc in snapshot.data!.docs) {
                              exposicaoItems.add(
                                DropdownMenuItem(
                                  child: Text(doc['name']),
                                  value: doc.id,
                                ),
                              );
                            }
                            return DropdownButtonFormField(
                              value: exposicaoId,
                              items: exposicaoItems,
                              onChanged: (value) {
                                setState(() {
                                  exposicaoId = value as String?;
                                });
                              },
                              decoration:
                                  InputDecoration(labelText: 'Exposição'),
                            );
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
                                  .doc(item.timestamp)
                                  .update({
                                'titulo': tituloCtrl.text,
                                'descricao': descricaoCtrl.text,
                                'imagem': imagemCtrl.text,
                                'exposicaoId': exposicaoId,
                                'url_libras': librasCtrl.text,
                                'url_audiodescricao': audiodescricaoCtrl.text,
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
              'Itens',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700),
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
        Expanded(
          child: _hasData == false
              ? EmptyPage(
                  icon: Icons.content_paste,
                  message: 'Nenhum dado disponível.\nFaça o upload primeiro!')
              : RefreshIndicator(
                  child: ListView.builder(
                    padding: EdgeInsets.only(top: 30, bottom: 20),
                    controller: controller,
                    physics: AlwaysScrollableScrollPhysics(),
                    itemCount: _data.length + 1,
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

  Widget dataList(Item d) {
    return Container(
      padding: EdgeInsets.all(15),
      margin: EdgeInsets.only(top: 5, bottom: 10),
      decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: <Widget>[
          Container(
            height: 110,
            width: 110,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
            child: CustomCacheImage(
              imageUrl: d.imagem!,
              radius: 10,
            ),
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.only(
                left: 15,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        d.titulo!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  Text(
                    d.descricao!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  if (d.urlLibras != null && d.urlLibras!.isNotEmpty)
                    Text(
                      'URL de Libras: ${d.urlLibras}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                    ),
                  if (d.urlAudiodescricao != null &&
                      d.urlAudiodescricao!.isNotEmpty)
                    Text(
                      'URL de Audiodescrição: ${d.urlAudiodescricao}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                    ),
                  SizedBox(
                    height: 10,
                  ),
                  Row(
                    children: <Widget>[
                      InkWell(
                        child: Container(
                            height: 35,
                            width: 45,
                            decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(10)),
                            child: Icon(Icons.edit,
                                size: 16, color: Colors.grey[800])),
                        onTap: () {
                          openEditDialog(d);
                        },
                      ),
                      SizedBox(width: 10),
                      InkWell(
                        child: Container(
                            height: 35,
                            width: 45,
                            decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(10)),
                            child: Icon(Icons.delete,
                                size: 16, color: Colors.grey[800])),
                        onTap: () {
                          handleDelete(d.timestamp);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
