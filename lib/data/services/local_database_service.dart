import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/report.dart';

class LocalDatabaseService {
  static final LocalDatabaseService _instance = LocalDatabaseService._internal();
  factory LocalDatabaseService() => _instance;
  LocalDatabaseService._internal();

  Database? _database;
  bool _databaseEnabled = true;

  // In-memory fallback database for Web/testing where sqlite is not initialized
  final List<Report> _memoryDb = [];

  Future<Database?> get database async {
    if (!_databaseEnabled) return null;
    if (_database != null) return _database!;
    try {
      _database = await _initDatabase();
      return _database!;
    } catch (e) {
      _databaseEnabled = false;
      debugPrint(
        'SQLite no está disponible en esta plataforma (ej. Web o FFI no iniciado). '
        'Usando fallback de base de datos en memoria local. Detalles: $e',
      );
      return null;
    }
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'agora_incidents.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE incidents (
        id TEXT PRIMARY KEY,
        title TEXT,
        area TEXT,
        classroom TEXT,
        building TEXT,
        dateTime TEXT,
        details TEXT,
        status TEXT,
        reportedBy TEXT,
        imageUrl TEXT
      )
    ''');
  }

  /// Inserts or updates an incident report.
  Future<void> saveIncident(Report report) async {
    final db = await database;
    if (db != null) {
      await db.insert(
        'incidents',
        _toMap(report),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } else {
      _memoryDb.removeWhere((r) => r.id == report.id);
      _memoryDb.add(report);
    }
  }

  /// Fetches all incidents stored locally.
  Future<List<Report>> getIncidents() async {
    final db = await database;
    if (db != null) {
      final List<Map<String, dynamic>> maps = await db.query('incidents');
      return List.generate(maps.length, (i) {
        return _fromMap(maps[i]);
      });
    } else {
      return List.from(_memoryDb);
    }
  }

  /// Deletes an incident report by ID.
  Future<void> deleteIncident(String id) async {
    final db = await database;
    if (db != null) {
      await db.delete(
        'incidents',
        where: 'id = ?',
        whereArgs: [id],
      );
    } else {
      _memoryDb.removeWhere((r) => r.id == id);
    }
  }

  // Helpers to transform data between Report model and SQLite columns
  Map<String, dynamic> _toMap(Report report) {
    return {
      'id': report.id,
      'title': report.title,
      'area': report.area?.name,
      'classroom': report.classroom,
      'building': report.building,
      'dateTime': report.dateTime.toIso8601String(),
      'details': report.details,
      'status': report.status.name,
      'reportedBy': report.reportedBy,
      'imageUrl': report.imageUrl,
    };
  }

  Report _fromMap(Map<String, dynamic> map) {
    final areaString = map['area'] as String?;
    final areaEnum = areaString != null
        ? ReportArea.values.firstWhere((e) => e.name == areaString)
        : null;

    return Report(
      id: map['id'] as String,
      title: map['title'] as String,
      area: areaEnum,
      classroom: map['classroom'] as String,
      building: map['building'] as String,
      dateTime: DateTime.parse(map['dateTime'] as String),
      details: map['details'] as String,
      status: ReportStatus.values.firstWhere((e) => e.name == map['status']),
      reportedBy: map['reportedBy'] as String,
      imageUrl: map['imageUrl'] as String?,
    );
  }
}
