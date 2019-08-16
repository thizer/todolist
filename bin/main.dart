import 'dart:io';
import 'dart:mirrors';

import 'package:args/args.dart';
import 'package:todolist/todolist.dart';
import 'package:todolist/application.dart';

main(List<String> args) {
  
  ArgParser parser = ArgParser();

  parser.addFlag(HELP, abbr: 'h', defaultsTo: false, negatable: false);
  parser.addFlag(LIST, abbr: 'l', defaultsTo: false, negatable: false, help: 'Listar tarefas');
  parser.addOption(ADD, abbr: 'a', help: 'Adicionar tarefa');
  parser.addOption(REMOVE, abbr: 'd', help: 'Remover uma tarefa');
  parser.addOption(MOVE, abbr: 'm', help: 'Trocar grupo de uma tarefa');
  parser.addOption(GROUP, abbr: 'g', defaultsTo: 'default', help: 'Informa o grupo onde listar ou adicionar');
  parser.addOption(STATUS, abbr: 's', allowed: ['new', 'doing', 'done'], defaultsTo: 'new', help: 'Modifica o status da tarefa');
  parser.addOption(GROUP_NAME, help: 'Um nome para adicionar suas tarefas pessoais');
  parser.addOption(JSON_DB, valueHelp: 'json filename', help: 'Aponta onde salvar as tarefas (Arquivo JSON)');

  try {

    if (!Platform.isLinux) {
      throw Exception('Não sei o que fazer.. Nunca cheguei nessa parte =S');
    }

    // Quando nao for informado nenhum parametro forcamos uma lista
    if (args.isEmpty) {

      args = List<String>();
      args.add("--list");
    }

    ArgResults results = parser.parse(args);

    // O cara so quer ajuda
    if (results[HELP]) {
      print(parser.usage);
      exit(0);
    }

    // Inicia o programa de fato
    TodoList(results);

  } on Exception catch (e) {

    print(e);
    print(parser.usage);
    exit(1);
  }
}        
