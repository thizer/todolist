// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Task _$TaskFromJson(Map<String, dynamic> json) {
  return Task(
    json['title'] as String,
    json['description'] as String,
    json['created'] == null ? null : DateTime.parse(json['created'] as String),
    json['status'] as String,
  )
    ..id = json['id'] as String
    ..priority = json['priority'] as int
    ..author = json['author'] as String;
}

Map<String, dynamic> _$TaskToJson(Task instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'created': instance.created?.toIso8601String(),
      'status': instance.status,
      'priority': instance.priority,
      'author': instance.author,
    };
