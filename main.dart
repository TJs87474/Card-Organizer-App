import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart'; 

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext appcontext) {
    return MaterialApp(
      home: CardOrganizerApp(),
    );
  }
}

class CardOrganizerApp extends StatefulWidget {
  const CardOrganizerApp({super.key});

  @override
  _CardOrganizerAppState createState() => _CardOrganizerAppState();
}

class _CardOrganizerAppState extends State<CardOrganizerApp> {
  late Database db;
  bool isDbInitialized = false;

  @override
  void initState() {
    super.initState();
    initDatabase();
  }

  Future<void> initDatabase() async {
    // Correctly defining the path before passing it to openDatabase
    String path = join(await getDatabasesPath(), 'cards_database.db');

    db = await openDatabase(
      path,
      onCreate: (db, version) {
        db.execute("CREATE TABLE Folders(id INTEGER PRIMARY KEY, name TEXT)");
        db.execute("CREATE TABLE Cards(id INTEGER PRIMARY KEY, name TEXT, folder_id INTEGER, FOREIGN KEY(folder_id) REFERENCES Folders(id))");
      },
      version: 1,
    );
    setState(() {
      isDbInitialized = true;
    });
  }

  void showSnackBar(BuildContext context, String message, {Color color = Colors.red}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: color, duration: const Duration(seconds: 2)),
  );
}

  Future<int> getCardCount(int folderId) async {
    final count = await db.rawQuery("SELECT COUNT(*) as count FROM Cards WHERE folder_id = ?", [folderId]);
    return Sqflite.firstIntValue(count) ?? 0;
  }

  Future<void> addCard(String cardName, int folderId) async {
    int cardCount = await getCardCount(folderId);
    if (cardCount >= 6) {
      showSnackBar(context as BuildContext, "Folder limit reached! ❌ Max 6 cards allowed.");
      return;
    }
    await db.insert('Cards', {'name': cardName, 'folder_id': folderId});
    showSnackBar(context as BuildContext, "Card added successfully! ✅", color: Colors.green);
    setState(() {});
  }

  Future<void> confirmDeleteFolder(int folderId) async {
    int cardCount = await getCardCount(folderId);
    if (cardCount >= 3) {
      showSnackBar(context as BuildContext, "Cannot delete folder! ❌ Must have fewer than 3 cards.");
      return;
    }

    showDialog(
      context: context as BuildContext,  
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Delete Folder?"),
          content: const Text("Are you sure you want to delete this folder? This action cannot be undone."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                await db.delete('Folders', where: 'id = ?', whereArgs: [folderId]);
                Navigator.of(dialogContext).pop();
                showSnackBar(context as BuildContext,"Folder deleted successfully! ✅", color: Colors.green);
                setState(() {});
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext appContext) {
    if (!isDbInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Card Organizer")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => addCard("Ace of Spades", 1),
              child: const Text("Add Card"),
            ),
            ElevatedButton(
              onPressed: () => confirmDeleteFolder(1),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text("Delete Folder"),
            ),
          ],
        ),
      ),
    );
  }
}
