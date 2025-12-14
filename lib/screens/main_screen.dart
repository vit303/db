import 'package:db/models/user.dart';
import 'package:db/screens/records_screen.dart';
import 'package:db/widgets/menu_drawer.dart';
import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  final User? user;
  
  const MainScreen({super.key, required this.user});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late User _currentUser;
  late List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    // Используем переданного пользователя или создаем гостя
    _currentUser = widget.user ?? User.guest(); // Исправлено: widget.user
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Инициализируем виджеты здесь, так как они могут зависеть от контекста
    _widgetOptions = [
      RecordsScreen(userRole: _currentUser.role),
      _buildDashboardScreen(),
      _buildProfileScreen(),
    ];
  }

  Widget _buildDashboardScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.dashboard, size: 100, color: Colors.blueGrey),
          const SizedBox(height: 20),
          Text(
            'Панель управления',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 10),
          Text(
            'Добро пожаловать, ${_currentUser.fullName}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileScreen() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.blueGrey[100],
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.blueGrey[800],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentUser.fullName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Chip(
                          label: Text(
                            _currentUser.role.displayName,
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.blue,
                        ),
                        const SizedBox(height: 10),
                        Text('Email: ${_currentUser.email}'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                _buildStatCard('Работ подано', '156', Icons.assignment),
                _buildStatCard('Участников', '89', Icons.people),
                _buildStatCard('Секций', '10', Icons.category),
                _buildStatCard('Наград', '45', Icons.emoji_events),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.blue),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/logo_small.png',
              height: 30,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.school, color: Colors.white);
              },
            ),
            const SizedBox(width: 10),
            const Text('Научная конференция'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      drawer: MenuDrawer(user: _currentUser),
      body: _widgetOptions.isNotEmpty 
          ? _widgetOptions[_selectedIndex]
          : const Center(child: CircularProgressIndicator()),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Записи',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Панель',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Профиль',
          ),
        ],
      ),
    );
  }
}