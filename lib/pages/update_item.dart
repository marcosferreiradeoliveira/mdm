import 'package:admin/blocs/admin_bloc.dart';
import 'package:admin/models/item.dart';
import 'package:admin/utils/dialog.dart';
import 'package:admin/widgets/cover_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UpdateItem extends StatefulWidget {
  final Item itemData;
  UpdateItem({Key? key, required this.itemData}) : super(key: key);

  @override
  _UpdateItemState createState() => _UpdateItemState();
}

class _UpdateItemState extends State<UpdateItem> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  var formKey = GlobalKey<FormState>();
  var scaffoldKey = GlobalKey<ScaffoldState>();
  final String collectionName = 'Item';

  var exposicaoCtrl = TextEditingController();
  var tituloCtrl = TextEditingController();
  var imagemCtrl = TextEditingController();
  var descricaoCtrl = TextEditingController();

  clearFields() {
    exposicaoCtrl.clear();
    tituloCtrl.clear();
    imagemCtrl.clear();
    descricaoCtrl.clear();
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
        await saveToDatabase();
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
    };

    await ref.update(_itemData);
  }

  initData() {
    exposicaoCtrl.text = widget.itemData.exposicaoId!;
    tituloCtrl.text = widget.itemData.titulo!;
    imagemCtrl.text = widget.itemData.imagem!;
    descricaoCtrl.text = widget.itemData.descricao!;
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
                TextFormField(
                  decoration: inputDecoration(
                      'ID da Exposição', 'Exposição', exposicaoCtrl),
                  controller: exposicaoCtrl,
                  validator: (value) {
                    if (value!.isEmpty) return 'Campo vazio';
                    return null;
                  },
                ),
                SizedBox(
                  height: 20,
                ),
                TextFormField(
                  decoration:
                      inputDecoration('Título do Item', 'Título', tituloCtrl),
                  controller: tituloCtrl,
                  validator: (value) {
                    if (value!.isEmpty) return 'Campo vazio';
                    return null;
                  },
                ),
                SizedBox(
                  height: 20,
                ),
                TextFormField(
                  decoration:
                      inputDecoration('URL da Imagem', 'Imagem', imagemCtrl),
                  controller: imagemCtrl,
                  validator: (value) {
                    if (value!.isEmpty) return 'Campo vazio';
                    return null;
                  },
                ),
                SizedBox(
                  height: 20,
                ),
                TextFormField(
                  decoration: InputDecoration(
                      hintText: 'Descrição do Item',
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
                    if (value!.isEmpty) return 'Campo vazio';
                    return null;
                  },
                ),
                SizedBox(
                  height: 50,
                ),
                Container(
                    color: Colors.deepPurpleAccent,
                    height: 45,
                    child: TextButton(
                        child: Text(
                          'Atualizar Item',
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
              }),
        ),
      ),
    );
  }
}
