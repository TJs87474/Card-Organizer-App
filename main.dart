import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'screens/cards_screen.dart';  

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
  List<Map<String, dynamic>> folders = [];

  @override
  void initState() {
    super.initState();
    initDatabase();
  }

  Future<void> initDatabase() async {
    String path = join(await getDatabasesPath(), 'cards_database.db');
    db = await openDatabase(
      path,
      onCreate: (db, version) {
        db.execute("CREATE TABLE Folders(id INTEGER PRIMARY KEY, name TEXT)");
        db.execute("CREATE TABLE Cards(id INTEGER PRIMARY KEY, name TEXT, folder_id INTEGER, FOREIGN KEY(folder_id) REFERENCES Folders(id))");
      },
      version: 1,
    );
    fetchFolders();
  }

  Future<void> fetchFolders() async {
    final List<Map<String, dynamic>> folderData = await db.query('Folders');
    setState(() {
      folders = folderData;
    });
  }

  Future<int> getCardCount(int folderId) async {
    final count = await db.rawQuery("SELECT COUNT(*) as count FROM Cards WHERE folder_id = ?", [folderId]);
    return Sqflite.firstIntValue(count) ?? 0;
  }

  Future<String?> getFolderPreviewImage(int folderId) async {
    final cards = await db.query('Cards', where: 'folder_id = ?', whereArgs: [folderId], limit: 1);
    return cards.isNotEmpty ? cards[0]['name'] as String: null; // Use card name as preview
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Card Organizer")),
      body: isDbInitialized
          ? ListView.builder(
              itemCount: folders.length,
              itemBuilder: (context, index) {
                final folder = folders[index];
                return FutureBuilder<String?>(
                  future: getFolderPreviewImage(folder['id']),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    String? previewImage = snapshot.data;
                    return ListTile(
                      leading: previewImage != null
                          ? Image.asset(previewImage) // Display preview image (could be a card image)
                          : const Icon(Icons.image),
                      title: Text(folder['name']),
                      subtitle: FutureBuilder<int>(
                        future: getCardCount(folder['id']),
                        builder: (context, cardCountSnapshot) {
                          if (cardCountSnapshot.connectionState == ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          }
                          int cardCount = cardCountSnapshot.data ?? 0;
                          return Text('$cardCount cards');
                        },
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CardsScreen(folderId: folder['id']),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
