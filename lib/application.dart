import 'dart:io';

const HELP = 'help';

const LIST = 'list';
const ADD = 'add';
const REMOVE = 'remove';
const MOVE = 'move';

const GROUP = 'group';
const FINISH = 'finish';

const SET_FOLDER = 'set-folder';

String getHomePath() {
  Map<String, String> env = Platform.environment;
  return env.entries.firstWhere((o) => o.key == 'HOME').value;
}

bool checkArg(var arg) {
  bool result = false;
  if (arg.runtimeType.toString() == 'bool') {

    // Ja eh booleano, apenas retorna
    result = arg;

  } else if (arg != null && arg.toString().isNotEmpty) {

    // Outro tipo qualquer, checa se esta vazio (como string)
    result = true;
  }
  return result;
}
