import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../utilities/console_log.dart';

class AppDatabase {
  /// Singleton instance
  static final AppDatabase _instance = AppDatabase._();

  factory AppDatabase() => _instance;

  AppDatabase._();

  late Database database;

  /// Initialize the database
  Future<void> init() async {
    print('[AppDatabase] Initializing database...');
    // Get database path
    String path = join(await getDatabasesPath(), AppDatabaseConfig.dbPath);

    // Open or create database
    database = await openDatabase(
      path,
      version: AppDatabaseConfig.version,
      onCreate: (db, version) async {
        print('[AppDatabase] Creating tables...');
        await db.execute(AppDatabaseConfig.createUserTable);
        await db.execute(AppDatabaseConfig.createProductTable);
        await db.execute(AppDatabaseConfig.createTransactionTable);
        await db.execute(AppDatabaseConfig.createOrderedProductTable);
        await db.execute(AppDatabaseConfig.createQueuedActionTable);
      },
    );

    print('[AppDatabase] Database initialized successfully.');
  }

  /// Drop the database (used for testing or development)
  Future<void> dropDatabase() async {
    String path = join(await getDatabasesPath(), AppDatabaseConfig.dbPath);
    File databaseFile = File(path);
    if (await databaseFile.exists()) {
      await database.close();
      await databaseFile.delete();
      print('[AppDatabase] Database deleted successfully.');
    } else {
      print('[AppDatabase] Database does not exist.');
    }
  }

  /// For testing purposes only
  Future<void> initTestDatabase({required Database testDatabase}) async {
    assert(() {
      database = testDatabase;
      return true;
    }(), "[AppDatabase].initTestDatabase should only be used in unit tests.");

    if (!kDebugMode) return;

    await Future.wait([
      database.execute(AppDatabaseConfig.createUserTable),
      database.execute(AppDatabaseConfig.createProductTable),
      database.execute(AppDatabaseConfig.createTransactionTable),
      database.execute(AppDatabaseConfig.createOrderedProductTable),
      database.execute(AppDatabaseConfig.createQueuedActionTable),
    ]);
  }
}

class AppDatabaseConfig {
  static const String dbPath = 'app_database.db';
  static const int version = 1;

  static const String userTableName = 'User';
  static const String productTableName = 'Product';
  static const String transactionTableName = 'Transaction';
  static const String orderedProductTableName = 'OrderedProduct';
  static const String queuedActionTableName = 'QueuedAction';

  static String createUserTable = '''
CREATE TABLE IF NOT EXISTS '$userTableName' (
    'id' TEXT NOT NULL,
    'email' TEXT,
    'phone' TEXT,
    'name' TEXT,
    'gender' TEXT,
    'birthdate' TEXT,
    'imageUrl' TEXT,
    'createdAt' DATETIME DEFAULT CURRENT_TIMESTAMP,
    'updatedAt' DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY ('id')
);
''';

  static String createProductTable = '''
CREATE TABLE IF NOT EXISTS '$productTableName' (
    'id' INTEGER NOT NULL,
    'createdById' TEXT,
    'name' TEXT,
    'imageUrl' TEXT,
    'stock' INTEGER,
    'sold' INTEGER,
    'price' INTEGER,
    'description' TEXT,
    createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
    updatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY ('id'),
    FOREIGN KEY ('createdById') REFERENCES 'User' ('id')
);
''';

  static String createTransactionTable = '''
CREATE TABLE IF NOT EXISTS '$transactionTableName' (
    'id' INTEGER NOT NULL,
    'paymentMethod' TEXT,
    'customerName' TEXT,
    'description' TEXT,
    'createdById' TEXT,
    'receivedAmount' INTEGER,
    'returnAmount' INTEGER,
    'totalAmount' INTEGER,
    'totalOrderedProduct' INTEGER,
    'createdAt' DATETIME DEFAULT CURRENT_TIMESTAMP,
    'updatedAt' DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY ('id'),
    FOREIGN KEY ('createdById') REFERENCES 'User' ('id')
);
''';

  static String createOrderedProductTable = '''
CREATE TABLE IF NOT EXISTS '$orderedProductTableName' (
    'id' INTEGER NOT NULL,
    'transactionId' INTEGER,
    'productId' INTEGER,
    'quantity' INTEGER,
    'stock' INTEGER,
    'name' TEXT,
    'imageUrl' TEXT,
    'price' INTEGER,
    'createdAt' DATETIME DEFAULT CURRENT_TIMESTAMP,
    'updatedAt' DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY ('id'),
    FOREIGN KEY ('transactionId') REFERENCES 'Transaction' ('id'),
    FOREIGN KEY ('productId') REFERENCES 'Product' ('id')
);
''';

  static String createQueuedActionTable = '''
CREATE TABLE IF NOT EXISTS '$queuedActionTableName' (
    'id' INTEGER NOT NULL,
    'repository' TEXT,
    'method' TEXT,
    'param' TEXT,
    'isCritical' INTEGER,
    'createdAt' DATETIME DEFAULT CURRENT_TIMESTAMP
);
''';
}
