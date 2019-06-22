import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  TextEditingController _todoController = TextEditingController();

  List _todoList = [];
  Map<String, dynamic> _lastRemoved;
  int _lastRemovedPosition;

  @override
  void initState() {
    _readData().then((data) {
      setState(() {
        _todoList = json.decode(data);
      });
    });
  }

  Future<File> _getFile() async {
    final Directory directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/todo_data.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(_todoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }

  Widget _buildItem(BuildContext context, int index) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      direction: DismissDirection.startToEnd,
      onDismissed: (direction) {
        setState(() {
          _lastRemoved = Map.from(_todoList[index]);
          _lastRemovedPosition = index;
          _todoList.removeAt(index);
          _saveData();
        });
        final snack = SnackBar(
          content: Text("tarefa \"${_lastRemoved["title"]}\" removida."),
          action: SnackBarAction(
            label: "Desfazer",
            onPressed: () {
              setState(() {
                _todoList.insert(_lastRemovedPosition, _lastRemoved);
              });
            },
          ),
          duration: Duration(seconds: 4),
        );
        Scaffold.of(context).removeCurrentSnackBar();
        Scaffold.of(context).showSnackBar(snack);
      },
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
      child: CheckboxListTile(
        title: Text(
          _todoList[index]["title"],
          style: TextStyle(
              decoration: _todoList[index]["finished"]
                  ? TextDecoration.lineThrough
                  : null),
        ),
        subtitle: Text(
            _todoList[index]["finished"] ? "Tarefa concluida" : "Pendente"),
        value: _todoList[index]["finished"],
        onChanged: (checked) {
          setState(() {
            _todoList[index]["finished"] = checked;
            _saveData();
          });
        },
        secondary: CircleAvatar(
          child: Icon(_todoList[index]["finished"] ? Icons.check : Icons.error),
        ),
      ),
    );
  }

  Future<Null> _refresh() async {
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _todoList.sort((bubbleOne, bubbleTwo) {
        if (bubbleOne["finished"] && !bubbleTwo["finished"])
          return 1;
        else if (!bubbleOne["finished"] && bubbleTwo["finished"])
          return -1;
        else
          return 0;
      });
    });
    _saveData();
    return null;
  }

  void _addTodo() {
    setState(() {
      Map<String, dynamic> newTodo = Map();
      newTodo["title"] = _todoController.text;
      _todoController.text = "";

      newTodo["finished"] = false;

      _todoList.add(newTodo);
      _saveData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de tarefas"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(8, 1, 8, 1),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _todoController,
                    decoration: InputDecoration(
                        labelText: "Nova Tarefa",
                        labelStyle: TextStyle(color: Colors.blueAccent)),
                  ),
                ),
                RaisedButton(
                  color: Colors.blueAccent,
                  child: Text("Add"),
                  textColor: Colors.white,
                  onPressed: () {
                    _addTodo();
                  },
                )
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              child: ListView.builder(
                  padding: EdgeInsets.only(top: 8),
                  itemCount: _todoList.length,
                  itemBuilder: _buildItem),
              onRefresh: _refresh,
            ),
          )
        ],
      ),
    );
  }
}
