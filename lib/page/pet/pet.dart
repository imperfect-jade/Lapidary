import 'package:flutter/material.dart';
//宠物页面
class PetPage extends StatefulWidget {
  PetPage({Key? key}) : super(key: key);

  @override
  _PetPageState createState() => _PetPageState();
}

class _PetPageState extends State<PetPage> {
  @override
  Widget build(BuildContext context) {
    return Container(
       child: Text("宠物"),
    );
  }
}