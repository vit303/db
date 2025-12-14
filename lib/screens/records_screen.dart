import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:db/models/user.dart';
import 'package:db/services/postgres_service.dart';
import 'package:db/widgets/record_card.dart';

class RecordsScreen extends StatefulWidget {
  final UserRole userRole;
  final String? initialFilter;

  const RecordsScreen({
    super.key,
    required this.userRole,
    this.initialFilter,
  });

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> with SingleTickerProviderStateMixin {
  final List<Map<String, dynamic>> _allRecords = [];
  List<Map<String, dynamic>> _displayedRecords = [];
  String _selectedTab = 'Все';
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  late TabController _tabController;

  final List<String> _tabs = [
    'Все',
    'Участники',
    'Работы',
    'Секции',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _selectedTab = widget.initialFilter ?? 'Все';
    _tabController.index = _tabs.indexOf(_selectedTab);
    _loadRecords();
    _searchController.addListener(_applySearch);
    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        _selectedTab = _tabs[_tabController.index];
        _applyFilterAndSearch();
      });
    }
  }

  void _applySearch() {
    setState(() {
      _applyFilterAndSearch();
    });
  }

  void _applyFilterAndSearch() {
    List<Map<String, dynamic>> temp = List.from(_allRecords);

    // Фильтр по табу
    if (_selectedTab != 'Все') {
      final targetType = switch (_selectedTab) {
        'Участники' => 'Участник',
        'Работы' => 'Конкурсная работа',
        'Секции' => 'Секция',
        _ => '',
      };
      temp = temp.where((r) => r['type'] == targetType).toList();
    }

    // Поиск
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      temp = temp.where((r) {
        return (r['title']?.toString() ?? '').toLowerCase().contains(query) ||
            (r['subtitle']?.toString() ?? '').toLowerCase().contains(query) ||
            (r['description']?.toString() ?? '').toLowerCase().contains(query) ||
            (r['status']?.toString() ?? '').toLowerCase().contains(query);
      }).toList();
    }

    _displayedRecords = temp;
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    _allRecords.clear();

    try {
      // Участники + работа
      final participants = await PostgresService.executeQuery('''
        SELECT 
          p.id AS participant_id, p.surname, p.name, p.fathername, p.class_number,
          c.city_name, ei.educational_institution_name,
          p.participant_format, p.email, p.phone_number, p.consent_link,
          cw.id AS work_id, cw.title AS work_title, cw.works_link,
          s.section_name,
          ss.surname AS supervisor_surname, ss.name AS supervisor_name
        FROM participant p
        LEFT JOIN city c ON p.city_id = c.id
        LEFT JOIN educational_institution ei ON p.educational_institution_id = ei.id
        LEFT JOIN competitive_work cw ON p.competitive_work_id = cw.id
        LEFT JOIN sections s ON cw.section_id = s.id
        LEFT JOIN scientific_supervisor ss ON cw.scientific_supervisor_id = ss.id
        ORDER BY p.surname, p.name
      ''');

      // Конкурсные работы
      final works = await PostgresService.executeQuery('''
        SELECT 
          cw.id, cw.title, cw.works_link,
          s.section_name,
          p.surname AS participant_surname, p.name AS participant_name, p.fathername AS participant_fathername,
          ss.surname AS supervisor_surname, ss.name AS supervisor_name
        FROM competitive_work cw
        LEFT JOIN sections s ON cw.section_id = s.id
        LEFT JOIN participant p ON cw.participant_id = p.id
        LEFT JOIN scientific_supervisor ss ON cw.scientific_supervisor_id = ss.id
        ORDER BY cw.title
      ''');

      // Секции
      final sections = await PostgresService.executeQuery('''
        SELECT 
          s.id, s.section_name, s.description, s.connection_link, s.auditorium
        FROM sections s
        ORDER BY s.section_name
      ''');

      // Участники
      for (final p in participants) {
        final hasWork = p['work_id'] != null;

        _allRecords.add({
          'id': p['participant_id'],
          'table': 'participant',
          'type': 'Участник',
          'title': '${p['surname']} ${p['name']} ${p['fathername'] ?? ''}'.trim(),
          'subtitle': '${p['class_number']} класс, ${p['educational_institution_name'] ?? 'Не указано'}',
          'description': 'Город: ${p['city_name'] ?? 'Не указан'}\n'
              '${hasWork ? 'Работа: ${p['work_title']}\nСекция: ${p['section_name'] ?? 'Не указана'}\nРуководитель: ${p['supervisor_surname']} ${p['supervisor_name']}\nСсылка: ${p['works_link'] ?? 'Нет'}' : 'Работа: Не подана'}\n'
              'Email: ${p['email'] ?? '—'}\n'
              'Телефон: ${p['phone_number'] ?? '—'}\n'
              'Согласие: ${p['consent_link'] != null ? 'Есть' : 'Нет'}',
          'status': hasWork ? 'Работа подана' : 'Зарегистрирован',
          'color': Colors.blue,
          'icon': Icons.person,
          'badges': [
            p['participant_format'] ?? 'Очный',
            p['class_number'] ?? '',
          ],
          'raw_data': p,
          'linked_work_id': p['work_id'],
          'work_title': hasWork ? p['work_title'] : null,
        });
      }

      // Конкурсные работы
      for (final w in works) {
        _allRecords.add({
          'id': w['id'],
          'table': 'competitive_work',
          'type': 'Конкурсная работа',
          'title': w['title'],
          'subtitle': 'Секция: ${w['section_name'] ?? 'Не указана'}',
          'description': 'Участник: ${w['participant_surname']} ${w['participant_name']} ${w['participant_fathername'] ?? ''}\n'
              'Руководитель: ${w['supervisor_surname']} ${w['supervisor_name']}\n'
              'Ссылка: ${w['works_link'] ?? 'Нет'}',
          'status': 'На рассмотрении',
          'color': Colors.green,
          'icon': Icons.assignment,
          'badges': [w['section_name'] ?? 'Без секции'],
          'raw_data': w,
        });
      }

      // Секции
      for (final s in sections) {
        _allRecords.add({
          'id': s['id'],
          'table': 'sections',
          'type': 'Секция',
          'title': s['section_name'],
          'subtitle': 'Аудитория: ${s['auditorium'] ?? 'Онлайн'}',
          'description': '${s['description'] ?? 'Нет описания'}\nСсылка: ${s['connection_link'] ?? 'Нет'}',
          'status': 'Активна',
          'color': Colors.purple,
          'icon': Icons.category,
          'badges': ['Секция'],
          'raw_data': s,
        });
      }

      _applyFilterAndSearch();
    } catch (e) {
      print('Ошибка загрузки данных: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Детальный просмотр с кликабельной ссылкой на работу
  void _showDetails(Map<String, dynamic> record) {
    final lines = record['description'].split('\n');
    final hasWork = record['linked_work_id'] != null;
    final workTitle = record['work_title'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(record['title']),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: lines.map<Widget>((line) {
              if (hasWork && line.startsWith('Работа:')) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.black, fontSize: 14),
                      children: [
                        const TextSpan(text: 'Работа: '),
                        TextSpan(
                          text: workTitle,
                          style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.pop(context);
                              _editWork(record['linked_work_id']);
                            },
                        ),
                      ],
                    ),
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(line, style: const TextStyle(fontSize: 14)),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Закрыть')),
        ],
      ),
    );
  }

  // Редактирование конкурсной работы
  Future<void> _editWork(int? workId) async {
    if (workId == null) return;

    final workData = await PostgresService.executeQuery('''
      SELECT id, title, works_link
      FROM competitive_work
      WHERE id = $workId
    ''');

    if (workData.isEmpty) return;

    final work = workData.first;
    final titleController = TextEditingController(text: work['title']?.toString() ?? '');
    final linkController = TextEditingController(text: work['works_link']?.toString() ?? '');

    final success = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Редактирование конкурсной работы'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Название работы', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: linkController,
              decoration: const InputDecoration(labelText: 'Ссылка на работу', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Сохранить')),
        ],
      ),
    );

    if (success != true) return;

    final params = {
      'id': workId,
      'title': titleController.text.trim(),
      'works_link': linkController.text.trim().isEmpty ? null : linkController.text.trim(),
    };

    final updateSuccess = await PostgresService.executeUpdate('''
      UPDATE competitive_work
      SET title = @title, works_link = @works_link
      WHERE id = @id
    ''', params);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(updateSuccess ? 'Работа обновлена' : 'Ошибка'), backgroundColor: updateSuccess ? Colors.green : Colors.red),
    );

    if (updateSuccess) _loadRecords();
  }

  // Редактирование основной записи
  void _editRecord(Map<String, dynamic> record) async {
    if (record['type'] == 'Конкурсная работа') {
      _editWork(record['id']);
      return;
    }

    final table = record['table'] as String;
    final rawData = record['raw_data'] as Map<String, dynamic>;

    final editableFields = rawData.keys.where((k) => k != 'id').toList();
    final controllers = <String, TextEditingController>{};

    for (var field in editableFields) {
      controllers[field] = TextEditingController(text: rawData[field]?.toString() ?? '');
    }

    final success = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Редактирование: ${record['type']}'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView(
            children: editableFields.map((field) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: TextField(
                  controller: controllers[field],
                  decoration: InputDecoration(labelText: field.toUpperCase(), border: OutlineInputBorder()),
                  maxLines: field.contains('description') || field.contains('link') ? 3 : 1,
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Сохранить')),
        ],
      ),
    );

    if (success != true) return;

    final setParts = <String>[];
    final params = <String, dynamic>{'id': record['id']};

    for (var field in editableFields) {
      final value = controllers[field]!.text.trim();
      params[field] = value.isEmpty ? null : value;
      setParts.add('$field = @$field');
    }

    final sql = 'UPDATE $table SET ${setParts.join(', ')} WHERE id = @id';

    final updateSuccess = await PostgresService.executeUpdate(sql, params);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(updateSuccess ? 'Запись обновлена' : 'Ошибка'), backgroundColor: updateSuccess ? Colors.green : Colors.red),
    );

    if (updateSuccess) _loadRecords();
  }

  // Удаление
  void _deleteRecord(Map<String, dynamic> record) async {
    final table = record['table'] as String;
    final id = record['id'];

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить запись?'),
        content: Text('Удалить "${record['title']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await PostgresService.executeUpdate(
      'DELETE FROM $table WHERE id = @id',
      {'id': id},
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'Запись удалена' : 'Ошибка'), backgroundColor: success ? Colors.green : Colors.red),
    );

    if (success) _loadRecords();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Записи конференции'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadRecords),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Поиск по записям...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: _searchController.clear,
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _displayedRecords.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _searchController.text.isEmpty ? Icons.inbox : Icons.search_off,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchController.text.isEmpty ? 'Нет записей' : 'Ничего не найдено',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _displayedRecords.length,
                  itemBuilder: (context, index) {
                    final record = _displayedRecords[index];
                    return RecordCard(
                      record: record,
                      userRole: widget.userRole,
                      onTap: () => _showDetails(record),
                      onEdit: (widget.userRole == UserRole.admin || widget.userRole == UserRole.moderator)
                          ? () => _editRecord(record)
                          : null,
                      onDelete: widget.userRole == UserRole.admin ? () => _deleteRecord(record) : null,
                    );
                  },
                ),
      floatingActionButton: (widget.userRole == UserRole.admin || widget.userRole == UserRole.moderator)
          ? FloatingActionButton(
              onPressed: _loadRecords,
              child: const Icon(Icons.refresh),
            )
          : null,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.removeListener(_applySearch);
    _searchController.dispose();
    super.dispose();
  }
}