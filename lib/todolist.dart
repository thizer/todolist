import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';

import 'package:args/args.dart';
import 'package:ini/ini.dart';
import 'package:todolist/model/database.dart';
import 'package:todolist/model/group.dart';
import 'package:todolist/model/task.dart';

import 'application.dart';

class TodoList {

  final ArgResults args;

  JsonEncoder jsonEncoder;
  JsonDecoder jsonDecoder;

  String jsonDbFile;

  Config config;

  /// Json Obj file content
  Database database;

  TodoList(this.args) {

    // This is the object that transform objects to pretty json strings
    jsonEncoder = JsonEncoder.withIndent('  ');

    String newJsonDb = checkArg(this.args[JSON_DB]) ? this.args[JSON_DB] : null;
    String groupName = checkArg(this.args[GROUP_NAME]) ? this.args[GROUP_NAME] : null;
    
    // Quando troca o arquivo database json o sistema termina
    if (newJsonDb != null && newJsonDb.isNotEmpty) {

      if (!newJsonDb.endsWith('.json')) {
        throw FormatException('--jsondb Deve ser o caminho para um arquivo json. Se não existir o sistema tentará criá-lo.');
      }

      init(newJsonDb: newJsonDb, groupName: groupName);
      exit(0);
    }

    init(groupName: groupName);
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

    saveDatabase();
  }

  void init({ String newJsonDb, String groupName }) {

    // Determina o caminho para a pasta home do usuario
    String homePath = getHomePath();
    String userName = getUsername();

    // Tenta abrir arquivo .todolist na home do usuario (se nao existir tenta criar)
    File configFile = File("$homePath/.todolist");
    if (!configFile.existsSync()) {

      String defaultContent = (newJsonDb == null) ? "jsondbfile=$homePath/todolist.json\n" : "jsondbfile=$newJsonDb\n";
      defaultContent += (groupName == null) ? "groupname=$userName\n" : "groupname=$groupName\n";
      
      // Cria arquivo e inclui o newJsonDb
      configFile.createSync();
      configFile.writeAsStringSync(defaultContent);
    }

    // Abre o arquivo em modo INI
    var lines = configFile.readAsLinesSync();
    this.config = Config.fromStrings(lines);
    
    // Troca newJsonDb caso tenha sido informado
    if (newJsonDb != null && newJsonDb.isNotEmpty) {
      this.config.set('default', 'jsondbfile', newJsonDb);

      // Salva alteracao
      configFile.writeAsStringSync(this.config.toString());
    }

    // Troca o nome do grupo do usuario 'logado'
    if (groupName != null && groupName.isNotEmpty) {
      this.config.set('default', 'groupname', groupName);

      // Salva alteracao
      configFile.writeAsStringSync(this.config.toString());
    }

    // Determina onde salvar o arquivo de banco de dados
    this.jsonDbFile = config.get('default', 'jsondbfile');
  }

  void openDatabase() {

    // Here we open or create the json database file
    File jsonDb = File(this.jsonDbFile);

    // Se o arquivo de banco de dados nao existir vamos cria-lo
    if (!jsonDb.existsSync()) {

      // Cria configuracao absolutamente basica do json
      List<Group> groups = List<Group>();
      groups.add(Group('default', List<Task>()));
      Map<String, dynamic> defaultContent = Database(groups).toJson();

      // Salva essa estrutura minimalista no arquivo
      jsonDb.createSync();
      jsonDb.writeAsStringSync(jsonEncoder.convert(defaultContent));
    }

    // Efetua a leitura desse arquivo de banco de dados faz o parse de json
    String jsonDbContent = jsonDb.readAsStringSync();
    this.database = Database.fromJson(jsonDecode(jsonDbContent));
  }

  void saveDatabase() {
    if (this.database == null) {
      return;
    }

    // transforma classe Database em json
    String dbContents = jsonEncoder.convert(this.database.toJson());

    // Salva o arquivo
    File jsonDb = File(this.jsonDbFile);
    jsonDb.writeAsStringSync(dbContents);
  }

  void add() {
    Group group = getOrCreateGroup(this.args[GROUP]);
    group.tasks.add(Task(this.args[ADD], this.args.rest.join(' '), DateTime.now(), 'new'));

    this.list();
  }

  void remove() {
    print('remove');
  }

  void move()  {
    print('move');
  }

  void list() {
    
    DateFormat df = DateFormat('yyyy-MM-dd');

    for (Group group in this.database.group) {
      if (group.name == 'default' || group.name == config.get('default', 'groupname')) {
        print("----------------${group.name}-----------------------------");
        
        for (Task task in group.tasks) {

          String status;

          switch (task.status) {
            case 'new': status = '[ ]'; break;
            case 'doing': status = '[-]'; break;
            case 'done': status = '[x]'; break;
          }

          String desc = (task.description.isNotEmpty) ? '\n    \"${task.description}\"\n' : '\n';

          print("$status #${task.id} ${df.format(task.created)} - ${task.title}"+desc);
        }
      }
    }

    // print("\nConfigurações");
    // print("Config file = "+getHomePath()+"/.todolist");
    // for (var i in config.items('default')) {
    //   print(i.first+" = "+i.last);
    // }
  }

  Group getOrCreateGroup(String name) {
    Group result;
    bool found = false;

    // Procura pelo grupo na lista
    for (Group group in this.database.group) {
      if (group.name == name) {
        result = group;
        found = true;
        break;
      }
    }

    // Nao achou, cria, adiciona na lista e retorna
    if (!found) {
      result = Group(name, List<Task>());
      this.database.group.add(result);
    }

    return result;
  }

}
