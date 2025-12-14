import 'package:flutter/material.dart';
import '../services/postgres_service.dart';

class CrudScreen extends StatefulWidget {
  final String tableName;
  final String displayName;

  const CrudScreen({
    super.key,
    required this.tableName,
    this.displayName = '',
  });

  @override
  State<CrudScreen> createState() => _CrudScreenState();
}

class _CrudScreenState extends State<CrudScreen> {
  List<Map<String, dynamic>> rows = [];
  bool isLoading = true;
  String errorMessage = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final data = await PostgresService.executeQuery('SELECT * FROM "${widget.tableName.toLowerCase()}" ORDER BY id');
      setState(() => rows = data);
    } catch (e) {
      setState(() => errorMessage = 'Ошибка загрузки данных: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredRows {
    if (_searchController.text.isEmpty) return rows;

    final query = _searchController.text.toLowerCase();
    return rows.where((row) {
      return row.values.any((value) =>
          value != null && value.toString().toLowerCase().contains(query));
    }).toList();
  }

  void _showAddDialog() {
    final controllers = <String, TextEditingController>{};
    final columns = rows.isEmpty ? [] : rows.first.keys.where((k) => k != 'id').toList();

    for (var col in columns) {
      controllers[col] = TextEditingController();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Добавить запись в ${widget.displayName.isEmpty ? widget.tableName : widget.displayName}'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: columns.map((col) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: TextField(
                  controller: controllers[col],
                  decoration: InputDecoration(labelText: col),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () async {
              final params = <String, dynamic>{};
              for (var entry in controllers.entries) {
                params[entry.key] = entry.value.text.trim().isEmpty ? null : entry.value.text;
              }

              final sql = '''
                INSERT INTO "${widget.tableName.toLowerCase()}" (${columns.join(', ')})
                VALUES (${columns.map((c) => '@$c').join(', ')})
              ''';

              final success = await PostgresService.executeUpdate(sql, params);
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(success ? 'Запись добавлена' : 'Ошибка добавления')),
              );

              if (success) _loadData();
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> row) {
    final controllers = <String, TextEditingController>{};
    final columns = row.keys.where((k) => k != 'id').toList();

    for (var col in columns) {
      controllers[col] = TextEditingController(text: row[col]?.toString() ?? '');
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Редактировать запись'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: columns.map((col) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: TextField(
                  controller: controllers[col],
                  decoration: InputDecoration(labelText: col),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () async {
              final params = <String, dynamic>{'id': row['id']};
              final setParts = <String>[];

              for (var entry in controllers.entries) {
                final value = entry.value.text.trim();
                params[entry.key] = value.isEmpty ? null : value;
                setParts.add('"${entry.key}" = @${entry.key}');
              }

              final sql = '''
                UPDATE "${widget.tableName.toLowerCase()}"
                SET ${setParts.join(', ')}
                WHERE id = @id
              ''';

              final success = await PostgresService.executeUpdate(sql, params);
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(success ? 'Запись обновлена' : 'Ошибка обновления')),
              );

              if (success) _loadData();
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(Map<String, dynamic> row) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить запись?'),
        content: Text('ID: ${row['id']}\n${row.values.where((v) => v != null).take(3).join(', ')}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final success = await PostgresService.executeUpdate(
                'DELETE FROM "${widget.tableName.toLowerCase()}" WHERE id = @id',
                {'id': row['id']},
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(success ? 'Запись удалена' : 'Ошибка удаления')),
              );
              if (success) _loadData();
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.displayName.isEmpty ? widget.tableName : widget.displayName;

    return Scaffold(
      appBar: AppBar(
        title: Text('Справочник: $title'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Поиск...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      })
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage.isNotEmpty
                    ? Center(child: Text(errorMessage, style: const TextStyle(color: Colors.red)))
                    : _filteredRows.isEmpty
                        ? const Center(child: Text('Нет данных'))
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: [
                                const DataColumn(label: Text('ID')),
                                ..._filteredRows.first.keys.where((k) => k != 'id').map((k) => DataColumn(label: Text(k.toUpperCase()))),
                                const DataColumn(label: Text('ДЕЙСТВИЯ')),
                              ],
                              rows: _filteredRows.map((row) {
                                final cells = [
                                  DataCell(Text(row['id'].toString())),
                                  ...row.keys.where((k) => k != 'id').map((k) => DataCell(Text(row[k]?.toString() ?? ''))),
                                  DataCell(
                                    Row(
                                      children: [
                                        IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showEditDialog(row)),
                                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _showDeleteDialog(row)),
                                      ],
                                    ),
                                  ),
                                ];
                                return DataRow(cells: cells);
                              }).toList(),
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
        tooltip: 'Добавить запись',
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}