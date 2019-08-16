// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Task _$TaskFromJson(Map<String, dynamic> json) {
  return Task(
    json['title'] as String,
    json['description'] as String,
    json['author'] as String,
    json['priority'] as int ?? 2,
  )
    ..id = json['id'] as String
    ..created = json['created'] == null
        ? null
        : DateTime.parse(json['created'] as String)
    ..status = json['status'] as String ?? 'new';
}

Map<String, dynamic> _$TaskToJson(Task instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'created': instance.created?.toIso8601String(),
      'status': instance.status,
      'author': instance.author,
      'priority': instance.priority,
    };
