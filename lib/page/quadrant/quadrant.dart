import 'package:flutter/material.dart';
//四象限页面
class QuadrantPage extends StatefulWidget {
  QuadrantPage({Key? key}) : super(key: key);

  @override
  _QuadrantPageState createState() => _QuadrantPageState();
}

class _QuadrantPageState extends State<QuadrantPage> {
  @override
  Widget build(BuildContext context) {
    return Container(
       child: Text("四象限"),
    );
  }
}