import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:tao_status_tracker/core/utils/security_utils.dart';
import 'package:tao_status_tracker/models/habit.dart';
import 'package:tao_status_tracker/models/habit_completion.dart';
import 'package:tao_status_tracker/models/challenge.dart';
import 'package:tao_status_tracker/models/challenge_progress.dart';

class LocalStorageService {
  static Database? _database;
  static const String _dbName = 'tao_habits.db';
  static const int _dbVersion = 2;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _createTables,
      onUpgrade: _upgradeTables,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE habits (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        category TEXT NOT NULL,
        iconCode INTEGER NOT NULL,
        iconPath TEXT,
        selectedDays TEXT NOT NULL,
        reminderTime TEXT NOT NULL,
        duration INTEGER,
        repeat TEXT,
        createdAt INTEGER NOT NULL,
        synced INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE completions (
        id TEXT PRIMARY KEY,
        habitId TEXT NOT NULL,
        userId TEXT NOT NULL,
        completedAt INTEGER NOT NULL,
        duration INTEGER NOT NULL,
        notes TEXT,
        rating REAL,
        isSkipped INTEGER DEFAULT 0,
        synced INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE challenges (
        id TEXT PRIMARY KEY,
        creatorId TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        startDate INTEGER NOT NULL,
        durationDays INTEGER NOT NULL,
        participantIds TEXT NOT NULL,
        reminderTime TEXT,
        status TEXT NOT NULL,
        createdAt INTEGER NOT NULL,
        synced INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE challenge_progress (
        id TEXT PRIMARY KEY,
        challengeId TEXT NOT NULL,
        userId TEXT NOT NULL,
        date INTEGER NOT NULL,
        completed INTEGER DEFAULT 0,
        notes TEXT,
        createdAt INTEGER NOT NULL,
        synced INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_queue (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        data TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        synced INTEGER DEFAULT 0
      )
    ''');
  }

  Future<void> _upgradeTables(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS challenges (
          id TEXT PRIMARY KEY,
          creatorId TEXT NOT NULL,
          title TEXT NOT NULL,
          description TEXT,
          startDate INTEGER NOT NULL,
          durationDays INTEGER NOT NULL,
          participantIds TEXT NOT NULL,
          reminderTime TEXT,
          status TEXT NOT NULL,
          createdAt INTEGER NOT NULL,
          synced INTEGER DEFAULT 0
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS challenge_progress (
          id TEXT PRIMARY KEY,
          challengeId TEXT NOT NULL,
          userId TEXT NOT NULL,
          date INTEGER NOT NULL,
          completed INTEGER DEFAULT 0,
          notes TEXT,
          createdAt INTEGER NOT NULL,
          synced INTEGER DEFAULT 0
        )
      ''');
    }
  }

  // Habit operations
  Future<void> saveHabit(Habit habit, String userId, {bool synced = false}) async {
    try {
      final db = await database;
      await db.insert(
        'habits',
        {
          'id': habit.id,
          'userId': userId,
          'title': SecurityUtils.sanitizeInput(habit.title),
          'description': SecurityUtils.sanitizeInput(habit.description),
          'category': habit.category,
          'iconCode': habit.iconCode,
          'iconPath': habit.iconPath,
          'selectedDays': jsonEncode(habit.selectedDays),
          'reminderTime': habit.reminderTime,
          'duration': habit.duration,
          'repeat': habit.repeat,
          'createdAt': habit.createdAt.millisecondsSinceEpoch,
          'synced': synced ? 1 : 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      SecurityUtils.secureLog('Error saving habit locally: $e');
    }
  }

  Future<List<Habit>> getHabits(String userId) async {
    try {
      final db = await database;
      final maps = await db.query(
        'habits',
        where: 'userId = ?',
        whereArgs: [userId],
        orderBy: 'createdAt DESC',
      );

      return maps.map((map) => _habitFromMap(map)).toList();
    } catch (e) {
      SecurityUtils.secureLog('Error getting habits locally: $e');
      return [];
    }
  }

  Future<void> deleteHabit(String habitId) async {
    try {
      final db = await database;
      await db.delete('habits', where: 'id = ?', whereArgs: [habitId]);
    } catch (e) {
      SecurityUtils.secureLog('Error deleting habit locally: $e');
    }
  }

  // Completion operations
  Future<void> saveCompletion(HabitCompletion completion, {bool synced = false}) async {
    try {
      final db = await database;
      final completionId = completion.id.isEmpty 
          ? DateTime.now().millisecondsSinceEpoch.toString() 
          : completion.id;
          
      await db.insert(
        'completions',
        {
          'id': completionId,
          'habitId': completion.habitId,
          'userId': completion.userId,
          'completedAt': completion.completedAt.millisecondsSinceEpoch,
          'duration': completion.duration,
          'notes': SecurityUtils.sanitizeInput(completion.notes ?? ''),
          'rating': completion.rating,
          'isSkipped': completion.isSkipped ? 1 : 0,
          'synced': synced ? 1 : 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      SecurityUtils.secureLog('Error saving completion locally: $e');
    }
  }

  Future<List<HabitCompletion>> getCompletions(String userId, {String? habitId}) async {
    try {
      final db = await database;
      String where = 'userId = ?';
      List<dynamic> whereArgs = [userId];

      if (habitId != null) {
        where += ' AND habitId = ?';
        whereArgs.add(habitId);
      }

      final maps = await db.query(
        'completions',
        where: where,
        whereArgs: whereArgs,
        orderBy: 'completedAt DESC',
      );

      return maps.map((map) => _completionFromMap(map)).toList();
    } catch (e) {
      SecurityUtils.secureLog('Error getting completions locally: $e');
      return [];
    }
  }

  // Challenge operations
  Future<void> saveChallenge(Challenge challenge, {bool synced = false}) async {
    try {
      final db = await database;
      await db.insert(
        'challenges',
        {
          'id': challenge.id,
          'creatorId': challenge.creatorId,
          'title': SecurityUtils.sanitizeInput(challenge.title),
          'description': SecurityUtils.sanitizeInput(challenge.description),
          'startDate': challenge.startDate.millisecondsSinceEpoch,
          'durationDays': challenge.durationDays,
          'participantIds': jsonEncode(challenge.participantIds),
          'reminderTime': challenge.reminderTime,
          'status': challenge.status.name,
          'createdAt': challenge.createdAt.millisecondsSinceEpoch,
          'synced': synced ? 1 : 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      SecurityUtils.secureLog('Error saving challenge locally: $e');
    }
  }

  Future<List<Challenge>> getChallenges(String userId) async {
    try {
      final db = await database;
      final maps = await db.query(
        'challenges',
        where: 'participantIds LIKE ?',
        whereArgs: ['%"$userId"%'],
        orderBy: 'createdAt DESC',
      );

      return maps.map((map) => _challengeFromMap(map)).toList();
    } catch (e) {
      SecurityUtils.secureLog('Error getting challenges locally: $e');
      return [];
    }
  }

  Future<Challenge?> getChallenge(String challengeId) async {
    try {
      final db = await database;
      final maps = await db.query(
        'challenges',
        where: 'id = ?',
        whereArgs: [challengeId],
        limit: 1,
      );

      if (maps.isEmpty) return null;
      return _challengeFromMap(maps.first);
    } catch (e) {
      SecurityUtils.secureLog('Error getting challenge locally: $e');
      return null;
    }
  }

  // Challenge progress operations
  Future<void> saveChallengeProgress(ChallengeProgress progress, {bool synced = false}) async {
    try {
      final db = await database;
      await db.insert(
        'challenge_progress',
        {
          'id': progress.id,
          'challengeId': progress.challengeId,
          'userId': progress.userId,
          'date': progress.date.millisecondsSinceEpoch,
          'completed': progress.completed ? 1 : 0,
          'notes': SecurityUtils.sanitizeInput(progress.notes ?? ''),
          'createdAt': progress.createdAt.millisecondsSinceEpoch,
          'synced': synced ? 1 : 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      SecurityUtils.secureLog('Error saving challenge progress locally: $e');
    }
  }

  Future<List<ChallengeProgress>> getChallengeProgress(String challengeId, String userId) async {
    try {
      final db = await database;
      final maps = await db.query(
        'challenge_progress',
        where: 'challengeId = ? AND userId = ?',
        whereArgs: [challengeId, userId],
        orderBy: 'date DESC',
      );

      return maps.map((map) => _challengeProgressFromMap(map)).toList();
    } catch (e) {
      SecurityUtils.secureLog('Error getting challenge progress locally: $e');
      return [];
    }
  }

  // Sync operations
  Future<void> addToSyncQueue(String type, Map<String, dynamic> data) async {
    try {
      final db = await database;
      await db.insert('sync_queue', {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'type': type,
        'data': jsonEncode(data),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'synced': 0,
      });
    } catch (e) {
      SecurityUtils.secureLog('Error adding to sync queue: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getPendingSyncOperations() async {
    try {
      final db = await database;
      return await db.query(
        'sync_queue',
        where: 'synced = ?',
        whereArgs: [0],
        orderBy: 'timestamp ASC',
      );
    } catch (e) {
      SecurityUtils.secureLog('Error getting pending sync operations: $e');
      return [];
    }
  }

  Future<void> markSyncOperationComplete(String id) async {
    try {
      final db = await database;
      await db.update(
        'sync_queue',
        {'synced': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      SecurityUtils.secureLog('Error marking sync operation complete: $e');
    }
  }

  // Helper methods
  Habit _habitFromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      category: map['category'],
      iconCode: map['iconCode'],
      iconPath: map['iconPath'],
      selectedDays: List<int>.from(jsonDecode(map['selectedDays'])),
      reminderTime: map['reminderTime'],
      duration: map['duration'],
      repeat: map['repeat'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
    );
  }

  HabitCompletion _completionFromMap(Map<String, dynamic> map) {
    return HabitCompletion(
      id: map['id'],
      habitId: map['habitId'],
      userId: map['userId'],
      completedAt: DateTime.fromMillisecondsSinceEpoch(map['completedAt']),
      duration: map['duration'],
      notes: map['notes'],
      rating: map['rating']?.toDouble(),
      isSkipped: map['isSkipped'] == 1,
    );
  }

  Challenge _challengeFromMap(Map<String, dynamic> map) {
    return Challenge(
      id: map['id'],
      creatorId: map['creatorId'],
      title: map['title'],
      description: map['description'],
      startDate: DateTime.fromMillisecondsSinceEpoch(map['startDate']),
      durationDays: map['durationDays'],
      participantIds: List<String>.from(jsonDecode(map['participantIds'])),
      reminderTime: map['reminderTime'],
      status: ChallengeStatus.values.firstWhere(
        (status) => status.name == map['status'],
        orElse: () => ChallengeStatus.upcoming,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
    );
  }

  ChallengeProgress _challengeProgressFromMap(Map<String, dynamic> map) {
    return ChallengeProgress(
      id: map['id'],
      challengeId: map['challengeId'],
      userId: map['userId'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      completed: map['completed'] == 1,
      notes: map['notes'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
    );
  }

  Future<void> clearAllData() async {
    try {
      final db = await database;
      await db.delete('habits');
      await db.delete('completions');
      await db.delete('challenges');
      await db.delete('challenge_progress');
      await db.delete('sync_queue');
    } catch (e) {
      SecurityUtils.secureLog('Error clearing local data: $e');
    }
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}