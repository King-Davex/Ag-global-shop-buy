import 'package:flutter/material.dart';
import 'package:flutter_coffee_app/model/brew_model.dart';
import 'package:provider/provider.dart';
class BrewList extends StatefulWidget {
  const BrewList({super.key});

  @override
  State<BrewList> createState() => _BrewListState();
}

class _BrewListState extends State<BrewList> {
  @override
  Widget build(BuildContext context) {
    final brew = Provider.of<List<Brew>>(context);
    
    return ListView.builder(
      itemCount: brew.length,
      itemBuilder: (context, index) {
       
        return Card(
            child: ListTile(
              leading: CircleAvatar(
                radius: 25,
                 backgroundColor:Colors.brown[brew[index].strenght as int],
                
              ),
              title: Text(brew[index].name as String),
              subtitle: Text(brew[index].sugar as String),
              ),

              
            
        );
      },
     
    );
  }
}