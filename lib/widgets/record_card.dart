import 'package:db/models/user.dart';
import 'package:flutter/material.dart';

class RecordCard extends StatelessWidget {
  final Map<String, dynamic> record;
  final UserRole? userRole;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const RecordCard({
    super.key,
    required this.record,
    this.userRole,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  // Безопасное получение цвета
  Color _getCardColor() {
    if (record['color'] is Color) {
      return record['color'] as Color;
    }
    return Colors.blue; // fallback
  }

  // Безопасное получение иконки
  IconData _getIcon() {
    if (record['icon'] is IconData) {
      return record['icon'] as IconData;
    }
    return Icons.info;
  }

  // Безопасное получение статуса цвета
  Color _getStatusColor(String? status) {
    final s = status?.toLowerCase() ?? '';
    if (s.contains('подтвержден') ||
        s.contains('активен') ||
        s.contains('вручен') ||
        s.contains('победитель')) {
      return Colors.green;
    }
    if (s.contains('на рассмотрении') || s.contains('назначен')) {
      return Colors.orange;
    }
    if (s.contains('оценена')) {
      return Colors.blue;
    }
    if (s.contains('отклонен') || s.contains('удален')) {
      return Colors.red;
    }
    return Colors.grey;
  }

  // Безопасное получение списка бейджей как List<String>
  List<String> _getBadges() {
    final List<String> badges = [];
    final rawBadges = record['badges'];

    if (rawBadges == null) return badges;

    if (rawBadges is List) {
      for (var badge in rawBadges) {
        badges.add(badge.toString());
      }
    } else if (rawBadges is String) {
      badges.add(rawBadges);
    }

    return badges;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getCardColor();
    final icon = _getIcon();
    final title = record['title']?.toString() ?? 'Без названия';
    final subtitle = record['subtitle']?.toString() ?? '';
    final status = record['status']?.toString() ?? 'Не определён';
    final type = record['type']?.toString() ?? '';
    final date = record['date']?.toString() ?? '';
    final badges = _getBadges();

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Верхняя строка: иконка типа + заголовок + статус
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Иконка типа
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 12),

                  // Заголовок и статус
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2C3E50),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(status),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                status,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(color: Colors.grey, fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Бейджики
              if (badges.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: badges.map((badge) {
                      return Chip(
                        label: Text(
                          badge,
                          style: const TextStyle(fontSize: 11),
                        ),
                        backgroundColor: Colors.grey[100],
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
                  ),
                ),

              // Нижняя строка: дата, тип и действия
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    // Дата и тип
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(date, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(width: 12),
                        const Icon(Icons.category, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(type, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),

                    const Spacer(),

                    // Кнопки действий (только для админа/модератора/жюри)
                    if (userRole == UserRole.admin ||
                        userRole == UserRole.moderator ||
                        userRole == UserRole.jury)
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_red_eye, size: 18, color: Colors.grey),
                            onPressed: onTap,
                            tooltip: 'Просмотр',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          if (onEdit != null)
                            IconButton(
                              icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                              onPressed: onEdit,
                              tooltip: 'Редактировать',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          if (onDelete != null &&
                              (userRole == UserRole.admin || userRole == UserRole.moderator))
                            IconButton(
                              icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                              onPressed: onDelete,
                              tooltip: 'Удалить',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}