import 'enums.dart';

class LocationModel {
  final String id;
  final String name;
  final LocationType type;
  final DateTime createdAt;

  LocationModel({
    required this.id,
    required this.name,
    required this.type,
    required this.createdAt,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    final typeStr = (json['type'] as String?) ?? 'warehouse';
    return LocationModel(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      type: typeStr.toLocationType() ?? LocationType.warehouse,
      createdAt: DateTime.tryParse((json['created_at'] as String?) ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

