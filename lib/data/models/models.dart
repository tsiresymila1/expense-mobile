// Thin data models parsed from InstantDB query-result maps.
// InstantDB returns each entity's scalar attributes as a Map<String, dynamic>.
// We store link ids ALSO as scalar attributes (projectId, categoryId, creatorId,
// ownerId, userId) so the client can filter with plain `where` clauses; the
// matching InstantDB links exist server-side for permission rules.
// ponytail: hand-written fromMap over codegen; adopt flutter_instantdb_generator
// only if typed queries become worth the build_runner cost.

DateTime? _date(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
  if (v is String) return DateTime.tryParse(v);
  return null;
}

double _double(dynamic v) => v is num ? v.toDouble() : 0.0;

class Expense {
  final String id;
  final String creatorId;
  final String? projectId;
  final String? categoryId;
  final double amount;
  final String type; // 'expense' | 'income'
  final DateTime date;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  Expense({
    required this.id,
    required this.creatorId,
    this.projectId,
    this.categoryId,
    required this.amount,
    required this.type,
    required this.date,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Expense.fromMap(Map<String, dynamic> m) => Expense(
        id: m['id'] as String,
        creatorId: (m['creatorId'] ?? '') as String,
        projectId: m['projectId'] as String?,
        categoryId: m['categoryId'] as String?,
        amount: _double(m['amount']),
        type: (m['type'] ?? 'expense') as String,
        date: _date(m['date']) ?? DateTime.now(),
        note: m['note'] as String?,
        createdAt: _date(m['createdAt']) ?? DateTime.now(),
        updatedAt: _date(m['updatedAt']) ?? DateTime.now(),
      );
}

class Category {
  final String id;
  final String? ownerId;
  final String name;
  final String? icon;
  final String? color;
  final bool isDefault;
  final DateTime updatedAt;

  Category({
    required this.id,
    this.ownerId,
    required this.name,
    this.icon,
    this.color,
    this.isDefault = false,
    required this.updatedAt,
  });

  factory Category.fromMap(Map<String, dynamic> m) => Category(
        id: m['id'] as String,
        ownerId: m['ownerId'] as String?,
        name: (m['name'] ?? '') as String,
        icon: m['icon'] as String?,
        color: m['color'] as String?,
        isDefault: (m['isDefault'] ?? false) as bool,
        updatedAt: _date(m['updatedAt']) ?? DateTime.now(),
      );
}

class Project {
  final String id;
  final String ownerId;
  final String name;
  final String? description;
  final String? color;
  final String? icon;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  Project({
    required this.id,
    required this.ownerId,
    required this.name,
    this.description,
    this.color,
    this.icon,
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Project.fromMap(Map<String, dynamic> m) => Project(
        id: m['id'] as String,
        ownerId: (m['ownerId'] ?? '') as String,
        name: (m['name'] ?? '') as String,
        description: m['description'] as String?,
        color: m['color'] as String?,
        icon: m['icon'] as String?,
        isDefault: (m['isDefault'] ?? false) as bool,
        createdAt: _date(m['createdAt']) ?? DateTime.now(),
        updatedAt: _date(m['updatedAt']) ?? DateTime.now(),
      );
}

class ProjectMember {
  final String id;
  final String projectId;
  final String userId;
  final String role;
  final String? invitedBy;
  final DateTime? invitedAt;
  final DateTime? acceptedAt;

  ProjectMember({
    required this.id,
    required this.projectId,
    required this.userId,
    this.role = 'viewer',
    this.invitedBy,
    this.invitedAt,
    this.acceptedAt,
  });

  factory ProjectMember.fromMap(Map<String, dynamic> m) => ProjectMember(
        id: m['id'] as String,
        projectId: (m['projectId'] ?? '') as String,
        userId: (m['userId'] ?? '') as String,
        role: (m['role'] ?? 'viewer') as String,
        invitedBy: m['invitedBy'] as String?,
        invitedAt: _date(m['invitedAt']),
        acceptedAt: _date(m['acceptedAt']),
      );
}

class Profile {
  final String id; // == InstantDB $users id
  final String name;
  final String email;

  Profile({required this.id, required this.name, required this.email});

  factory Profile.fromMap(Map<String, dynamic> m) => Profile(
        id: m['id'] as String,
        name: (m['name'] ?? '') as String,
        email: (m['email'] ?? '') as String,
      );
}

/// Helper: coerce a QueryResult namespace list into typed models.
List<T> mapList<T>(
  dynamic raw,
  T Function(Map<String, dynamic>) from,
) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((e) => from(Map<String, dynamic>.from(e)))
      .toList();
}
