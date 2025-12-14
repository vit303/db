import 'package:db/models/user.dart';
import 'package:db/services/postgres_service.dart';
import 'package:db/widgets/record_card.dart';
import 'package:flutter/material.dart';

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
  final List<Map<String, dynamic>> _records = [];
  final List<Map<String, dynamic>> _filteredRecords = [];
  String _selectedFilter = 'Все';
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  late TabController _tabController;
  int _activeTab = 0;

  final List<String> _filters = [
    'Все',
    'Участники',
    'Конкурсные работы',
    'Научные руководители',
    'Секции',
    'Награды',
    'Волонтеры',
    'Жюри',
    'Учебные заведения',
  ];

  final List<String> _tabs = [
    'Все',
    'Участники',
    'Работы',
    'Секции',
  ];

  // Демо-данные на случай ошибки
  final List<Map<String, dynamic>> _sampleData = [
    {
      'id': 1,
      'type': 'Участник',
      'title': 'Иванов Александр Петрович',
      'subtitle': '10А класс, НГТУ, Новосибирск',
      'description': 'Работа: "Разработка системы распознавания образов"\nEmail: a.ivanov@edu.nstu.ru\nТелефон: +79131234577',
      'status': 'Подтвержден',
      'date': '15.03.2025',
      'color': Colors.blue,
      'icon': Icons.person,
      'badges': ['Онлайн', '10 класс'],
      'actions': ['Просмотр', 'Редактировать', 'Выдать сертификат'],
    },
    {
      'id': 2,
      'type': 'Конкурсная работа',
      'title': 'Разработка системы распознавания образов',
      'subtitle': 'Секция: Информационные технологии',
      'description': 'Автор: Иванов А.П.\nНаучный руководитель: Петров И.С.\nСсылка: https://drive.google.com/work1',
      'status': 'На рассмотрении',
      'date': '20.03.2025',
      'color': Colors.green,
      'icon': Icons.assignment,
      'badges': ['IT секция', 'Ссылка приложена'],
      'actions': ['Оценить', 'Просмотр работы', 'Назначить жюри'],
    },
    // Добавьте остальные демо-записи по желанию
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _selectedFilter = widget.initialFilter ?? 'Все';
    _loadRecords();
    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        _activeTab = _tabController.index;
        _selectedFilter = _tabs[_activeTab];
        _filterRecords();
      });
    }
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    _records.clear();

    try {
      final participants = await PostgresService.executeQuery('''
        SELECT 
          p.id, p.surname, p.name, p.fathername, p.class_number,
          c.city_name, ei.educational_institution_name,
          cw.title AS work_title, p.participant_format
        FROM Participant p
        LEFT JOIN City c ON p.city_id = c.id
        LEFT JOIN Educational_institution ei ON p.educational_institution_id = ei.id
        LEFT JOIN Competitive_work cw ON p.competitive_work_id = cw.id
        ORDER BY p.surname, p.name
      ''');

      final works = await PostgresService.executeQuery('''
        SELECT 
          cw.id, cw.title,
          s.section_name,
          p.surname AS participant_surname, p.name AS participant_name,
          ss.surname AS supervisor_surname, ss.name AS supervisor_name
        FROM Competitive_work cw
        LEFT JOIN Sections s ON cw.section_id = s.id
        LEFT JOIN Participant p ON cw.participant_id = p.id
        LEFT JOIN Scientific_supervisor ss ON cw.scientific_supervisor_id = ss.id
        ORDER BY cw.title
      ''');

      final sections = await PostgresService.executeQuery('''
        SELECT 
          s.id, s.section_name, s.description, s.connection_link, s.auditorium,
          COUNT(DISTINCT cw.id) AS work_count,
          COUNT(DISTINCT v.id) AS volunteer_count
        FROM Sections s
        LEFT JOIN Competitive_work cw ON s.id = cw.section_id
        LEFT JOIN Volunteers_on_sections vs ON s.id = vs.section_id
        LEFT JOIN Volunteer v ON vs.volunteer_id = v.id
        GROUP BY s.id
        ORDER BY s.section_name
      ''');

      // Участники
      for (final p in participants) {
        _records.add({
          'id': p['id'],
          'type': 'Участник',
          'title': '${p['surname']} ${p['name']} ${p['fathername'] ?? ''}'.trim(),
          'subtitle': '${p['class_number']} класс, ${p['educational_institution_name'] ?? 'Не указано'}',
          'description': 'Город: ${p['city_name'] ?? 'Не указан'}\nРабота: ${p['work_title'] ?? 'Не подана'}',
          'status': p['work_title'] != null ? 'Работа подана' : 'Зарегистрирован',
          'date': 'Зарегистрирован',
          'color': Colors.blue,
          'icon': Icons.person,
          'badges': [p['participant_format'] ?? 'Очный', p['class_number'] ?? ''],
          'actions': ['Просмотр', 'Редактировать', 'Сертификат'],
        });
      }

      // Работы
      for (final w in works) {
        _records.add({
          'id': w['id'],
          'type': 'Конкурсная работа',
          'title': w['title'],
          'subtitle': 'Секция: ${w['section_name'] ?? 'Не указана'}\nУчастник: ${w['participant_surname']} ${w['participant_name']}',
          'description': 'Руководитель: ${w['supervisor_surname']} ${w['supervisor_name']}',
          'status': 'На рассмотрении',
          'date': 'Подана',
          'color': Colors.green,
          'icon': Icons.assignment,
          'badges': [w['section_name'] ?? 'Без секции'],
          'actions': ['Оценить', 'Просмотр', 'Жюри'],
        });
      }

      // Секции
      for (final s in sections) {
        _records.add({
          'id': s['id'],
          'type': 'Секция',
          'title': s['section_name'],
          'subtitle': 'Аудитория: ${s['auditorium'] ?? 'Онлайн'}',
          'description': '${s['description'] ?? ''}\nСсылка: ${s['connection_link'] ?? 'Нет'}',
          'status': 'Активна',
          'date': 'Создана',
          'color': Colors.purple,
          'icon': Icons.category,
          'badges': ['${s['work_count']} работ', '${s['volunteer_count']} волонтёров'],
          'actions': ['Расписание', 'Участники', 'Настройки'],
        });
      }

      setState(() => _filterRecords());
    } catch (e) {
      print('Ошибка загрузки из БД: $e');
      _records.addAll(_sampleData);
      setState(() => _filterRecords());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterRecords() {
    if (_selectedFilter == 'Все') {
      _filteredRecords.clear();
      _filteredRecords.addAll(_records);
      return;
    }

    String targetType = '';
    switch (_selectedFilter) {
      case 'Участники':
        targetType = 'Участник';
        break;
      case 'Конкурсные работы':
        targetType = 'Конкурсная работа';
        break;
      case 'Секции':
        targetType = 'Секция';
        break;
      default:
        targetType = _selectedFilter;
    }

    _filteredRecords.clear();
    _filteredRecords.addAll(_records.where((r) => r['type'] == targetType).toList());
  }

  List<Map<String, dynamic>> _getSearchedRecords() {
    if (_searchController.text.isEmpty) return _filteredRecords;

    final query = _searchController.text.toLowerCase();
    return _filteredRecords.where((r) {
      final title = (r['title'] as String?) ?? '';
      final subtitle = (r['subtitle'] as String?) ?? '';
      final description = (r['description'] as String?) ?? '';
      return title.toLowerCase().contains(query) ||
          subtitle.toLowerCase().contains(query) ||
          description.toLowerCase().contains(query);
    }).toList();
  }

  void _refreshData() async {
    await _loadRecords();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Данные обновлены'), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchedRecords = _getSearchedRecords();

    return Scaffold(
      appBar: AppBar(title: const Text('Записи')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : searchedRecords.isEmpty
              ? const Center(child: Text('Нет данных'))
              : ListView.builder(
                  itemCount: searchedRecords.length,
                  itemBuilder: (context, index) {
                    final record = searchedRecords[index];
                    return RecordCard(
                      record: record,
                      userRole: widget.userRole,
                      onTap: () {
                        // _showRecordDetails(record);
                      },
                      onEdit: widget.userRole == UserRole.admin || widget.userRole == UserRole.moderator
                          ? () {
                              // _showEditDialog(record);
                            }
                          : null,
                      onDelete: widget.userRole == UserRole.admin
                          ? () {
                              // _showDeleteDialog(record);
                            }
                          : null,
                    );
                  },
                ),
      floatingActionButton: (widget.userRole == UserRole.admin || widget.userRole == UserRole.moderator)
          ? FloatingActionButton(
              onPressed: _refreshData,
              child: const Icon(Icons.refresh),
            )
          : null,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}