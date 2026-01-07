import 'package:flutter/material.dart';

class DifficultyScoreSelector extends StatelessWidget {
  final int? selectedValue;
  final Function(int value, String term) onSelected;

  const DifficultyScoreSelector({
    Key? key,
    required this.onSelected,
    this.selectedValue,
  }) : super(key: key);

  static const List<Map<String, dynamic>> levels = [
    {
      'value': 10,
      'term': 'Simple',
      'description': "Effortless; I don't even think about it.",
      'color': Colors.green,
      'icon': Icons.sentiment_satisfied_alt,
    },
    {
      'value': 50,
      'term': 'Easy',
      'description': 'A little willpower needed; usually successful.',
      'color': Colors.lightGreen,
      'icon': Icons.sentiment_satisfied,
    },
    {
      'value': 100,
      'term': 'Normal',
      'description': 'The standard challenge; requires focus.',
      'color': Colors.blue,
      'icon': Icons.sentiment_neutral,
    },
    {
      'value': 200,
      'term': 'Hard',
      'description': 'Takes real discipline; might fail sometimes.',
      'color': Colors.orange,
      'icon': Icons.sentiment_dissatisfied,
    },
    {
      'value': 300,
      'term': 'Tough',
      'description': 'A struggle every time; very likely to fail.',
      'color': Colors.deepOrange,
      'icon': Icons.sentiment_very_dissatisfied,
    },
    {
      'value': 400,
      'term': 'Extreme',
      'description': 'Nearly impossible for me right now.',
      'color': Colors.red,
      'icon': Icons.warning_amber_rounded,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: levels.map((level) {
        final bool isSelected = selectedValue == level['value'];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Card(
            elevation: isSelected ? 4 : 1,
            color: isSelected
                ? (level['color'] as Color).withOpacity(0.12)
                : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: level['color'],
                child: Icon(level['icon'], color: Colors.white),
              ),
              title: Text(
                '${level['term']} (${level['value']})',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(level['description']),
              trailing: isSelected
                  ? Icon(Icons.check_circle, color: level['color'])
                  : null,
              onTap: () {
                onSelected(level['value'], level['term']);
              },
            ),
          ),
        );
      }).toList(),
    );
  }
}
