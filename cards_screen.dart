import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class CardsScreen extends StatefulWidget {
  final int folderId;

  const CardsScreen({super.key, required this.folderId});

  @override
  _CardsScreenState createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  late Database db;
  List<Map<String, dynamic>> cards = [];

  @override
  void initState() {
    super.initState();
    initDatabase();
  }

  Future<void> initDatabase() async {
    String path = join(await getDatabasesPath(), 'cards_database.db');
    db = await openDatabase(path);
    fetchCards();
  }

  Future<void> fetchCards() async {
    final List<Map<String, dynamic>> cardData = await db.query('Cards', where: 'folder_id = ?', whereArgs: [widget.folderId]);
    setState(() {
      cards = cardData;
    });
  }

  void showSnackBar(String message, {Color color = Colors.red}) {
    ScaffoldMessenger.of(context as BuildContext).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cards in Folder")),
      body: cards.isEmpty
          ? const Center(child: Text('No cards available.'))
          : GridView.builder(
              itemCount: cards.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.75,
              ),
              itemBuilder: (context, index) {
                final card = cards[index];
                return Card(
                  elevation: 4,
                  child: Column(
                    children: [
                      Image.asset('assets/images/${card['name']}.png'), // Assuming card images are stored as assets
                      Text(card['name']),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          await db.delete('Cards', where: 'id = ?', whereArgs: [card['id']]);
                          showSnackBar("Card deleted successfully!", color: Colors.green);
                          fetchCards();
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Show a dialog to add a card
          String cardName = ''; // Add dialog code here
          await db.insert('Cards', {'name': cardName, 'folder_id': widget.folderId});
          showSnackBar("Card added successfully!", color: Colors.green);
          fetchCards();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
