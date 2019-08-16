import 'task.dart';

import 'package:json_annotation/json_annotation.dart';
part 'group.g.dart';

@JsonSerializable(explicitToJson: true)
class Group {

  // Fez alguma alteracao nessa classe?
  // Rode o comando abaixo para atualizar seus correspondentes *.g.dart
  //
  // $ pub run build_runner build

  String name;
  List<Task> tasks;

  Group(this.name, this.tasks);

  factory Group.fromJson(Map<String, dynamic> json) => _$GroupFromJson(json);
  Map<String, dynamic> toJson() => _$GroupToJson(this);
}