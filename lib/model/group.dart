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

  /// Search for a task inside the tasks list
  /// 
  /// The search here is made by [id] param
  Task find(String id) {
    Task result;
    for (Task item in this.tasks) {
      if (item.id == id) {
        result = item;
        break;
      }
    }
    return result;
  }

  factory Group.fromJson(Map<String, dynamic> json) => _$GroupFromJson(json);
  Map<String, dynamic> toJson() => _$GroupToJson(this);
}