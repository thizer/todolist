import 'package:json_annotation/json_annotation.dart';
part 'task.g.dart';

@JsonSerializable(explicitToJson: true)
class Task {
  String title;
  String description;
  DateTime created;
  String status;

  Task(this.title, this.description, this.created, this.status);

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);
  Map<String, dynamic> toJson() => _$TaskToJson(this);
}
