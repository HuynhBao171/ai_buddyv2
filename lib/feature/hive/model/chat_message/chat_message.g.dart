// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ChatMessageImpl _$$ChatMessageImplFromJson(Map<String, dynamic> json) =>
    _$ChatMessageImpl(
      id: json['id'] as String,
      text: json['text'] as String,
      imagePath: json['imagePath'] as String,
      audioId: json['audioId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      typeOfMessage: json['typeOfMessage'] as String,
      chatBotId: json['chatBotId'] as String,
      typeOfMessageUser: json['typeOfMessageUser'] as String,
      requikljkkljkl: json['requikljkkljkl'],
    );

Map<String, dynamic> _$$ChatMessageImplToJson(_$ChatMessageImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'text': instance.text,
      'imagePath': instance.imagePath,
      'audioId': instance.audioId,
      'createdAt': instance.createdAt.toIso8601String(),
      'typeOfMessage': instance.typeOfMessage,
      'chatBotId': instance.chatBotId,
      'typeOfMessageUser': instance.typeOfMessageUser,
      'requikljkkljkl': instance.requikljkkljkl,
    };
