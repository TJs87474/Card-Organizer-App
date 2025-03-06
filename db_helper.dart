import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DbHelper {
  static Database? _database;

  // Method to initialize the database
  Future<Database> initDatabase() async {
    if (_database != null) return _database!;

    // Get the path to the database file
    String path = join(await getDatabasesPath(), 'card_organizer.db');

    // Open the database
    _database = await openDatabase(path, version: 1, onCreate: (db, version) {
      // Create the tables if not already present
      db.execute(
        'CREATE TABLE folders(id INTEGER PRIMARY KEY, name TEXT, card_count INTEGER)',
      );
      db.execute(
        'CREATE TABLE cards(id INTEGER PRIMARY KEY, folder_id INTEGER, name TEXT, image_url TEXT)',
      );
    });

    return _database!;
  }

  // Method to get all folders
  Future<List<Map<String, dynamic>>> getFolders() async {
    final db = await initDatabase();
    return await db.query('folders');
  }

  // Method to get all cards for a folder
  Future<List<Map<String, dynamic>>> getCards(int folderId) async {
    final db = await initDatabase();
    return await db.query('cards', where: 'folder_id = ?', whereArgs: [folderId]);
  }

  // Method to get all available cards (those without a folder)
  Future<List<Map<String, dynamic>>> getAvailableCards() async {
    final db = await initDatabase();
    return await db.query('cards', where: 'folder_id IS NULL');
  }

  // Method to add a card to a folder
  Future<void> addCardToFolder(int cardId, int folderId) async {
    final db = await initDatabase();
    await db.update(
      'cards',
      {'folder_id': folderId},
      where: 'id = ?',
      whereArgs: [cardId],
    );
  }

  // Method to remove a card from a folder (set folder_id to null)
  Future<void> removeCard(int cardId) async {
    final db = await initDatabase();
    await db.update(
      'cards',
      {'folder_id': null},
      where: 'id = ?',
      whereArgs: [cardId],
    );
  }
}
