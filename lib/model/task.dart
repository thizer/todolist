import 'package:json_annotation/json_annotation.dart';
import 'package:todolist/application.dart';
part 'task.g.dart';

@JsonSerializable(explicitToJson: true)
class Task {
  
  // Fez alguma alteracao nessa classe?
  // Rode o comando abaixo para atualizar seus correspondentes *.g.dart
  //
  // $ pub run build_runner build

  String id;
  String title;
  String description;
  DateTime created;
  String status;
  String author;
  int priority;

  Task(this.title, this.description, this.author, this.priority) {
    this.id = rndHash(5);
    this.created = DateTime.now();
    this.status = 'new';
  }

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);
  Map<String, dynamic> toJson() => _$TaskToJson(this);
}
