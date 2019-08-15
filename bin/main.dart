import 'dart:io';

import 'package:args/args.dart';
import 'package:todolist/todolist.dart';
import 'package:todolist/application.dart';

main(List<String> args) {
  
  ArgParser parser = ArgParser();

  parser.addFlag(HELP, abbr: 'h', defaultsTo: false, negatable: false);
  parser.addFlag(LIST, abbr: 'l', defaultsTo: false, negatable: false, help: 'Listar tarefas');
  parser.addOption(GROUP, abbr: 'g', help: 'Informa o grupo onde listar ou adicionar');
  parser.addOption(ADD, abbr: 'a', help: 'Adicionar tarefa');
  parser.addOption(REMOVE, abbr: 'd', help: 'Remover uma tarefa');
  parser.addOption(MOVE, abbr: 'm', help: 'Trocar grupo de uma tarefa');
  parser.addOption('set-folder', valueHelp: 'path', help: 'Aponta onde salvar as tarefas (json database file)');

  try {

    if (!Platform.isLinux) {
      throw Exception('Não sei o que fazer.. Nunca cheguei nessa parte =S');
    }

    ArgResults results = parser.parse(args);

    // O cara so quer ajuda
    if (args.isEmpty || results[HELP]) {
      print(parser.usage);
      exit(0);
    }

    // Inicia o programa de fato
    TodoList(results);

  } catch (e) {
    print(e.toString());
    print(parser.usage);
    exit(1);
  }
}        
