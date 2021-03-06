import 'dart:io';
import 'dart:convert';
import 'package:args/args.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart' as crypto;

const ABOUT = 'about';
const HELP = 'help';

const ALL = 'all';
const COMPACT = 'compact';
const LIST = 'list';
const ADD = 'add';
const REMOVE = 'remove';
const MOVE = 'move';

const GROUP = 'group';

const STATUS = 'status';
const NEW = 'new';
const DOING = 'doing';
const DONE = 'done';

const PRIORITY = 'priority';
const URG = 'urg';
const MED = 'med';
const LOW = 'low';

const REMOVE_GROUP = 'rm-group';
const GROUP_NAME = 'set-groupname';
const JSON_DB = 'set-jsondb';

String getHomePath() {
  var env = Platform.environment;
  return env.entries.firstWhere((o) => o.key == 'HOME').value;
}

String getUsername() {
  var env = Platform.environment;
  return env.entries.firstWhere((o) => o.key == 'USER').value;
}

bool checkArg(var arg) {
  var result = false;
  if (arg.runtimeType.toString() == 'bool') {
    // Ja eh booleano, apenas retorna
    result = arg;
  } else if (arg != null && arg.toString().isNotEmpty) {
    // Outro tipo qualquer, checa se esta vazio (como string)
    result = true;
  }
  return result;
}

bool checkArgInArray(ArgResults arg, List<String> array) {
  var result = false;
  for (var item in array) {
    if (checkArg(arg[item])) {
      result = true;
      break;
    }
  }
  return result;
}

String rndHash(int length) {
  var content = Utf8Encoder().convert(DateTime.now().toIso8601String());
  var md5 = crypto.md5;
  var digest = md5.convert(content);
  var hash = hex.encode(digest.bytes);

  return hash.substring(0, length);
}

String textCenter(String text, {int maxlen = 50, String padding = ' '}) {
  // Calcula metade dos caracteres para cada lado
  var pad = ((maxlen - text.length) / 2).floor();
  if (pad < 0) pad = 0;

  // Aplica em ambos os lados
  var result = ''.padLeft(pad, padding) + text + ''.padRight(pad, padding);

  // Em caso de impares é necessario completar
  return result.padRight(maxlen, padding);
}
