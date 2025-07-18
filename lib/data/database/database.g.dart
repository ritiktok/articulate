// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $StrokesTable extends Strokes with TableInfo<$StrokesTable, Stroke> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StrokesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pointsMeta = const VerificationMeta('points');
  @override
  late final GeneratedColumn<String> points = GeneratedColumn<String>(
    'points',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationMeta = const VerificationMeta(
    'operation',
  );
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
    'operation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('draw'),
  );
  static const VerificationMeta _targetStrokeIdMeta = const VerificationMeta(
    'targetStrokeId',
  );
  @override
  late final GeneratedColumn<String> targetStrokeId = GeneratedColumn<String>(
    'target_stroke_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localVersionMeta = const VerificationMeta(
    'localVersion',
  );
  @override
  late final GeneratedColumn<int> localVersion = GeneratedColumn<int>(
    'local_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    userId,
    points,
    createdAt,
    operation,
    targetStrokeId,
    isActive,
    version,
    localVersion,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'strokes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Stroke> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('points')) {
      context.handle(
        _pointsMeta,
        points.isAcceptableOrUnknown(data['points']!, _pointsMeta),
      );
    } else if (isInserting) {
      context.missing(_pointsMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(
        _operationMeta,
        operation.isAcceptableOrUnknown(data['operation']!, _operationMeta),
      );
    }
    if (data.containsKey('target_stroke_id')) {
      context.handle(
        _targetStrokeIdMeta,
        targetStrokeId.isAcceptableOrUnknown(
          data['target_stroke_id']!,
          _targetStrokeIdMeta,
        ),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('local_version')) {
      context.handle(
        _localVersionMeta,
        localVersion.isAcceptableOrUnknown(
          data['local_version']!,
          _localVersionMeta,
        ),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Stroke map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Stroke(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      points: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}points'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      operation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation'],
      )!,
      targetStrokeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_stroke_id'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      ),
      localVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}local_version'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
    );
  }

  @override
  $StrokesTable createAlias(String alias) {
    return $StrokesTable(attachedDatabase, alias);
  }
}

class Stroke extends DataClass implements Insertable<Stroke> {
  final String id;
  final String sessionId;
  final String userId;
  final String points;
  final DateTime createdAt;
  final String operation;
  final String? targetStrokeId;
  final bool isActive;
  final int? version;
  final int? localVersion;
  final String syncStatus;
  const Stroke({
    required this.id,
    required this.sessionId,
    required this.userId,
    required this.points,
    required this.createdAt,
    required this.operation,
    this.targetStrokeId,
    required this.isActive,
    this.version,
    this.localVersion,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['user_id'] = Variable<String>(userId);
    map['points'] = Variable<String>(points);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['operation'] = Variable<String>(operation);
    if (!nullToAbsent || targetStrokeId != null) {
      map['target_stroke_id'] = Variable<String>(targetStrokeId);
    }
    map['is_active'] = Variable<bool>(isActive);
    if (!nullToAbsent || version != null) {
      map['version'] = Variable<int>(version);
    }
    if (!nullToAbsent || localVersion != null) {
      map['local_version'] = Variable<int>(localVersion);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    return map;
  }

  StrokesCompanion toCompanion(bool nullToAbsent) {
    return StrokesCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      userId: Value(userId),
      points: Value(points),
      createdAt: Value(createdAt),
      operation: Value(operation),
      targetStrokeId: targetStrokeId == null && nullToAbsent
          ? const Value.absent()
          : Value(targetStrokeId),
      isActive: Value(isActive),
      version: version == null && nullToAbsent
          ? const Value.absent()
          : Value(version),
      localVersion: localVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(localVersion),
      syncStatus: Value(syncStatus),
    );
  }

  factory Stroke.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Stroke(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      userId: serializer.fromJson<String>(json['userId']),
      points: serializer.fromJson<String>(json['points']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      operation: serializer.fromJson<String>(json['operation']),
      targetStrokeId: serializer.fromJson<String?>(json['targetStrokeId']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      version: serializer.fromJson<int?>(json['version']),
      localVersion: serializer.fromJson<int?>(json['localVersion']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'userId': serializer.toJson<String>(userId),
      'points': serializer.toJson<String>(points),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'operation': serializer.toJson<String>(operation),
      'targetStrokeId': serializer.toJson<String?>(targetStrokeId),
      'isActive': serializer.toJson<bool>(isActive),
      'version': serializer.toJson<int?>(version),
      'localVersion': serializer.toJson<int?>(localVersion),
      'syncStatus': serializer.toJson<String>(syncStatus),
    };
  }

  Stroke copyWith({
    String? id,
    String? sessionId,
    String? userId,
    String? points,
    DateTime? createdAt,
    String? operation,
    Value<String?> targetStrokeId = const Value.absent(),
    bool? isActive,
    Value<int?> version = const Value.absent(),
    Value<int?> localVersion = const Value.absent(),
    String? syncStatus,
  }) => Stroke(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    userId: userId ?? this.userId,
    points: points ?? this.points,
    createdAt: createdAt ?? this.createdAt,
    operation: operation ?? this.operation,
    targetStrokeId: targetStrokeId.present
        ? targetStrokeId.value
        : this.targetStrokeId,
    isActive: isActive ?? this.isActive,
    version: version.present ? version.value : this.version,
    localVersion: localVersion.present ? localVersion.value : this.localVersion,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  Stroke copyWithCompanion(StrokesCompanion data) {
    return Stroke(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      userId: data.userId.present ? data.userId.value : this.userId,
      points: data.points.present ? data.points.value : this.points,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      operation: data.operation.present ? data.operation.value : this.operation,
      targetStrokeId: data.targetStrokeId.present
          ? data.targetStrokeId.value
          : this.targetStrokeId,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      version: data.version.present ? data.version.value : this.version,
      localVersion: data.localVersion.present
          ? data.localVersion.value
          : this.localVersion,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Stroke(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('userId: $userId, ')
          ..write('points: $points, ')
          ..write('createdAt: $createdAt, ')
          ..write('operation: $operation, ')
          ..write('targetStrokeId: $targetStrokeId, ')
          ..write('isActive: $isActive, ')
          ..write('version: $version, ')
          ..write('localVersion: $localVersion, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    userId,
    points,
    createdAt,
    operation,
    targetStrokeId,
    isActive,
    version,
    localVersion,
    syncStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Stroke &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.userId == this.userId &&
          other.points == this.points &&
          other.createdAt == this.createdAt &&
          other.operation == this.operation &&
          other.targetStrokeId == this.targetStrokeId &&
          other.isActive == this.isActive &&
          other.version == this.version &&
          other.localVersion == this.localVersion &&
          other.syncStatus == this.syncStatus);
}

class StrokesCompanion extends UpdateCompanion<Stroke> {
  final Value<String> id;
  final Value<String> sessionId;
  final Value<String> userId;
  final Value<String> points;
  final Value<DateTime> createdAt;
  final Value<String> operation;
  final Value<String?> targetStrokeId;
  final Value<bool> isActive;
  final Value<int?> version;
  final Value<int?> localVersion;
  final Value<String> syncStatus;
  final Value<int> rowid;
  const StrokesCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.userId = const Value.absent(),
    this.points = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.operation = const Value.absent(),
    this.targetStrokeId = const Value.absent(),
    this.isActive = const Value.absent(),
    this.version = const Value.absent(),
    this.localVersion = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StrokesCompanion.insert({
    required String id,
    required String sessionId,
    required String userId,
    required String points,
    required DateTime createdAt,
    this.operation = const Value.absent(),
    this.targetStrokeId = const Value.absent(),
    this.isActive = const Value.absent(),
    this.version = const Value.absent(),
    this.localVersion = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionId = Value(sessionId),
       userId = Value(userId),
       points = Value(points),
       createdAt = Value(createdAt);
  static Insertable<Stroke> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<String>? userId,
    Expression<String>? points,
    Expression<DateTime>? createdAt,
    Expression<String>? operation,
    Expression<String>? targetStrokeId,
    Expression<bool>? isActive,
    Expression<int>? version,
    Expression<int>? localVersion,
    Expression<String>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (userId != null) 'user_id': userId,
      if (points != null) 'points': points,
      if (createdAt != null) 'created_at': createdAt,
      if (operation != null) 'operation': operation,
      if (targetStrokeId != null) 'target_stroke_id': targetStrokeId,
      if (isActive != null) 'is_active': isActive,
      if (version != null) 'version': version,
      if (localVersion != null) 'local_version': localVersion,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StrokesCompanion copyWith({
    Value<String>? id,
    Value<String>? sessionId,
    Value<String>? userId,
    Value<String>? points,
    Value<DateTime>? createdAt,
    Value<String>? operation,
    Value<String?>? targetStrokeId,
    Value<bool>? isActive,
    Value<int?>? version,
    Value<int?>? localVersion,
    Value<String>? syncStatus,
    Value<int>? rowid,
  }) {
    return StrokesCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      points: points ?? this.points,
      createdAt: createdAt ?? this.createdAt,
      operation: operation ?? this.operation,
      targetStrokeId: targetStrokeId ?? this.targetStrokeId,
      isActive: isActive ?? this.isActive,
      version: version ?? this.version,
      localVersion: localVersion ?? this.localVersion,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (points.present) {
      map['points'] = Variable<String>(points.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (targetStrokeId.present) {
      map['target_stroke_id'] = Variable<String>(targetStrokeId.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (localVersion.present) {
      map['local_version'] = Variable<int>(localVersion.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StrokesCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('userId: $userId, ')
          ..write('points: $points, ')
          ..write('createdAt: $createdAt, ')
          ..write('operation: $operation, ')
          ..write('targetStrokeId: $targetStrokeId, ')
          ..write('isActive: $isActive, ')
          ..write('version: $version, ')
          ..write('localVersion: $localVersion, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$CanvasDatabase extends GeneratedDatabase {
  _$CanvasDatabase(QueryExecutor e) : super(e);
  $CanvasDatabaseManager get managers => $CanvasDatabaseManager(this);
  late final $StrokesTable strokes = $StrokesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [strokes];
}

typedef $$StrokesTableCreateCompanionBuilder =
    StrokesCompanion Function({
      required String id,
      required String sessionId,
      required String userId,
      required String points,
      required DateTime createdAt,
      Value<String> operation,
      Value<String?> targetStrokeId,
      Value<bool> isActive,
      Value<int?> version,
      Value<int?> localVersion,
      Value<String> syncStatus,
      Value<int> rowid,
    });
typedef $$StrokesTableUpdateCompanionBuilder =
    StrokesCompanion Function({
      Value<String> id,
      Value<String> sessionId,
      Value<String> userId,
      Value<String> points,
      Value<DateTime> createdAt,
      Value<String> operation,
      Value<String?> targetStrokeId,
      Value<bool> isActive,
      Value<int?> version,
      Value<int?> localVersion,
      Value<String> syncStatus,
      Value<int> rowid,
    });

class $$StrokesTableFilterComposer
    extends Composer<_$CanvasDatabase, $StrokesTable> {
  $$StrokesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get points => $composableBuilder(
    column: $table.points,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetStrokeId => $composableBuilder(
    column: $table.targetStrokeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get localVersion => $composableBuilder(
    column: $table.localVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StrokesTableOrderingComposer
    extends Composer<_$CanvasDatabase, $StrokesTable> {
  $$StrokesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get points => $composableBuilder(
    column: $table.points,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetStrokeId => $composableBuilder(
    column: $table.targetStrokeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get localVersion => $composableBuilder(
    column: $table.localVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StrokesTableAnnotationComposer
    extends Composer<_$CanvasDatabase, $StrokesTable> {
  $$StrokesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get points =>
      $composableBuilder(column: $table.points, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get targetStrokeId => $composableBuilder(
    column: $table.targetStrokeId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<int> get localVersion => $composableBuilder(
    column: $table.localVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );
}

class $$StrokesTableTableManager
    extends
        RootTableManager<
          _$CanvasDatabase,
          $StrokesTable,
          Stroke,
          $$StrokesTableFilterComposer,
          $$StrokesTableOrderingComposer,
          $$StrokesTableAnnotationComposer,
          $$StrokesTableCreateCompanionBuilder,
          $$StrokesTableUpdateCompanionBuilder,
          (Stroke, BaseReferences<_$CanvasDatabase, $StrokesTable, Stroke>),
          Stroke,
          PrefetchHooks Function()
        > {
  $$StrokesTableTableManager(_$CanvasDatabase db, $StrokesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StrokesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StrokesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StrokesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> points = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> operation = const Value.absent(),
                Value<String?> targetStrokeId = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int?> version = const Value.absent(),
                Value<int?> localVersion = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StrokesCompanion(
                id: id,
                sessionId: sessionId,
                userId: userId,
                points: points,
                createdAt: createdAt,
                operation: operation,
                targetStrokeId: targetStrokeId,
                isActive: isActive,
                version: version,
                localVersion: localVersion,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sessionId,
                required String userId,
                required String points,
                required DateTime createdAt,
                Value<String> operation = const Value.absent(),
                Value<String?> targetStrokeId = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int?> version = const Value.absent(),
                Value<int?> localVersion = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StrokesCompanion.insert(
                id: id,
                sessionId: sessionId,
                userId: userId,
                points: points,
                createdAt: createdAt,
                operation: operation,
                targetStrokeId: targetStrokeId,
                isActive: isActive,
                version: version,
                localVersion: localVersion,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StrokesTableProcessedTableManager =
    ProcessedTableManager<
      _$CanvasDatabase,
      $StrokesTable,
      Stroke,
      $$StrokesTableFilterComposer,
      $$StrokesTableOrderingComposer,
      $$StrokesTableAnnotationComposer,
      $$StrokesTableCreateCompanionBuilder,
      $$StrokesTableUpdateCompanionBuilder,
      (Stroke, BaseReferences<_$CanvasDatabase, $StrokesTable, Stroke>),
      Stroke,
      PrefetchHooks Function()
    >;

class $CanvasDatabaseManager {
  final _$CanvasDatabase _db;
  $CanvasDatabaseManager(this._db);
  $$StrokesTableTableManager get strokes =>
      $$StrokesTableTableManager(_db, _db.strokes);
}
