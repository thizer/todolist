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
  ArgParser parser;
  ArgResults args;

  JsonEncoder jsonEncoder;
  JsonDecoder jsonDecoder;

  String jsonDbFile;

  Config config;

  /// Json Obj file content
  Database database;

  TodoList(this.args, this.parser) {
    // This is the object that transform objects to pretty json strings
    jsonEncoder = JsonEncoder.withIndent('  ');

    String newJsonDb = checkArg(args[JSON_DB]) ? args[JSON_DB] : null;
    String groupName = checkArg(args[GROUP_NAME]) ? args[GROUP_NAME] : null;

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

    if (args[ABOUT]) {
      print(Colorize(textCenter('------------------------------'))..lightBlue());
      print(Colorize(textCenter('TodoList - Sobre este Software') + '\n')..lightBlue());
      print(textCenter('-------------------------------------'));
      print('Crie listas de tarefas separadas por grupos (usuários)');
      print('Defina prioridades para executar primeiro o que é mais importante');
      print('Utilize os status [new, doing, done] para manter seus parceiros informados');
      print(textCenter('-------------------------------------'));
      print('A maneira mais pratica de controlar suas tarefas sem perder tempo');

      print('\nVerifique abaixo informações sobre a atual configuração:');
      print('Config file = ' + getHomePath() + '/.todolist');
      for (var i in config.items('default')) {
        print(i.first + ' = ' + i.last);
      }
      print(Colorize('\n' + textCenter('THIZER® - www.thizer.com') + '\n')
        ..white()
        ..bgBlack());
      exit(0);
    }

    if (checkArg(args[LIST])) {
      list();
    } else if (checkArg(args[ADD])) {
      add();
    } else if (checkArg(args[REMOVE])) {
      remove();
    } else if (checkArg(args[MOVE])) {
      move();
    } else if (checkArg(args[STATUS])) {
      status();
    } else if (checkArg(args[PRIORITY])) {
      priority();
    } else if (checkArg(args[REMOVE_GROUP])) {
      removeGroup();
    } else {
      if (newJsonDb == null && groupName == null) {
        throw Exception('Não tenho bola de cristal, brod...');
      }
    }

    // No final de toda execussao persiste
    // as alteracoes no banco de dados (arquivo json)
    saveDatabase();
  }

  void init({String newJsonDb, String groupName}) {
    // Determina o caminho para a pasta home do usuario
    var homePath = getHomePath();
    var userName = getUsername();

    // Tenta abrir arquivo .todolist na home do usuario (se nao existir tenta criar)
    var configFile = File('$homePath/.todolist');
    if (!configFile.existsSync()) {
      var defaultContent = (newJsonDb == null) ? 'jsondbfile=$homePath/todolist.json\n' : 'jsondbfile=$newJsonDb\n';
      defaultContent += (groupName == null) ? 'groupname=$userName\n' : 'groupname=$groupName\n';

      // Cria arquivo e inclui o newJsonDb
      configFile.createSync();
      configFile.writeAsStringSync(defaultContent);
    }

    // Abre o arquivo em modo INI
    var lines = configFile.readAsLinesSync();
    config = Config.fromStrings(lines);

    // Troca newJsonDb caso tenha sido informado
    if (newJsonDb != null && newJsonDb.isNotEmpty) {
      config.set('default', 'jsondbfile', newJsonDb);

      // Salva alteracao
      configFile.writeAsStringSync(config.toString());
    }

    // Troca o nome do grupo do usuario 'logado'
    if (groupName != null && groupName.isNotEmpty) {
      config.set('default', 'groupname', groupName);

      // Salva alteracao
      configFile.writeAsStringSync(config.toString());

      // Determina onde salvar o arquivo de banco de dados
      jsonDbFile = config.get('default', 'jsondbfile');

      // Abre base de dados para criar o grupo
      openDatabase();

      var groupExists = false;
      for (var group in database.group) {
        if (group.name == groupName) {
          groupExists = true;
          break;
        }
      }

      if (!groupExists) {
        // Grupo ainda nao existe, cria
        database.group.add(Group(groupName, <Task>[]));

        // Persiste
        saveDatabase();
      }

      list();
    } else {
      // Determina onde salvar o arquivo de banco de dados
      jsonDbFile = config.get('default', 'jsondbfile');
    }
  }

  void openDatabase() {
    // Here we open or create the json database file
    var jsonDb = File(jsonDbFile);

    // Se o arquivo de banco de dados nao existir vamos cria-lo
    if (!jsonDb.existsSync()) {
      // Cria configuracao absolutamente basica do json
      var groups = <Group>[];
      groups.add(Group('default', <Task>[]));
      var defaultContent = Database(groups).toJson();

      // Salva essa estrutura minimalista no arquivo
      jsonDb.createSync();
      jsonDb.writeAsStringSync(jsonEncoder.convert(defaultContent));
    }

    // Efetua a leitura desse arquivo de banco de dados faz o parse de json
    var jsonDbContent = jsonDb.readAsStringSync();
    database = Database.fromJson(jsonDecode(jsonDbContent));
  }

  void saveDatabase() {
    if (database == null) {
      return;
    }

    // transforma classe Database em json
    var dbContents = jsonEncoder.convert(database.toJson());

    // Salva o arquivo
    var jsonDb = File(jsonDbFile);
    jsonDb.writeAsStringSync(dbContents);
  }

  void add() {
    // Cria uma tarefa novinha
    var group = getOrCreateGroup(args[GROUP]);
    group.tasks
        .add(Task(args[ADD], args.rest.join(' '), config.get('default', 'groupname').toString(), checkArg(args[PRIORITY]) ? int.parse(args[PRIORITY]) : 3));

    list();
  }

  void remove() {
    // Loop sobre todos os grupos
    for (var group in database.group) {
      var task = group.find(args[REMOVE]);
      if (task != null) {
        group.tasks.remove(task);
        break;
      } else {
        print(Colorize("\nTarefa '${args[REMOVE]}' não encontrada. Talvez já tenha sido apagada\n")..lightYellow());
      }
    }

    list();
  }

  void move() {
    if (!checkArg(args[GROUP]) && args.rest.isEmpty) {
      throw ArgParserException('Ué, você não informou o grupo para onde quer mover');
    }

    // O cara pode passar o nome do outro grupo com ou sem o '-g'
    String newGroupname = (args.rest.isNotEmpty) ? args.rest.first : args[GROUP];

    var found = false;

    // Loop sobre todos os grupos
    for (var group in database.group) {
      var task = group.find(args[MOVE]);
      if (task != null) {
        // Encontrou, remove e marca como encontrado
        group.tasks.remove(task);

        // Adiciona no novo grupo
        var newGroup = getOrCreateGroup(newGroupname);
        newGroup.tasks.add(task);

        found = true;

        // Refatora argumentos adicionando o grupo que foi
        // alterado, para listar as tarefas deste grupo

        var arguments = <String>[];
        arguments.addAll(['--$GROUP', newGroupname]);

        var results = parser.parse(arguments);
        args = results;

        break;
      }
    }

    if (!found) {
      print(Colorize("\nTarefa '${args[MOVE]}' não encontrada. Talvez tenha sido apagada\n")..lightYellow());
    }

    list();
  }

  void list() {
    if (args[ALL]) {
      // Mostrar todas as tarefas, de todo mundo
      for (var group in database.group) {
        imprimeTarefas(group);
      }
    } else {
      if (args[GROUP] != 'default') {
        var group = database.find(args[GROUP]);

        if (group == null) {
          print(Colorize("\nO grupo '${args[GROUP]}' não foi encontrado. Digitou errado?\n")..lightYellow());
          list();
          exit(0);
        }

        // Se nao foi encontrado o grupo, nem chegara aqui
        imprimeTarefas(group);
      } else {
        // Grupo do usuario
        var userGroup = database.find(config.get('default', 'groupname'));
        if (userGroup != null) {
          imprimeTarefas(userGroup);
        }

        // Grupo default
        var defaultGroup = database.find('default');
        if (defaultGroup != null) {
          imprimeTarefas(defaultGroup);
        }
      } // endelse
    } // endelse
    print('');
  }

  void status() {
    if (args.rest.isEmpty) {
      throw ArgParserException('Informe o id da tarefa que deseja alterar');
    }

    var found = false;

    // Loop sobre todos os grupos
    for (var group in database.group) {
      // Procura pela tarefa
      var task = group.find(args.rest.first);
      if (task != null) {
        task.status = args[STATUS];
        found = true;

        // Refatora argumentos adicionando o grupo que foi
        // alterado, para listar as tarefas deste grupo

        var arguments = <String>[];
        arguments.addAll(['--$GROUP', group.name]);

        var results = parser.parse(arguments);
        args = results;

        break;
      }
    }

    if (!found) {
      print(Colorize("\nTarefa '${args.rest.first}' não encontrada. Talvez tenha sido apagada\n")..lightYellow());
    }

    list();
  }

  void priority() {
    if (args.rest.isEmpty) {
      throw ArgParserException('Informe o id da tarefa que deseja alterar');
    }

    var tlatePrior = {'urg': 1, 'med': 2, 'low': 3};
    var found = false;

    // Loop sobre todos os grupos
    for (var group in database.group) {
      // Procura pela tarefa
      var task = group.find(args.rest.first);
      if (task != null) {
        task.priority = tlatePrior[args[PRIORITY]];
        found = true;

        // Refatora argumentos adicionando o grupo que foi
        // alterado, para listar as tarefas deste grupo

        var arguments = <String>[];
        arguments.addAll(['--$GROUP', group.name]);

        var results = parser.parse(arguments);
        args = results;

        break;
      }
    }

    if (!found) {
      print(Colorize("\nTarefa '${args.rest.first}' não encontrada. Talvez tenha sido apagada\n")..lightYellow());
    }

    list();
  }

  void removeGroup() {
    if (args[REMOVE_GROUP] == 'default') {
      throw ArgParserException("Ahh vai cagá... O grupo 'default' não pode ser removido");
    }

    // Busca grupo de origem
    var source = database.find(args[REMOVE_GROUP]);
    if (source == null) {
      print(Colorize("\nGrupo '${args[REMOVE_GROUP]}' não encontrado. Talvez já tenha sido apagado\n")..lightYellow());
      exit(0);
    }

    // Grupo destino default sempre existira
    var target = database.find('default');

    // Transfere todas as tarefas para la
    target.tasks.addAll(source.tasks);

    // Apaga grupo
    database.group.remove(source);

    list();
  }

  void imprimeTarefas(Group group, [bool compact = false]) {
    var df = DateFormat('yyyy-MM-dd H:mm');
    print(Colorize(textCenter(' + ${group.name} + ', maxlen: 70, padding: '-'))..lightBlue());

    if (group.tasks.isEmpty) {
      print(textCenter('Cidadão na maciota', maxlen: 70));
      print('');
      return;
    }

    // Ordena por prioridade
    group.tasks.sort(sortTasks);

    for (var task in group.tasks) {
      // Mostra 'icone' de acordo com status da tarefa
      String status;
      switch (task.status) {
        case 'new':
          status = '(```)';
          break;
        case 'doing':
          status = '(~~~)';
          break;
        case 'done':
          status = '(xxx)';
          break;
      }

      Colorize priority;

      var tlatePrior = {1: '[URG]', 2: '[MED]', 3: '[LOW]'};
      var priorityName = Colorize(tlatePrior[task.priority])..bgBlack();

      if (task.status == 'done') {
        priority = Colorize(status)
          ..bgBlack()
          ..darkGray();
      } else {
        switch (task.priority) {
          case 1:
            priority = Colorize(status)
              ..bgBlack()
              ..lightRed();
            priorityName..lightRed();
            break;
          case 2:
            priority = Colorize(status)
              ..bgBlack()
              ..yellow();
            priorityName..yellow();
            break;
          case 3:
            priority = Colorize(status)
              ..bgBlack()
              ..green();
            priorityName..green();
            break;
        }
      }

      // Prepara descricao e depois printa a tarefa em si
      var desc = Colorize((task.description.isNotEmpty) ? '${task.description}' : '...');
      (task.status == 'done') ? (desc..darkGray()) : (desc..lightBlue()); // Cor dependendo do status

      var taskid = Colorize('${task.id}')
        ..bgBlack()
        ..lightGray()
        ..bold();
      var title = Colorize('${task.title}')..lightGray();
      var header = Colorize('Em ${df.format(task.created)} por ${task.author}')..darkGray();

      if (args[COMPACT]) {
        // Imprime normal
        print(' $priority $taskid $title');
      } else {
        // Imprime normal
        print(' $taskid $title\n $priorityName $header\n $priority $desc');
      }
    }
  }

  Group getOrCreateGroup(String name) {
    Group result;
    var found = false;

    // Procura pelo grupo na lista
    for (var group in database.group) {
      if (group.name == name) {
        result = group;
        found = true;
        break;
      }
    }

    // Nao achou, cria, adiciona na lista e retorna
    if (!found) {
      result = Group(name, <Task>[]);
      database.group.add(result);
    }

    return result;
  }

  ///
  /// Efetiva uma ordenacao entre as tarefas de acordo com nossos proprios criterios
  ///
  /// [Task a] this
  /// [Task b] other
  ///
  /// Quando this < other retorna -1;
  /// Quando iguais retorna 0;
  /// Quando this > other retorna 1;
  int sortTasks(Task a, Task b) {
    var result = 0;

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
  }
}
