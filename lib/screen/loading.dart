import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
class Loading extends StatelessWidget {
  const Loading({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.brown.shade100,
      alignment: Alignment.center,
      padding: EdgeInsets.all(24),
      child: SpinKitCubeGrid(
        color: Colors.brown.shade400,
        size: 50,
      ),
    );
  }
}