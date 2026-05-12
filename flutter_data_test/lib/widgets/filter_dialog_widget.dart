import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/colors.dart';
import '../services/category_service.dart';

class FilterDialogWidget extends StatefulWidget {
  final bool kidsMode;
  final String selectedDuration;
  final String selectedVideoType;
  final String keyword;
  final TextEditingController avoidWordsCtrl;
  final TextEditingController advancedDescriptionCtrl;
  final Function(bool, String, String, bool) onApply;
  final VoidCallback onReset;

  final dynamic filterClickbait;

  const FilterDialogWidget({
    super.key,
    required this.kidsMode,
    required this.selectedDuration,
    required this.selectedVideoType,
    required this.filterClickbait,
    required this.keyword,
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
  late bool _filterClickbait;

  final _categoryNameCtrl = TextEditingController();
  bool _isSaving = false;
  String? _savedCode;

  @override
  void initState() {
    super.initState();
    _kidsMode = widget.kidsMode;
    _selectedDuration = widget.selectedDuration.toLowerCase();
    _selectedVideoType = widget.selectedVideoType;
    _filterClickbait = widget.filterClickbait;
  }

  @override
  void dispose() {
    _categoryNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveCategory() async {
    if (_categoryNameCtrl.text.trim().isEmpty) return;
    setState(() => _isSaving = true);

    try {
      final code = await CategoryService().saveCategory(
        name: _categoryNameCtrl.text.trim(),
        keyword: widget.keyword,
        kidsMode: _kidsMode,
        duration: _selectedDuration,
        videoType: _selectedVideoType,
        avoidWords: widget.avoidWordsCtrl.text.trim(),
        advancedDescription: widget.advancedDescriptionCtrl.text.trim(),
      );
      setState(() {
        _savedCode = code;
        _isSaving = false;
      });
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    }
  }

  Widget _buildDropdown<T>(
    String label,
    T value,
    List<T> items,
    ValueChanged<T?> onChanged,
  ) {
    return DropdownButtonFormField<T>(
      value: value,
      dropdownColor: auroraPanel,
      style: const TextStyle(color: auroraMint),
      decoration: InputDecoration(labelText: label),
      items: items
          .map((v) => DropdownMenuItem(value: v, child: Text(v.toString())))
          .toList(),
      onChanged: onChanged,
    );
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
                onChanged: (value) => setState(() => _kidsMode = value),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: auroraGlow,
                title: const Text(
                  'Kids Mode',
                  style: TextStyle(color: auroraMint),
                ),
                value: _kidsMode,
                onChanged: (value) => setState(() => _kidsMode = value),
              ),
              const SizedBox(height: 12),
              _buildDropdown(
                'Video Duration',
                _selectedDuration,
                ['any', 'short', 'medium', 'long'],
                (v) {
                  if (v != null) setState(() => _selectedDuration = v);
                },
              ),
              const SizedBox(height: 12),
              _buildDropdown(
                'Video Type',
                _selectedVideoType,
                ['Any', 'Live', 'Shorts', 'Videos'],
                (v) {
                  if (v != null) setState(() => _selectedVideoType = v);
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
              const SizedBox(height: 20),
              const Divider(color: auroraDeep),
              const SizedBox(height: 8),
              const Text(
                'Save & Share',
                style: TextStyle(
                  color: auroraGlow,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _categoryNameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  hintText: 'e.g. Chill Lo-Fi Evenings',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              if (_savedCode != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: auroraDeep,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.greenAccent,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _savedCode!,
                        style: const TextStyle(
                          color: auroraGlow,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(
                          Icons.copy,
                          color: auroraGlow,
                          size: 18,
                        ),
                        tooltip: 'Copy code',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _savedCode!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Code copied!')),
                          );
                        },
                      ),
                    ],
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
              _filterClickbait = true;
              widget.avoidWordsCtrl.clear();
              widget.advancedDescriptionCtrl.clear();
            });
            widget.onReset();
            Navigator.pop(context);
          },
          child: const Text('Reset'),
        ),
        if (_isSaving)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else
          TextButton.icon(
            icon: const Icon(Icons.bookmark_add_outlined),
            label: const Text('Save & Share'),
            onPressed: _categoryNameCtrl.text.trim().isEmpty
                ? null
                : _saveCategory,
          ),
        ElevatedButton(
          onPressed: () {
            widget.onApply(
              _kidsMode,
              _selectedDuration,
              _selectedVideoType,
              _filterClickbait,
            );
            Navigator.pop(context);
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
