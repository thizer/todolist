import 'group.dart';

import 'package:json_annotation/json_annotation.dart';
part 'database.g.dart';

@JsonSerializable(explicitToJson: true)
class Database {

  List<Group> group;

  Database(this.group);

  factory Database.fromJson(Map<String, dynamic> json) => _$DatabaseFromJson(json);
  Map<String, dynamic> toJson() => _$DatabaseToJson(this);
}
