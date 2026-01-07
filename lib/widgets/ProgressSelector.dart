import 'package:flutter/material.dart';

class ProgressSelectorContent extends StatefulWidget {
  final Function(double percentage, String label) onSelected;
  final double? initialPercentage;
  final bool showConfirmButton;

  const ProgressSelectorContent({
    Key? key,
    required this.onSelected,
    this.initialPercentage,
    this.showConfirmButton = true,
  }) : super(key: key);

  @override
  State<ProgressSelectorContent> createState() =>
      _ProgressSelectorContentState();
}

class _ProgressSelectorContentState extends State<ProgressSelectorContent> {
  double? _selectedPercentage;

  @override
  void initState() {
    super.initState();
    _selectedPercentage = widget.initialPercentage;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: ProgressSelector.progressLevels.length,
            itemBuilder: (context, index) {
              final level = ProgressSelector.progressLevels[index];
              final isSelected = _selectedPercentage == level['percentage'];

              return Card(
                elevation: isSelected ? 3 : 1,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: Icon(
                    level['icon'],
                    color: level['color'],
                  ),
                  title: Text(level['label']),
                  subtitle: Text(level['description']),
                  trailing: isSelected
                      ? Icon(Icons.check_circle, color: level['color'])
                      : const Icon(Icons.radio_button_unchecked),
                  onTap: () {
                    setState(() {
                      _selectedPercentage = level['percentage'];
                    });
                    
                    // Auto-trigger callback without confirm button
                    if (!widget.showConfirmButton) {
                      widget.onSelected(
                        level['percentage'],
                        level['label'],
                      );
                    }
                  },
                ),
              );
            },
          ),
        ),

        if (widget.showConfirmButton && _selectedPercentage != null)
          _confirmButton(),
      ],
    );
  }

  Widget _confirmButton() {
    final selected = ProgressSelector.progressLevels.firstWhere(
      (e) => e['percentage'] == _selectedPercentage,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            widget.onSelected(
              selected['percentage'],
              selected['label'],
            );
            Navigator.pop(context);
          },
          child: const Text(
            'Confirm',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}

class ProgressSelector {
  static void show(
    BuildContext context, {
    required Function(double percentage, String label) onSelected,
    double? initialPercentage,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.65,
        child: ProgressSelectorContent(
          onSelected: onSelected,
          initialPercentage: initialPercentage,
          showConfirmButton: true,
        ),
      ),
    );
  }

  static const List<Map<String, dynamic>> progressLevels = [
    {
      'percentage': 0.0,
      'label': 'Missed',
      'description': 'Didn\'t work on it at all',
      'icon': Icons.cancel_outlined,
      'color': Color(0xFFF44336),
    },
    {
      'percentage': 0.25,
      'label': 'Just Tried',
      'description': 'Tiny effort, but far from target',
      'icon': Icons.wb_twilight,
      'color': Color(0xFFFF9800),
    },
    {
      'percentage': 0.50,
      'label': 'Good Progress',
      'description': 'About halfway there',
      'icon': Icons.trending_up,
      'color': Color(0xFFFFC107),
    },
    {
      'percentage': 0.75,
      'label': 'Almost There',
      'description': 'Very close to target',
      'icon': Icons.outlined_flag,
      'color': Color(0xFF8BC34A),
    },
    {
      'percentage': 1.0,
      'label': 'Success',
      'description': 'Fully hit the goal',
      'icon': Icons.check_circle,
      'color': Color(0xFF4CAF50),
    },
  ];
}