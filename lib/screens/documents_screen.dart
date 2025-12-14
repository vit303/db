import 'package:flutter/material.dart';
import '../services/postgres_service.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final TextEditingController _sqlController = TextEditingController(
    text: 'SELECT * FROM Participant LIMIT 20',
  );
  List<Map<String, dynamic>> result = [];
  bool isLoading = false;
  String error = '';

  Future<void> _executeQuery() async {
    setState(() {
      isLoading = true;
      error = '';
    });
    try {
      final data = await PostgresService.executeQuery(_sqlController.text);
      setState(() => result = data);
    } catch (e) {
      setState(() => error = 'Ошибка: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Документы и запросы')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _sqlController,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'SQL-запрос',
                border: OutlineInputBorder(),
                hintText: 'Введите SELECT-запрос...',
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: isLoading ? null : _executeQuery,
              child: isLoading ? const CircularProgressIndicator() : const Text('Выполнить запрос'),
            ),
            if (error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(error, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 10),
            Expanded(
              child: result.isEmpty
                  ? const Center(child: Text('Нет результатов'))
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          columns: result.first.keys
                              .map((key) => DataColumn(label: Text(key.toUpperCase())))
                              .toList(),
                          rows: result
                              .map((row) => DataRow(
                                    cells: row.values
                                        .map((v) => DataCell(Text(v?.toString() ?? '')))
                                        .toList(),
                                  ))
                              .toList(),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}