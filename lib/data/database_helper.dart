import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:ntakomisiyo1/models/product.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  static const int _databaseVersion = 2; // Increment version number

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'ntakomisiyo.db');
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE favorites(
        id TEXT PRIMARY KEY,
        name TEXT,
        description TEXT,
        price REAL,
        imageUrl TEXT,
        category TEXT,
        sellerId TEXT,
        createdAt TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add createdAt column if upgrading from version 1
      await db.execute('ALTER TABLE favorites ADD COLUMN createdAt TEXT');
    }
  }

  Future<void> toggleFavorite(Product product) async {
    final db = await database;
    final isProductFavorite = await isFavorite(product.id);

    if (isProductFavorite) {
      await db.delete(
        'favorites',
        where: 'id = ?',
        whereArgs: [product.id],
      );
    } else {
      await db.insert(
        'favorites',
        {
          'id': product.id,
          'name': product.name,
          'description': product.description,
          'price': product.price,
          'imageUrl': product.imageUrl,
          'category': product.category,
          'sellerId': product.sellerId,
          'createdAt': product.createdAt.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<bool> isFavorite(String productId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'favorites',
      where: 'id = ?',
      whereArgs: [productId],
    );
    return maps.isNotEmpty;
  }

  Future<List<Product>> getFavorites() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('favorites');

    return List.generate(maps.length, (i) {
      return Product(
        id: maps[i]['id'],
        name: maps[i]['name'],
        description: maps[i]['description'],
        price: maps[i]['price'],
        imageUrl: maps[i]['imageUrl'],
        category: maps[i]['category'],
        sellerId: maps[i]['sellerId'],
        sellerPhone: maps[i]['sellerPhone'] ?? '+250780600494',
        createdAt: DateTime.parse(maps[i]['createdAt']),
      );
    });
  }
}
