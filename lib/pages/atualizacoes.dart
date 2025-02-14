import 'package:admin/blocs/admin_bloc.dart';
import 'package:admin/models/blog.dart';
import 'package:admin/pages/comments.dart';
import 'package:admin/pages/update_atualizacao.dart';
import 'package:admin/utils/cached_image.dart';
import 'package:admin/utils/dialog.dart';
import 'package:admin/utils/empty.dart';
import 'package:admin/utils/next_screen.dart';
import 'package:admin/utils/styles.dart';
import 'package:admin/utils/toast.dart';
import 'package:admin/widgets/blog_preview.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

class BlogPage extends StatefulWidget {
  const BlogPage({Key? key}) : super(key: key);

  @override
  _BlogPageState createState() => _BlogPageState();
}

class _BlogPageState extends State<BlogPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  ScrollController? controller;
  DocumentSnapshot? _lastVisible;
  late bool _isLoading;
  List<DocumentSnapshot> _snap = [];
  List<Blog> _data = [];
  final scaffoldKey = GlobalKey<ScaffoldState>();
  String collectionName = 'blogs';

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
    initializeDateFormatting('pt_BR', null).then((_) {
      if (this.mounted) {
        _getData();
      }
    });
  }

  Future<void> _getData() async {
    try {
      QuerySnapshot data;
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

      if (data.docs.isNotEmpty) {
        _lastVisible = data.docs.last;
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasData = true;
            _snap.addAll(data.docs);
            _data = _snap.map((e) => Blog.fromFirestore(e)).toList();
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
          });
          openToast(context, 'Nenhum conteúdo disponível');
        }
      }
    } catch (e) {
      print('Erro ao buscar dados: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (!_isLoading &&
        controller!.position.pixels == controller!.position.maxScrollExtent) {
      setState(() => _isLoading = true);
      _getData();
    }
  }

  Future<void> handleDelete(String timestamp) async {
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
              Text('Você quer apagar este item do banco de dados?',
                  style: TextStyle(
                      color: Colors.grey[900],
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
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
                        await ab.deleteContent(timestamp, 'blogs');
                        ab.decreaseCount('blogs_count');
                        openToast(context, 'Item deletado com sucesso!');
                        reloadData();
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
              )
            ],
          );
        });
  }

  void reloadData() {
    setState(() {
      _isLoading = true;
      _snap.clear();
      _data.clear();
      _lastVisible = null;
    });
    _getData();
  }

  void handlePreview(Blog d) async {
    await showBlogPreview(context, d.title, d.description, d.thumbnailImagelUrl,
        d.loves, d.sourceUrl, d.date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: Text(
          'Atualizações',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: _hasData == false
          ? EmptyPage(
              icon: Icons.content_paste,
              message: 'Nenhum dado disponível.\nFaça o upload primeiro!')
          : RefreshIndicator(
              onRefresh: () async {
                reloadData();
              },
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
            ),
    );
  }

  Widget dataList(Blog d) {
    return Container(
      padding: EdgeInsets.all(15),
      margin: EdgeInsets.only(top: 5, bottom: 5),
      height: 150,
      decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: <Widget>[
          Container(
            height: 130,
            width: 130,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
            child: CustomCacheImage(
              imageUrl: d.thumbnailImagelUrl,
              radius: 10,
            ),
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.only(
                top: 15,
                left: 15,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    d.title!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
                            child: Icon(Icons.remove_red_eye,
                                size: 16, color: Colors.grey[800])),
                        onTap: () {
                          handlePreview(d);
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
                            child: Icon(Icons.edit,
                                size: 16, color: Colors.grey[800])),
                        onTap: () {
                          nextScreen(context, UpdateBlog(blogData: d));
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
                          handleDelete(d.timestamp!);
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
