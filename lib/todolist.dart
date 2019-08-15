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

    String setFolder = checkArg(this.args[SET_FOLDER]) ? this.args[SET_FOLDER] : null;
    
    init(setFolder);

    // Quando troca o savepath o sistema termina
    // @todo nao ta funcionando essa bixiga... ¬¬
    if (setFolder != null && setFolder.isNotEmpty) {
      exit(0);
    }

    openDatabase();

    if (checkArg(this.args[LIST])) {
      this.list();

    } else if (checkArg(this.args[ADD])) {
      this.add();

    } else if (checkArg(this.args[REMOVE])) {
      this.remove();

    } else if (checkArg(this.args[MOVE])) {
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
      configFile.writeAsStringSync((newSavePath == null) ? "savepath=$homePath" : "savepath=$newSavePath");
    }

    var lines = configFile.readAsLinesSync();
    this.config = Config.fromStrings(lines);
    
    // Troca savepath caso tenha sido informado
    if (newSavePath != null && newSavePath.isNotEmpty) {
      this.config.set('default', 'savepath', newSavePath);

      // Salva alteracao
      configFile.writeAsStringSync(this.config.toString());
    }

    // Determina onde salvar o arquivo de banco de dados
    this.savePath = config.get('default', 'savepath');
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
    print('Lista de tarefas');

    print('');
    print("Configurações");
    print("Config file = "+getHomePath()+"/.todolist");
    for (var i in config.items('default')) {
      print(i.first+" = "+i.last);
    }
  }

}
