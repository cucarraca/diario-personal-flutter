import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const DiarioApp());
}

class DiaryEntry {
  final String id;
  final String title;
  final String content;
  final DateTime dateTime;

  DiaryEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.dateTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'dateTime': dateTime.toIso8601String(),
    };
  }

  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    return DiaryEntry(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      dateTime: DateTime.parse(json['dateTime']),
    );
  }
}

class DiarioApp extends StatelessWidget {
  const DiarioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diario Personal',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const DiaryHomePage(),
    );
  }
}

class DiaryHomePage extends StatefulWidget {
  const DiaryHomePage({super.key});

  @override
  State<DiaryHomePage> createState() => _DiaryHomePageState();
}

class _DiaryHomePageState extends State<DiaryHomePage> {
  List<DiaryEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final entriesJson = prefs.getStringList('diary_entries') ?? [];
    
    setState(() {
      _entries = entriesJson
          .map((entryJson) => DiaryEntry.fromJson(json.decode(entryJson)))
          .toList();
      // Sort entries by date (newest first)
      _entries.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    });
  }

  Future<void> _saveEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final entriesJson = _entries
        .map((entry) => json.encode(entry.toJson()))
        .toList();
    await prefs.setStringList('diary_entries', entriesJson);
  }

  void _addNewEntry() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EntryEditorPage(
          onSave: (title, content) {
            final newEntry = DiaryEntry(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              title: title,
              content: content,
              dateTime: DateTime.now(),
            );
            
            setState(() {
              _entries.insert(0, newEntry);
            });
            
            _saveEntries();
          },
        ),
      ),
    );
  }

  void _viewEntry(DiaryEntry entry) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EntryViewerPage(entry: entry),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Diario Personal'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _entries.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.book_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No tienes entradas aún',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    'Presiona el botón + para crear tu primera entrada',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _entries.length,
              itemBuilder: (context, index) {
                final entry = _entries[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    title: Text(
                      entry.title.isNotEmpty ? entry.title : 'Entrada sin título',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${entry.dateTime.day}/${entry.dateTime.month}/${entry.dateTime.year} - ${entry.dateTime.hour}:${entry.dateTime.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          entry.content.length > 100
                              ? '${entry.content.substring(0, 100)}...'
                              : entry.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    leading: const CircleAvatar(
                      child: Icon(Icons.edit_note),
                    ),
                    onTap: () => _viewEntry(entry),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewEntry,
        tooltip: 'Nueva entrada',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class EntryEditorPage extends StatefulWidget {
  final Function(String title, String content) onSave;

  const EntryEditorPage({
    super.key,
    required this.onSave,
  });

  @override
  State<EntryEditorPage> createState() => _EntryEditorPageState();
}

class _EntryEditorPageState extends State<EntryEditorPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  void _saveEntry() {
    if (_contentController.text.trim().isNotEmpty) {
      widget.onSave(
        _titleController.text.trim(),
        _contentController.text.trim(),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, escribe algo en tu entrada'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Entrada'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveEntry,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Título (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _contentController,
                decoration: const InputDecoration(
                  hintText: '¿Qué pasó hoy?',
                  border: OutlineInputBorder(),
                ),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EntryViewerPage extends StatelessWidget {
  final DiaryEntry entry;

  const EntryViewerPage({
    super.key,
    required this.entry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(entry.title.isNotEmpty ? entry.title : 'Entrada'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  '${entry.dateTime.day}/${entry.dateTime.month}/${entry.dateTime.year}',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  '${entry.dateTime.hour}:${entry.dateTime.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  entry.content,
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}