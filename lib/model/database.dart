import 'group.dart';

import 'package:json_annotation/json_annotation.dart';
part 'database.g.dart';

@JsonSerializable(explicitToJson: true)
class Database {

  // Fez alguma alteracao nessa classe?
  // Rode o comando abaixo para atualizar seus correspondentes *.g.dart
  //
  // $ pub run build_runner build

  List<Group> group;

  Database(this.group);

  Group find(String name) {
    for (Group item in this.group) {
      if (item.name == name) {
        return item;
      }
    }
  }

  factory Database.fromJson(Map<String, dynamic> json) => _$DatabaseFromJson(json);
  Map<String, dynamic> toJson() => _$DatabaseToJson(this);
}
