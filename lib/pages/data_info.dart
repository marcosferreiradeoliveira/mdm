import 'package:flutter/material.dart';

class DataInfoPage extends StatelessWidget {
  const DataInfoPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(30),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Bem vindo ao Painel Administrativo do App Museu das Mulheres',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurpleAccent,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          Container(
            constraints: BoxConstraints(maxWidth: 800),
            child: Text(
              'Aqui podem ser acrescentadas informações gerais sobre o funcionamento do site e do App.',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
