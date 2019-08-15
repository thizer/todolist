import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:ini/ini.dart';

import 'application.dart';

class TodoList {

  final ArgResults args;

  String savePath;

  Config config;

  /// Json Obj file content
  var database;

  TodoList(this.args) {

    init();
    openDatabase();

    if (checkArg(args[LIST])) {
      this.list();

    } else if (checkArg(args[ADD])) {
      this.add();

    } else if (checkArg(args[REMOVE])) {
      this.remove();

    } else if (checkArg(args[MOVE])) {
      this.move();

    } else {
      throw Exception('Não tenho bola de cristal, brod...');
    }
  }

  void init([String newSavePath]) {

    // @todo Verificar este parametro opcional para trocar o savepath

    // Determina o caminho para a pasta home do usuario
    String homePath = getHomePath();

    // Tenta abrir arquivo .todolist na home do usuario (se nao existir tenta criar)
    File configFile = File("$homePath/.todolist");
    if (!configFile.existsSync()) {

      // Cria arquivo e inclui o savepath
      configFile.createSync();
      configFile.writeAsStringSync("savepath=$homePath");
      this.savePath = homePath;
    }

    var lines = configFile.readAsLinesSync();
    this.config = Config.fromStrings(lines);
    
    // Determina onde salvar o arquivo de banco de dados
    this.savePath = this.savePath ?? config.get('default', 'savepath');
  }

  void openDatabase() {

    // Here we open or create the json database file

  }

  void add() {
    var content = [
      {
        'default': {
          'a7sdf87a5sd': 'Primeira nota',
          'a90sdf0a98': 'Segunda nota',
        },
        'marco': {
          'df87a5sd': 'Uma tarefa especifica',
        }
      }
    ];

    var encoded = jsonEncode(content);

    print(encoded);

    print(jsonDecode(encoded));
  }

  void remove() {
    print('remove');
  }

  void move() {
    print('move');
  }

  void list() {
    print('list');
  }

}
