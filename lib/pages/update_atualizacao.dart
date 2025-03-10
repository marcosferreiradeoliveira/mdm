import 'package:admin/blocs/admin_bloc.dart';
import 'package:admin/models/atualizacao.dart';
import 'package:admin/utils/dialog.dart';
import 'package:admin/widgets/blog_preview.dart';
import 'package:admin/widgets/cover_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UpdateBlog extends StatefulWidget {
  final Blog blogData;
  UpdateBlog({Key? key, required this.blogData}) : super(key: key);

  @override
  _UpdateBlogState createState() => _UpdateBlogState();
}

class _UpdateBlogState extends State<UpdateBlog> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  var formKey = GlobalKey<FormState>();
  var titleCtrl = TextEditingController();
  var titleEnCtrl = TextEditingController();
  var imageUrlCtrl = TextEditingController();
  var descriptionCtrl = TextEditingController();
  var descriptionEnCtrl = TextEditingController();
  var scaffoldKey = GlobalKey<ScaffoldState>();

  bool uploadStarted = false;

  void handleSubmit() async {
    final AdminBloc ab = Provider.of<AdminBloc>(context, listen: false);
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      if (ab.userType == 'tester') {
        openDialog(context, 'Você é um Testador',
            'Somente Admin pode fazer upload, deletar e modificar conteúdos');
      } else {
        setState(() => uploadStarted = true);
        await updateDatabase();
        setState(() => uploadStarted = false);
        openDialog(context, 'Atualizado com Sucesso', '');
      }
    }
  }

  Future updateDatabase() async {
    final DocumentReference ref =
        firestore.collection('blogs').doc(widget.blogData.timestamp);
    var _blogData = {
      'title': titleCtrl.text,
      'title_en': titleEnCtrl.text,
      'description': descriptionCtrl.text,
      'description_en': descriptionEnCtrl.text,
      'image url': imageUrlCtrl.text,
    };
    await ref.update(_blogData);
  }

  clearTextFields() {
    titleCtrl.clear();
    titleEnCtrl.clear();
    descriptionCtrl.clear();
    descriptionEnCtrl.clear();
    imageUrlCtrl.clear();
    FocusScope.of(context).unfocus();
  }

  handlePreview() async {
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      await showBlogPreview(
          context,
          titleCtrl.text,
          descriptionCtrl.text,
          imageUrlCtrl.text,
          widget.blogData.loves ?? 0,
          '',
          widget.blogData.date ?? '');
    }
  }

  initBlogData() {
    Blog d = widget.blogData;
    titleCtrl.text = d.title ?? '';
    titleEnCtrl.text = d.titleEn ?? '';
    descriptionCtrl.text = d.description ?? '';
    descriptionEnCtrl.text = d.descriptionEn ?? '';
    imageUrlCtrl.text = d.thumbnailImagelUrl ?? '';
  }

  @override
  void initState() {
    super.initState();
    initBlogData();
  }

  @override
  Widget build(BuildContext context) {
    double h = MediaQuery.of(context).size.height;
    return Scaffold(
        appBar: AppBar(),
        key: scaffoldKey,
        backgroundColor: Colors.grey[200],
        body: CoverWidget(
          widget: Form(
              key: formKey,
              child: ListView(
                controller: ScrollController(),
                children: <Widget>[
                  SizedBox(
                    height: h * 0.10,
                  ),
                  Text(
                    'Atualizar Detalhes do Blog',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(
                    height: 50,
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
                  TextFormField(
                    decoration: inputDecoration(
                        'Digite a URL da Imagem', 'Imagem', imageUrlCtrl),
                    controller: imageUrlCtrl,
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
                      hintText: 'Digite a Descrição (Html ou Texto Normal)',
                      border: OutlineInputBorder(),
                      labelText: 'Descrição',
                      contentPadding: EdgeInsets.only(
                          right: 0, left: 10, top: 15, bottom: 5),
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
                      contentPadding: EdgeInsets.only(
                          right: 0, left: 10, top: 15, bottom: 5),
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
                                fontWeight: FontWeight.w400,
                                color: Colors.black),
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
                      child: uploadStarted == true
                          ? Center(
                              child: Container(
                                  height: 30,
                                  width: 30,
                                  child: CircularProgressIndicator()),
                            )
                          : TextButton(
                              child: Text(
                                'Atualizar Blog',
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
        ));
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
