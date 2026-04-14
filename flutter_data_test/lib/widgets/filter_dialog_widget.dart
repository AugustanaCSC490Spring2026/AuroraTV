// Filter dialog widget for search customization
import 'package:flutter/material.dart';
import '../constants/colors.dart';

class FilterDialogWidget extends StatefulWidget {
  final bool kidsMode;
  final String selectedDuration;
  final String selectedVideoType;
  final TextEditingController avoidWordsCtrl;
  final TextEditingController advancedDescriptionCtrl;
  final Function(bool, String, String) onApply;
  final VoidCallback onReset;

  const FilterDialogWidget({
    super.key,
    required this.kidsMode,
    required this.selectedDuration,
    required this.selectedVideoType,
    required this.avoidWordsCtrl,
    required this.advancedDescriptionCtrl,
    required this.onApply,
    required this.onReset,
  });

  @override
  State<FilterDialogWidget> createState() => _FilterDialogWidgetState();
}

class _FilterDialogWidgetState extends State<FilterDialogWidget> {
  late bool _kidsMode;
  late String _selectedDuration;
  late String _selectedVideoType;

  @override
  void initState() {
    super.initState();
    _kidsMode = widget.kidsMode;
    _selectedDuration = widget.selectedDuration.toLowerCase();
    _selectedVideoType = widget.selectedVideoType;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: auroraPanel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: auroraDeep, width: 1.2),
      ),
      title: const Text(
        'Search Filters',
        style: TextStyle(color: auroraMint, fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: auroraGlow,
                title: const Text(
                  'Kids Mode',
                  style: TextStyle(color: auroraMint),
                ),
                value: _kidsMode,
                onChanged: (value) {
                  setState(() => _kidsMode = value);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedDuration,
                dropdownColor: auroraPanel,
                style: const TextStyle(color: auroraMint),
                decoration: const InputDecoration(labelText: 'Video Duration'),
                items: ['any', 'short', 'medium', 'long']
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedDuration = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedVideoType,
                dropdownColor: auroraPanel,
                style: const TextStyle(color: auroraMint),
                decoration: const InputDecoration(labelText: 'Video Type'),
                items: ['Any', 'Live', 'Shorts', 'Videos']
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedVideoType = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: widget.avoidWordsCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Words to Avoid',
                  hintText: 'e.g. remix, clips, shorts',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: widget.advancedDescriptionCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Advanced Description',
                  hintText: 'Optional extra detail',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              _kidsMode = false;
              _selectedDuration = 'any';
              _selectedVideoType = 'Any';
              widget.avoidWordsCtrl.clear();
              widget.advancedDescriptionCtrl.clear();
            });
            widget.onReset();
            Navigator.pop(context);
          },
          child: const Text('Reset'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onApply(_kidsMode, _selectedDuration, _selectedVideoType);
            Navigator.pop(context);
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
