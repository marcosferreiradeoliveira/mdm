import 'package:admin/blocs/admin_bloc.dart';
import 'package:admin/config/config.dart';
import 'package:admin/pages/home.dart';
import 'package:admin/utils/next_screen.dart';
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart';

class SignInPage extends StatefulWidget {
  SignInPage({Key? key}) : super(key: key);

  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  var passwordCtrl = TextEditingController();
  var formKey = GlobalKey<FormState>();
  String? password;

  handleSignIn() async {
    final AdminBloc ab = Provider.of<AdminBloc>(context, listen: false);
    if (formKey.currentState!.validate()) {
      formKey.currentState!.validate();
      if (password == Config().testerPassword) {
        await ab.setSignInForTesting();
        Future.delayed(Duration(seconds: 1)).then((value) => nextScreenReplace(context, HomePage()));
      } else {
        await ab.setSignIn();
        Future.delayed(Duration(seconds: 1)).then((value) => nextScreenReplace(context, HomePage()));
      }
    }
  }

  @override
  void dispose() {
    passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AdminBloc ab = Provider.of<AdminBloc>(context, listen: false);

    return Scaffold(
        backgroundColor: Colors.grey[200],
        body: Center(
          child: Container(
            height: 400,
            width: 600,
            padding: EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(0),
              boxShadow: <BoxShadow>[BoxShadow(color: Colors.grey[300]!, blurRadius: 10, offset: Offset(3, 3))],
            ),
            child: Column(
              children: <Widget>[
                SizedBox(
                  height: 50,
                ),
                Text(
                  Config().appName,
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
                ),
                Text(
                  'Welcome to Admin Panel',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                SizedBox(
                  height: 50,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 40, right: 40),
                  child: Form(
                      key: formKey,
                      child: TextFormField(
                        controller: passwordCtrl,
                        obscureText: true,
                        decoration: InputDecoration(
                            hintText: 'Enter Password',
                            border: OutlineInputBorder(),
                            labelText: 'Password',
                            contentPadding: EdgeInsets.only(right: 0, left: 10),
                            suffixIcon: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: CircleAvatar(
                                radius: 15,
                                backgroundColor: Colors.grey[300],
                                child: IconButton(
                                    icon: Icon(Icons.close, size: 15),
                                    onPressed: () {
                                      passwordCtrl.clear();
                                    }),
                              ),
                            )),
                        validator: (String? value) {
                          String? _adminPassword = ab.adminPass;
                          if (value!.length == 0)
                            return "Password can't be empty";
                          else if (value != _adminPassword && value != Config().testerPassword) return 'Wrong Password! Please try again.';

                          return null;
                        },
                        onChanged: (String value) {
                          setState(() {
                            password = value;
                          });
                        },
                      )),
                ),
                SizedBox(
                  height: 30,
                ),
                Container(
                  height: 45,
                  width: 200,
                  decoration: BoxDecoration(
                      color: Colors.deepPurpleAccent,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: <BoxShadow>[BoxShadow(color: Colors.grey[400]!, blurRadius: 10, offset: Offset(2, 2))]),
                  child: TextButton.icon(
                    style: ButtonStyle(
                        shape: WidgetStateProperty.resolveWith((states) => RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)))),
                    icon: Icon(
                      LineIcons.arrowRight,
                      color: Colors.white,
                      size: 25,
                    ),
                    label: Text(
                      'Sign In',
                      style: TextStyle(fontWeight: FontWeight.w400, color: Colors.white, fontSize: 16),
                    ),
                    onPressed: () => handleSignIn(),
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}
