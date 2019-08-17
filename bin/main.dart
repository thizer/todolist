import 'dart:io';

import 'package:args/args.dart';
import 'package:colorize/colorize.dart';
import 'package:todolist/todolist.dart';
import 'package:todolist/application.dart';

main(List<String> args) {
  
  ArgParser parser = ArgParser();

  parser.addFlag(ABOUT, defaultsTo: false, negatable: false, help: 'Exibe informações importantes sobre o aplicativo');
  parser.addFlag(HELP, abbr: 'h', defaultsTo: false, negatable: false);
  parser.addFlag(LIST, abbr: 'l', defaultsTo: false, negatable: false, help: 'Listar tarefas');
  parser.addFlag(ALL, defaultsTo: false, negatable: false, help: 'Exibe todas as tarefas');
  parser.addOption(ADD, abbr: 'a', help: 'Adicionar tarefa');
  parser.addOption(REMOVE, abbr: 'd', help: 'Remover uma tarefa');
  parser.addOption(MOVE, abbr: 'm', help: 'Trocar grupo de uma tarefa');
  parser.addOption(GROUP, abbr: 'g', defaultsTo: 'default', help: 'Informa o grupo onde listar ou adicionar');
  parser.addOption(NEW, help: "Shortcut para '-s new'");
  parser.addOption(DOING, help: "Shortcut para '-s doing'");
  parser.addOption(DONE, help: "Shortcut para '-s help'");
  parser.addOption(STATUS, abbr: 's', allowed: ['new', 'doing', 'done'], help: 'Modifica o status da tarefa');
  parser.addOption(PRIORITY, abbr: 'p', allowed: ['1','2','3'], help: 'Declara a prioridade de uma tarefa onde 1 é mais urgente');
  parser.addOption(REMOVE_GROUP, help: "Transfere todas as tarefas para 'default' e apaga grupo");
  parser.addOption(GROUP_NAME, help: 'Um nome para adicionar suas tarefas pessoais');
  parser.addOption(JSON_DB, valueHelp: 'json filename', help: 'Aponta onde salvar as tarefas (Arquivo JSON)');

  try {

    print("\x1B[2J\x1B[0;0H");

    if (!Platform.isLinux) {
      throw Exception('Não sei o que fazer.. Nunca cheguei nessa parte =S');
    }

    // Quando nao for informado nenhum parametro forcamos uma lista
    if (args.isEmpty) {
      args = List<String>();
      args.add("--$LIST");
    }

    // Efetiva o parse dos argumentos
    ArgResults results = parser.parse(args);

    // Verifica se os atalhos foram definidos, se foram substituimos
    // o results atual para forcar de acordo com o atalho
    if (checkArg(results[ALL])) {
      results = parser.parse(['--$LIST', '--$ALL']);

    } else if (checkArg(results[NEW])) {
      results = parser.parse(['--$STATUS', 'new', results[NEW]]);

    } else if (checkArg(results[DOING])) {
      results = parser.parse(['--$STATUS', 'doing', results[DOING]]);

    } else if (checkArg(results[DONE])) {
      results = parser.parse(['--$STATUS', 'done', results[DONE]]);
    }

    // O cara so quer ajuda
    if (results[HELP]) {
      print(parser.usage);
      exit(0);
    }

    // Inicia o programa de fato
    TodoList(results);

  } catch (e) {

    Colorize msgStyle = Colorize("\n${e.toString()}\n");
    msgStyle.lightYellow();
    msgStyle.italic();

    print(msgStyle);
    print(parser.usage);
    exit(1);
  }
}        
