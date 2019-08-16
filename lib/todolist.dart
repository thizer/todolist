import 'dart:convert';
import 'dart:io';
import 'package:colorize/colorize.dart';
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

    if (this.args[ABOUT]) {

      print(Colorize("\nSobre este Software\n")..lightBlue());
      print("Config file = "+getHomePath()+"/.todolist");
      for (var i in config.items('default')) {
        print(i.first+" = "+i.last);
      }
      print(Colorize("\nTodoList por Thizer\n")..white()..bgBlack());
      exit(0);
    }

    if (checkArg(this.args[LIST])) {
      this.list();

    } else if (checkArg(this.args[ADD])) {
      this.add();

    } else if (checkArg(this.args[REMOVE])) {
      this.remove();

    } else if (checkArg(this.args[MOVE])) {
      this.move();
      
    } else if (checkArg(this.args[STATUS])) {
      this.status();

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
    group.tasks.add(Task(
      this.args[ADD],
      this.args.rest.join(' '),
      config.get('default', 'groupname').toString(),
      2
    ));

    this.list();
  }

  void remove() {
    
    bool found = false;

    // Loop sobre todos os grupos
    for (Group group in this.database.group) {
      
      // Loop sobre as tarefas do grupo
      for (Task task in group.tasks) {
        if (task.id == this.args[REMOVE]) {

          // Encontrou, remove e marca como encontrado
          group.tasks.remove(task);
          found = true;
          break;
        }
      }
    }

    if (!found) {
      print(Colorize("\nTarefa '${this.args[REMOVE]}' não encontrada. Talvez já tenha sido apagada\n")..lightYellow());
    }

    list();
  }

  void move()  {
    bool found = false;

    // Loop sobre todos os grupos
    for (Group group in this.database.group) {
      
      // Loop sobre as tarefas do grupo
      for (Task task in group.tasks) {
        if (task.id == this.args[MOVE]) {

          // Encontrou, remove e marca como encontrado
          group.tasks.remove(task);

          // Adiciona no novo grupo
          Group newGroup = getOrCreateGroup(this.args[GROUP]);
          newGroup.tasks.add(task);

          found = true;
          break;
        }
      }
    }

    if (!found) {
      print(Colorize("\nTarefa '${this.args[REMOVE]}' não encontrada. Talvez tenha sido apagada\n")..lightYellow());
    }

    list();
  }

  void list() {

    if (this.args[ALL]) {

      // Mostrar todas as tarefas, de todo mundo
      for (Group group in this.database.group) {
        imprimeTarefas(group);
      }

    } else {

      if (this.args[GROUP] != 'default') {

        // Foi informado o grupo onde listar as tarefas
        for (Group group in this.database.group) {
          if (group.name == this.args[GROUP]) {
            imprimeTarefas(group);
            break;
          }
        } 
      } else {

        // Não foi informado grupo onde listar as tarefas então listamos
        // as tarefas default e as do proprio usuario
        for (Group group in this.database.group) {
          if (group.name == 'default' || group.name == config.get('default', 'groupname')) {
            imprimeTarefas(group);
          }
        }

      } // endelse
    } // endelse
  }

  void status() {
    if (this.args.rest.isEmpty) {
      throw FormatException('Informe o id da tarefa que deseja alterar');
    }

    bool found = false;

    // Loop sobre todos os grupos
    for (Group group in this.database.group) {
      
      // Loop sobre as tarefas do grupo
      for (Task task in group.tasks) {
        if (task.id == this.args.rest.first) {

          task.status = this.args[STATUS];
          found = true;
          break;
        }
      }
    }

    if (!found) {
      print(Colorize("\nTarefa '${this.args[REMOVE]}' não encontrada. Talvez tenha sido apagada\n")..lightYellow());
    }

    list();
  }

  void imprimeTarefas(Group group) {

    DateFormat df = DateFormat('yyyy-MM-dd');
    print("\n----------------------------- "+(Colorize(group.name)..lightBlue()).toString()+" -----------------------------");

    // Ordena por prioridade
    group.tasks.sort((a,b) {
      return a.priority.compareTo(b.priority);
    });

    for (Task task in group.tasks) {

      // Mostra 'icone' de acordo com status da tarefa
      Colorize status;
      switch (task.status) {
        case 'new': status = Colorize('[ ]')..lightYellow(); break;
        case 'doing': status = Colorize('[-]')..lightRed(); break;
        case 'done': status = Colorize('[x]'); break;
      }

      Colorize priority;
      switch (task.priority) {
        case 1: priority = Colorize('*')..bgBlack()..lightRed(); break;
        case 2: priority = Colorize('*')..bgBlack()..lightGray(); break;
        case 3: priority = Colorize('*')..bgBlack()..lightGreen(); break;
      }

      // Prepara descricao e depois printa a tarefa em si
      String desc = (task.description.isNotEmpty) ? '    ${task.description}\n' : '';
      Colorize title = Colorize("${task.title}")..lightGray();
      print("$status ${priority} ${title}\n    ${task.id} ${df.format(task.created)} - Author: ${task.author}\n"+desc);
    }
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
