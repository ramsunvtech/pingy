import 'package:flutter/material.dart';

class DifficultySelector extends StatefulWidget {
  final Function(int value, String term) onSelected;
  final int? initialValue;

  const DifficultySelector({
    Key? key,
    required this.onSelected,
    this.initialValue,
  }) : super(key: key);

  @override
  State<DifficultySelector> createState() => _DifficultySelectorState();
}

class _DifficultySelectorState extends State<DifficultySelector> {
  int? _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            _handleBar(),
            _title(context),
            const Divider(),

            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: DifficultySelector.difficultyLevels.length,
                itemBuilder: (context, index) {
                  final level =
                      DifficultySelector.difficultyLevels[index];
                  final isSelected = _selectedValue == level['value'];

                  return Card(
                    elevation: isSelected ? 4 : 1,
                    color: isSelected
                        ? (level['color'] as Color).withOpacity(0.1)
                        : null,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: level['color'],
                        child: Icon(level['icon'], color: Colors.white),
                      ),
                      title: Text(level['term'],
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(level['description']),
                      trailing: isSelected
                          ? Icon(Icons.check_circle,
                              color: level['color'])
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedValue = level['value'];
                        });
                      },
                    ),
                  );
                },
              ),
            ),

            _confirmButton(),
          ],
        );
      },
    );
  }

  Widget _confirmButton() {
    if (_selectedValue == null) return const SizedBox.shrink();

    final selected = DifficultySelector.difficultyLevels.firstWhere(
      (e) => e['value'] == _selectedValue,
    );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            widget.onSelected(selected['value'], selected['term']);
            Navigator.pop(context);
          },
          child: const Text('Confirm'),
        ),
      ),
    );
  }

  Widget _handleBar() => Container(
        height: 4,
        width: 40,
        margin: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(2),
        ),
      );

  Widget _title(BuildContext context) => Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          'Select Difficulty Level',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      );
}
