import 'package:json_annotation/json_annotation.dart';
import 'package:todolist/application.dart';
part 'task.g.dart';

@JsonSerializable(explicitToJson: true)
class Task {
  
  String id;
  String title;
  String description;
  DateTime created;
  String status;
  int priority;
  String author;

  Task(this.title, this.description, this.created, this.status) {
    this.id = rndHash(5);
  }

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);
  Map<String, dynamic> toJson() => _$TaskToJson(this);
}
