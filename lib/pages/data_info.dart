import 'package:admin/blocs/admin_bloc.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DataInfoPage extends StatefulWidget {
  const DataInfoPage({Key? key}) : super(key: key);

  @override
  _DataInfoPageState createState() => _DataInfoPageState();
}

class _DataInfoPageState extends State<DataInfoPage> {
  Future? users;
  Future? places;
  Future? blogs;
  Future? notifications;
  Future? states;

  @override
  void initState() {
    super.initState();
    users = context.read<AdminBloc>().getTotalDocuments('users_count');
    places = context.read<AdminBloc>().getTotalDocuments('places_count');
    blogs = context.read<AdminBloc>().getTotalDocuments('blogs_count');
    notifications =
        context.read<AdminBloc>().getTotalDocuments('notifications_count');
    states = context.read<AdminBloc>().getTotalDocuments('states_count');
  }

  @override
  Widget build(BuildContext context) {
    double w = MediaQuery.of(context).size.width;

    return Container(
      padding: EdgeInsets.only(left: w * 0.05, right: w * 0.05, top: w * 0.05),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              FutureBuilder(
                future: states,
                builder: (BuildContext context, AsyncSnapshot snap) {
                  if (!snap.hasData) return card('Exposições', 0);
                  if (snap.hasError) return card('Exposições', 0);
                  return card('Exposições', snap.data);
                },
              ),
              SizedBox(
                width: 20,
              ),
              FutureBuilder(
                future: places,
                builder: (BuildContext context, AsyncSnapshot snap) {
                  if (!snap.hasData) return card('Itens', 0);
                  if (snap.hasError) return card('Itens', 0);
                  return card('Itens', snap.data);
                },
              ),
            ],
          ),
          SizedBox(
            height: 30,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              FutureBuilder(
                future: blogs,
                builder: (BuildContext context, AsyncSnapshot snap) {
                  if (!snap.hasData) return card('Atualizações', 0);
                  if (snap.hasError) return card('Atualizações', 0);
                  return card('Atualizações', snap.data);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget card(String title, int? number) {
    return Container(
      padding: EdgeInsets.all(30),
      height: 180,
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(0),
        boxShadow: <BoxShadow>[
          BoxShadow(
              color: Colors.grey[300]!, blurRadius: 10, offset: Offset(3, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black54),
          ),
          Container(
            margin: EdgeInsets.only(top: 5, bottom: 5),
            height: 2,
            width: 30,
            decoration: BoxDecoration(
                color: Colors.indigoAccent,
                borderRadius: BorderRadius.circular(15)),
          ),
          SizedBox(
            height: 30,
          ),
          Row(
            children: <Widget>[
              Icon(
                Icons.trending_up,
                size: 40,
                color: Colors.deepPurpleAccent,
              ),
              SizedBox(
                width: 5,
              ),
              Text(
                number.toString(),
                style: TextStyle(
                    fontSize: 35,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87),
              )
            ],
          )
        ],
      ),
    );
  }
}
