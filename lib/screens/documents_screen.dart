import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../services/postgres_service.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final TextEditingController _sqlController = TextEditingController();

  List<Map<String, dynamic>> result = [];
  bool isLoading = false;
  String error = '';

  // 3 готовых запроса, адаптированных под твою БД
  final List<String> _predefinedQueries = [
    // 1. Участники определённой секции
    """
    SELECT * FROM participant;
    """,

    // 2. Рейтинг работ по наличию наград (замена оценки жюри, так как таблицы Jury_evaluation нет)
    """
    SELECT 
      s.section_name,
      cw.title AS work_title,
      p.surname || ' ' || p.name || ' ' || COALESCE(p.fathername, '') AS participant,
      COALESCE(c.certificate_degree, 'Без награды') AS award
    FROM Competitive_work cw
    JOIN Participant p ON cw.participant_id = p.id
    JOIN Sections s ON cw.section_id = s.id
    LEFT JOIN Certificate c ON p.id = c.participant_id
    ORDER BY 
      CASE 
        WHEN c.certificate_degree LIKE '%I степени%' THEN 1
        WHEN c.certificate_degree LIKE '%II степени%' THEN 2
        WHEN c.certificate_degree LIKE '%III степени%' THEN 3
        ELSE 4
      END,
      s.section_name,
      p.surname
    """,

    // 3. Участники из определённого города с учебным заведением
    """
    SELECT 
      p.surname || ' ' || p.name || ' ' || COALESCE(p.fathername, '') AS fio,
      c.city_name,
      ei.educational_institution_name,
      p.class_number,
      p.participant_format
    FROM Participant p
    JOIN City c ON p.city_id = c.id
    JOIN Educational_institution ei ON p.educational_institution_id = ei.id
    WHERE c.city_name = 'Новосибирск'
    ORDER BY p.surname
    """,
  ];

  final List<String> _queryNames = [
    'Все участники',
    'Рейтинг работ по наградам (I, II, III степень)',
    'Участники из Новосибирска (с учебным заведением)',
  ];

  @override
  void initState() {
    super.initState();
    _sqlController.text = _predefinedQueries[0];
  }

  Future<void> _executeQuery() async {
    final query = _sqlController.text.trim();
    if (query.isEmpty) {
      setState(() => error = 'Введите SQL-запрос');
      return;
    }

    setState(() {
      isLoading = true;
      error = '';
      result = [];
    });

    try {
      final data = await PostgresService.executeQuery(query);
      setState(() => result = data);
    } catch (e) {
      setState(() => error = 'Ошибка выполнения запроса: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _exportToCsv() async {
    if (result.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нет данных для экспорта')),
      );
      return;
    }

    try {
      List<List<dynamic>> rows = [];
      rows.add(result.first.keys.toList()); // заголовки

      for (var row in result) {
        rows.add(row.values.toList());
      }

      String csv = const ListToCsvConverter().convert(rows);

      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/query_result_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File(path);
      await file.writeAsString(csv);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Экспорт успешен: $path'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка экспорта: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Документы и запросы'),
        actions: [
          if (result.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Экспорт в CSV',
              onPressed: _exportToCsv,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<int>(
              value: 0,
              decoration: const InputDecoration(
                labelText: 'Готовые запросы',
                border: OutlineInputBorder(),
              ),
              items: _queryNames.asMap().entries.map((e) {
                return DropdownMenuItem(value: e.key, child: Text(e.value));
              }).toList(),
              onChanged: (index) {
                if (index != null) {
                  _sqlController.text = _predefinedQueries[index];
                  result = [];
                  error = '';
                }
              },
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _sqlController,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'SQL-запрос (только SELECT)',
                border: OutlineInputBorder(),
                hintText: 'Введите свой запрос...',
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _executeQuery,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Выполнить запрос'),
              ),
            ),

            if (error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(error, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ),

            const SizedBox(height: 10),

            Expanded(
              child: result.isEmpty
                  ? Center(
                      child: Text(
                        error.isEmpty ? 'Результаты появятся после выполнения запроса' : '',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          headingRowHeight: 56,
                          columns: result.first.keys
                              .map((key) => DataColumn(
                                    label: Text(key.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ))
                              .toList(),
                          rows: result
                              .map((row) => DataRow(
                                    cells: row.values
                                        .map((v) => DataCell(Text(v?.toString() ?? '', overflow: TextOverflow.ellipsis)))
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

  @override
  void dispose() {
    _sqlController.dispose();
    super.dispose();
  }
}