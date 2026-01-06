import 'package:flutter/material.dart';
import 'package:flutter_coffee_app/home/brew_list.dart';
import 'package:flutter_coffee_app/home/settings_form.dart';
import 'package:flutter_coffee_app/model/brew_model.dart';
import 'package:flutter_coffee_app/services/auth.dart';
import 'package:flutter_coffee_app/services/database.dart';
import 'package:provider/provider.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bottomsheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 20, horizontal: 60),
              child: SettingsForm(),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamProvider<List<Brew>>.value(
      value: DatabaseService().brews,
      initialData: [],
      child: Scaffold(
        backgroundColor: Colors.brown.shade100,
        appBar: AppBar(
          backgroundColor: Colors.brown.shade400,
          centerTitle: true,
          elevation: 0,
          title: Text('Coffee App'),
          actions: [
            TextButton.icon(
              onPressed: () async {
                await AuthServices().logout();
              },
              label: Text('LogOut', style: TextStyle(color: Colors.black)),
              icon: Icon(Icons.person, color: Colors.black),
            ),
            TextButton.icon(
              onPressed: bottomsheet,
              label: Text('settings', style: TextStyle(color: Colors.black)),
              icon: Icon(Icons.settings, color: Colors.black),
            ),
          ],
        ),
        body: BrewList(),
      ),
    );
  }
}
