import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:db/services/postgres_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;

  int totalParticipants = 0;
  int totalWorks = 0;
  int totalSections = 0;
  int totalAwards = 0;

  List<PieChartSectionData> roleDistribution = [];
  List<BarChartGroupData> worksBySection = [];
  List<BarChartGroupData> topCities = [];
  List<String> cityNames = [];
  List<PieChartSectionData> supervisorTitles = [];

  final List<String> sectionNames = [
    'Программирование',
    'Робототехника',
    'ИИ и ML',
    'Веб-разработка',
    'Кибербезопасность',
    'Графика и дизайн',
  ];

  // Ключи для захвата графиков в PNG
  final GlobalKey _pieRoleKey = GlobalKey();
  final GlobalKey _barSectionKey = GlobalKey();
  final GlobalKey _barCityKey = GlobalKey();
  final GlobalKey _pieSupervisorKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    try {
      // Основные показатели
      final participantResult = await PostgresService.executeQuery('SELECT COUNT(*) AS count FROM participant');
      final workResult = await PostgresService.executeQuery('SELECT COUNT(*) AS count FROM competitive_work');
      final sectionResult = await PostgresService.executeQuery('SELECT COUNT(*) AS count FROM sections');

      totalParticipants = int.tryParse(participantResult.first['count'].toString()) ?? 0;
      totalWorks = int.tryParse(workResult.first['count'].toString()) ?? 0;
      totalSections = int.tryParse(sectionResult.first['count'].toString()) ?? 0;
      totalAwards = 45; 

     
      roleDistribution = [
        PieChartSectionData(value: totalParticipants.toDouble() * 0.7, color: Colors.blue, title: 'Участники', radius: 60, titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        PieChartSectionData(value: 15, color: Colors.green, title: 'Жюри', radius: 60, titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        PieChartSectionData(value: 10, color: Colors.orange, title: 'Модераторы', radius: 60, titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        PieChartSectionData(value: 5, color: Colors.purple, title: 'Волонтёры', radius: 60, titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      ];

      // Работы по секциям (примерные данные)
      worksBySection = List.generate(sectionNames.length, (i) {
        final values = [25, 18, 22, 15, 12, 8];
        return BarChartGroupData(
          x: i,
          barRods: [BarChartRodData(toY: values[i].toDouble(), color: Colors.blueAccent, width: 16)],
        );
      });

      // Топ-5 городов по количеству участников
      final cityResult = await PostgresService.executeQuery('''
        SELECT c.city_name, COUNT(p.id) AS cnt
        FROM participant p
        JOIN city c ON p.city_id = c.id
        GROUP BY c.city_name
        ORDER BY cnt DESC
        LIMIT 5
      ''');

      cityNames = [];
      topCities = [];
      for (var row in cityResult) {
        final name = row['city_name']?.toString() ?? 'Неизвестно';
        final count = double.tryParse(row['cnt'].toString()) ?? 0;
        cityNames.add(name);
        topCities.add(BarChartGroupData(
          x: cityNames.length - 1,
          barRods: [BarChartRodData(toY: count, color: Colors.teal, width: 20)],
        ));
      }

      // Научные звания научных руководителей
      final titlesResult = await PostgresService.executeQuery('''
        SELECT at.title AS title_name, COUNT(ats.scientific_supervisor_id) AS cnt
        FROM academic_titles_of_scientific_supervisor ats
        JOIN academic_titles at ON ats.academic_title_id = at.id
        GROUP BY at.title
        ORDER BY cnt DESC
      ''');

      supervisorTitles = titlesResult.map<PieChartSectionData>((row) {
        final title = row['title_name']?.toString() ?? 'Без звания';
        final count = double.tryParse(row['cnt'].toString()) ?? 1;
        final colors = [Colors.indigo, Colors.deepOrange, Colors.cyan, Colors.amber, Colors.lime, Colors.teal];
        return PieChartSectionData(
          value: count,
          title: '$title\n${count.toInt()}',
          color: colors[titlesResult.indexOf(row) % colors.length],
          radius: 60,
          titleStyle: const TextStyle(color: ui.Color.fromARGB(255, 3, 3, 3), fontSize: 12, fontWeight: FontWeight.bold),
        );
      }).toList();

      if (supervisorTitles.isEmpty) {
        supervisorTitles = [PieChartSectionData(value: 1, title: 'Нет данных', color: Colors.grey, radius: 60)];
      }
    } catch (e) {
      print('Ошибка загрузки аналитики: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Захват виджета и сохранение в PNG
  Future<void> _captureAndSave(GlobalKey key, String fileName) async {
    try {
      RenderRepaintBoundary boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/$fileName.png';
      final file = File(path);
      await file.writeAsBytes(pngBytes);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('График сохранён: $fileName.png'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка сохранения $fileName: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // Экспорт всех графиков
  Future<void> _exportAllCharts() async {
    await _captureAndSave(_pieRoleKey, 'roles_distribution');
    await _captureAndSave(_barSectionKey, 'works_by_section');
    await _captureAndSave(_barCityKey, 'top_cities');
    await _captureAndSave(_pieSupervisorKey, 'supervisor_titles');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Все графики экспортированы в PNG!'), backgroundColor: Colors.green),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Панель аналитики'),
        actions: [
          IconButton(
            icon: const Icon(Icons.image),
            tooltip: 'Экспорт графиков в PNG',
            onPressed: _exportAllCharts,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAnalytics,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Панель аналитики', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
              const SizedBox(height: 24),

              GridView.count(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.4,
                children: [
                  _buildStatCard('Участников', totalParticipants.toString(), Icons.people, Colors.blue),
                  _buildStatCard('Конкурсных работ', totalWorks.toString(), Icons.assignment_turned_in, Colors.green),
                  _buildStatCard('Секций', totalSections.toString(), Icons.category, Colors.orange),
                  _buildStatCard('Наград вручено', totalAwards.toString(), Icons.emoji_events, Colors.purple),
                ],
              ),

              const SizedBox(height: 32),

              // Распределение по ролям
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Распределение участников по ролям', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      RepaintBoundary(
                        key: _pieRoleKey,
                        child: Container(
                          color: Colors.white,
                          child: SizedBox(
                            height: 220,
                            child: PieChart(
                              PieChartData(
                                sections: roleDistribution,
                                centerSpaceRadius: 50,
                                sectionsSpace: 3,
                                borderData: FlBorderData(show: false),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Количество работ по секциям
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Количество работ по секциям', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      RepaintBoundary(
                        key: _barSectionKey,
                        child: Container(
                          color: Colors.white,
                          child: SizedBox(
                            height: 280,
                            child: BarChart(
                              BarChartData(
                                barGroups: worksBySection,
                                titlesData: FlTitlesData(
                                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 60,
                                      getTitlesWidget: (value, meta) {
                                        final index = value.toInt();
                                        if (index < 0 || index >= sectionNames.length) return const Text('');
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Text(sectionNames[index], style: const TextStyle(fontSize: 10), textAlign: TextAlign.center),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                gridData: FlGridData(show: true),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Топ-5 городов
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Топ-5 городов по количеству участников', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      RepaintBoundary(
                        key: _barCityKey,
                        child: Container(
                          color: Colors.white,
                          child: SizedBox(
                            height: 280,
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                barGroups: topCities,
                                titlesData: FlTitlesData(
                                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 100,
                                      getTitlesWidget: (value, meta) {
                                        final index = value.toInt();
                                        if (index < 0 || index >= cityNames.length) return const Text('');
                                        return Text(cityNames[index], style: const TextStyle(fontSize: 12));
                                      },
                                    ),
                                  ),
                                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                                ),
                                gridData: FlGridData(show: true, drawVerticalLine: false),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Научные звания руководителей
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Научные звания научных руководителей', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      RepaintBoundary(
                        key: _pieSupervisorKey,
                        child: Container(
                          color: Colors.white,
                          child: SizedBox(
                            height: 240,
                            child: PieChart(
                              PieChartData(
                                sections: supervisorTitles,
                                centerSpaceRadius: 50,
                                sectionsSpace: 4,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}