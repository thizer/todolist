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

      print(Colorize(textCenter("------------------------------"))..lightBlue());
      print(Colorize(textCenter("TodoList - Sobre este Software")+"\n")..lightBlue());
      print(textCenter("-------------------------------------"));
      print("Crie listas de tarefas separadas por grupos (usuários)");
      print("Defina prioridades para executar primeiro o que é mais importante");
      print("Utilize os status [new, doing, done] para manter seus parceiros informados");
      print(textCenter("-------------------------------------"));
      print("A maneira mais pratica de controlar suas tarefas sem perder tempo");

      print("\nVerifique abaixo informações sobre a atual configuração:");
      print("Config file = "+getHomePath()+"/.todolist");
      for (var i in config.items('default')) {
        print(i.first+" = "+i.last);
      }
      print(Colorize("\n"+textCenter("THIZER® - www.thizer.com")+"\n")..white()..bgBlack());
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

    } else if (checkArg(this.args[REMOVE_GROUP])) {
      this.removeGroup();
    } else {
      if (newJsonDb == null && groupName == null) {
        throw Exception('Não tenho bola de cristal, brod...');
      }
    }

    // No final de toda execussao persiste
    // as alteracoes no banco de dados (arquivo json)
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

      // Determina onde salvar o arquivo de banco de dados
      this.jsonDbFile = config.get('default', 'jsondbfile');

      // Abre base de dados para criar o grupo
      openDatabase();

      bool groupExists = false;
      for (Group group in this.database.group) {
        if (group.name == groupName) {
          groupExists = true;
          break;
        }
      }

      if (!groupExists) {

        // Grupo ainda nao existe, cria
        this.database.group.add(Group(groupName, List<Task>()));

        // Persiste
        saveDatabase();
      }

      list();

    } else {
      // Determina onde salvar o arquivo de banco de dados
      this.jsonDbFile = config.get('default', 'jsondbfile');
    }
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

    // Cria uma tarefa novinha
    Group group = getOrCreateGroup(this.args[GROUP]);
    group.tasks.add(Task(
      this.args[ADD],
      this.args.rest.join(' '),
      config.get('default', 'groupname').toString(),
      checkArg(this.args[PRIORITY]) ? int.parse(this.args[PRIORITY]) : 2
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
      if (found) break;
    }

    if (!found) {
      print(Colorize("\nTarefa '${this.args[MOVE]}' não encontrada. Talvez tenha sido apagada\n")..lightYellow());
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

  void removeGroup() {

    if (this.args[REMOVE_GROUP] == 'default') {
      throw Exception("Ahh vai cagá... O grupo 'default' não pode ser removido");
    }

    // Busca grupo de origem
    Group source = this.database.find(this.args[REMOVE_GROUP]);
    if (source == null) {
      print(Colorize("\nGrupo '${this.args[REMOVE_GROUP]}' não encontrado. Talvez já tenha sido apagado\n")..lightYellow());
      exit(0);
    }

    // Grupo destino default sempre existira
    Group target = this.database.find('default');

    // Transfere todas as tarefas para la
    target.tasks.addAll(source.tasks);

    // Apaga grupo
    this.database.group.remove(source);

    list();
  }

  void imprimeTarefas(Group group) {

    DateFormat df = DateFormat('yyyy-MM-dd H:mm');
    print("----------------------------- "+(Colorize(group.name)..lightBlue()).toString()+" -----------------------------");

    // Ordena por prioridade
    group.tasks.sort((a,b) {
      
      int result = 0;

      // As tarefas prontas vao pro final da lista, nao importa a prioridade
      if (a.status == 'done') {
        result = 1;
      } else if (b.status == 'done') {
        result = -1;
      }

      if (result == 0) {

        // Compara por prioridade
        result = a.priority.compareTo(b.priority);

        // Depois por status, caso seja necessario
        if (result == 0) {

          // Sim, poderia estar em outro lugar para usar menos memoria...
          var statuse = {'new': 2, 'doing': 1, 'done': 3};

          // -1 se a < b
          // 0 se iguais
          // 1 se a > b

          if (statuse[a.status] < statuse[b.status]) {
            result = -1;
          } else if (statuse[a.status] > statuse[b.status]) {
            result = 1;
          }

          // O que sobre a gente ordena pela data
          // Mais antigas para cima
          if (result == 0) {
            result = a.created.compareTo(b.created);
          }
        }
      }
      return result;
    });

    for (Task task in group.tasks) {

      // Mostra 'icone' de acordo com status da tarefa
      String status;
      switch (task.status) {
        case 'new':   status = '(   )'; break;
        case 'doing': status = '( ~ )'; break;
        case 'done':  status = '( x )'; break;
      }

      Colorize priority;

      if (task.status == 'done') {
        priority = Colorize(status)..darkGray();
      } else {
        switch (task.priority) {
          case 1: priority = Colorize(status)..bgBlack()..lightRed(); break;
          case 2: priority = Colorize(status)..bgBlack()..yellow(); break;
          case 3: priority = Colorize(status)..bgBlack()..green(); break;
        }
      }

      // Prepara descricao e depois printa a tarefa em si
      Colorize desc = Colorize((task.description.isNotEmpty) ? '    ${task.description}\n' : '')..blue();
      Colorize title = Colorize("${task.title}")..lightGray();
      Colorize header = Colorize("[${task.priority}] ${task.author} em ${df.format(task.created)}\n")..darkGray();
      
      print(" $priority ${task.id} $title\n       $header   $desc");
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
