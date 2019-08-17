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
  parser.addFlag(COMPACT, abbr: 'c', defaultsTo: false, negatable: false, help: 'Exibe as tarefas em modo compacto');
  parser.addOption(ADD, abbr: 'a', help: 'Adicionar tarefa');
  parser.addOption(REMOVE, abbr: 'd', help: 'Remover uma tarefa');
  parser.addOption(MOVE, abbr: 'm', help: 'Trocar grupo de uma tarefa');
  parser.addOption(GROUP, abbr: 'g', defaultsTo: 'default', help: 'Informa o grupo onde listar ou adicionar');
  parser.addOption(NEW, help: "Atalho para '-s new'");
  parser.addOption(DOING, help: "Atalho para '-s doing'");
  parser.addOption(DONE, help: "Atalho para '-s help'");
  parser.addOption(STATUS, abbr: 's', allowed: ['new', 'doing', 'done'], help: 'Modifica o status da tarefa');
  parser.addOption(URG, help: "Atalho para '-p urg'");
  parser.addOption(MED, help: "Atalho para '-p med'");
  parser.addOption(LOW, help: "Atalho para '-p low'");
  parser.addOption(PRIORITY, abbr: 'p', allowed: ['urg','med','low'], help: 'Declara a prioridade de uma tarefa');
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

      List<String> args = List<String>();
      args.addAll(['--$LIST', '--$ALL']);
      if (results[COMPACT]) {
        args.add('--$COMPACT');
      }

      results = parser.parse(args);
    }

    if (results[COMPACT]) {

      // Cria nova lista
      List<String> newArgs = List<String>();
      newArgs.addAll(['--$LIST', '--$COMPACT']);
      
      // Adiciona parametro --all caso seja necessario
      if (results[ALL]) {
        newArgs.add('--$ALL');
      }

      if (results.rest.isNotEmpty) {

        // Se usuario passou um nome usa como grupo
        newArgs.addAll(['--$GROUP', results.rest.first]);

      } else if (checkArg(results[GROUP])) {

        // Usuario ja tinha informado o grupo (do modo tradicional)
        newArgs.addAll(['--$GROUP', results[GROUP]]);
      }

      results = parser.parse(newArgs);
    }
    
    // Alteracao de status
    if (checkArg(results[NEW])) {
      results = parser.parse(['--$STATUS', 'new', results[NEW]]);

    } else if (checkArg(results[DOING])) {
      results = parser.parse(['--$STATUS', 'doing', results[DOING]]);

    } else if (checkArg(results[DONE])) {
      results = parser.parse(['--$STATUS', 'done', results[DONE]]);
    }
    
    // Alteracao de prioridade
    if (checkArg(results[URG])) {
      results = parser.parse(['--$PRIORITY', 'urg', results[URG]]);
      
    } else if (checkArg(results[MED])) {
      results = parser.parse(['--$PRIORITY', 'med', results[MED]]);

    } else if (checkArg(results[LOW])) {
      results = parser.parse(['--$PRIORITY', 'low', results[LOW]]);
    }

    // O cara so quer ajuda
    if (results[HELP]) {
      print(parser.usage);
      exit(0);
    }

    // Inicia o programa de fato
    TodoList(results, parser);

  } catch (e) {

    Colorize msgStyle = Colorize("\n${e.toString()}\n");
    msgStyle.lightYellow();
    msgStyle.italic();

    print(msgStyle);
    print(parser.usage);
    exit(1);
  }
}        
