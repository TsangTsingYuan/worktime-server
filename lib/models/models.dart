class UserModel {
  final String id;
  final String phone;
  final String passwordHash;
  final String nickname;
  final String config;
  final int createdAt;
  final int updatedAt;

  UserModel({
    required this.id,
    required this.phone,
    required this.passwordHash,
    this.nickname = '',
    this.config = '{}',
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'phone': phone,
    'password_hash': passwordHash,
    'nickname': nickname,
    'config': config,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };

  Map<String, dynamic> toPublicJson() => {
    'id': id,
    'phone': phone,
    'nickname': nickname,
    'createdAt': createdAt,
  };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
    id: map['id'],
    phone: map['phone'],
    passwordHash: map['password_hash'],
    nickname: map['nickname'] ?? '',
    config: map['config'] ?? '{}',
    createdAt: map['created_at'],
    updatedAt: map['updated_at'],
  );
}

class TodoModel {
  final String id;
  final String userId;
  final String? clientId;
  final String title;
  final String description;
  final int priority;
  final int status;
  final int? dueDate;
  final String category;
  final String? linkedWorkLogClientId;
  final String? parentClientId;
  final String recurringRule;
  final int sortOrder;
  final int createdAt;
  final int updatedAt;

  TodoModel({
    required this.id,
    required this.userId,
    this.clientId,
    required this.title,
    this.description = '',
    this.priority = 1,
    this.status = 0,
    this.dueDate,
    this.category = '',
    this.linkedWorkLogClientId,
    this.parentClientId,
    this.recurringRule = '',
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'user_id': userId,
    'client_id': clientId,
    'title': title,
    'description': description,
    'priority': priority,
    'status': status,
    'due_date': dueDate,
    'category': category,
    'linked_work_log_client_id': linkedWorkLogClientId,
    'parent_client_id': parentClientId,
    'recurring_rule': recurringRule,
    'sort_order': sortOrder,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'clientId': clientId,
    'title': title,
    'description': description,
    'priority': priority,
    'status': status,
    'dueDate': dueDate,
    'category': category,
    'linkedWorkLogClientId': linkedWorkLogClientId,
    'parentClientId': parentClientId,
    'recurringRule': recurringRule,
    'sortOrder': sortOrder,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  factory TodoModel.fromJson(Map<String, dynamic> json) => TodoModel(
    id: json['id'],
    userId: json['userId'],
    clientId: json['clientId']?.toString(),
    title: json['title'] ?? '',
    description: json['description'] ?? '',
    priority: json['priority'] ?? 1,
    status: json['status'] ?? 0,
    dueDate: json['dueDate'],
    category: json['category'] ?? '',
    linkedWorkLogClientId: json['linkedWorkLogClientId']?.toString(),
    parentClientId: json['parentClientId']?.toString(),
    recurringRule: json['recurringRule'] ?? '',
    sortOrder: json['sortOrder'] ?? 0,
    createdAt: json['createdAt'],
    updatedAt: json['updatedAt'],
  );
}

class WorkLogModel {
  final String id;
  final String userId;
  final String clientId;
  final String title;
  final String category;
  final int startTime;
  final int? endTime;
  final int duration;
  final int status;
  final String notes;
  final int createdAt;
  final int updatedAt;

  WorkLogModel({
    required this.id,
    required this.userId,
    required this.clientId,
    required this.title,
    this.category = '',
    required this.startTime,
    this.endTime,
    this.duration = 0,
    this.status = 0,
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'user_id': userId,
    'client_id': clientId,
    'title': title,
    'category': category,
    'start_time': startTime,
    'end_time': endTime,
    'duration': duration,
    'status': status,
    'notes': notes,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'clientId': clientId,
    'title': title,
    'category': category,
    'startTime': startTime,
    'endTime': endTime,
    'duration': duration,
    'status': status,
    'notes': notes,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  factory WorkLogModel.fromJson(Map<String, dynamic> json) => WorkLogModel(
    id: json['id'],
    userId: json['userId'],
    clientId: json['clientId'],
    title: json['title'],
    category: json['category'] ?? '',
    startTime: json['startTime'],
    endTime: json['endTime'],
    duration: json['duration'] ?? 0,
    status: json['status'] ?? 0,
    notes: json['notes'] ?? '',
    createdAt: json['createdAt'] ?? json['startTime'],
    updatedAt: json['updatedAt'] ?? json['startTime'],
  );
}
