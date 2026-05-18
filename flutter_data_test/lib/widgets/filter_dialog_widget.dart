import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/colors.dart';
import '../services/category_service.dart';
import 'retro_ui.dart';

class FilterDialogWidget extends StatefulWidget {
  final bool kidsMode;
  final String selectedDuration;
  final String selectedVideoType;
  final bool filterClickbait;
  final String keyword;
  final TextEditingController avoidWordsCtrl;
  final TextEditingController advancedDescriptionCtrl;
  final Function(bool, String, String, bool) onApply;
  final VoidCallback onReset;

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
        filterClickbait: _filterClickbait,
        avoidWords: widget.avoidWordsCtrl.text.trim(),
        advancedDescription: widget.advancedDescriptionCtrl.text.trim(),
      );
      setState(() {
        _savedCode = code;
        _isSaving = false;
      });
    } catch (e) {
      setState(() => _isSaving = false);
      if (!mounted) return;
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
      initialValue: value,
      dropdownColor: auroraCream,
      style: const TextStyle(color: auroraInk, fontWeight: FontWeight.w800),
      decoration: InputDecoration(labelText: label),
      icon: const Icon(Icons.keyboard_arrow_down_rounded),
      items: items
          .map((v) => DropdownMenuItem(value: v, child: Text(v.toString())))
          .toList(),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: RetroPanel(
          padding: const EdgeInsets.all(18),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Tune the tape', style: text.headlineMedium),
                    ),
                    RetroIconButton(
                      tooltip: 'Close',
                      icon: Icons.close_rounded,
                      size: 44,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const RetroWindowBar(title: 'FILTERS.EXE'),
                const SizedBox(height: 14),
                _SwitchBox(
                  title: 'Kids mode',
                  icon: Icons.child_care_rounded,
                  value: _kidsMode,
                  onChanged: (value) => setState(() => _kidsMode = value),
                ),
                const SizedBox(height: 12),
                _SwitchBox(
                  title: 'Filter clickbait',
                  icon: Icons.block_rounded,
                  value: _filterClickbait,
                  onChanged: (value) {
                    setState(() => _filterClickbait = value);
                  },
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 440;
                    final duration = _buildDropdown(
                      'Video duration',
                      _selectedDuration,
                      ['any', 'short', 'medium', 'long'],
                      (v) {
                        if (v != null) {
                          setState(() => _selectedDuration = v);
                        }
                      },
                    );
                    final type = _buildDropdown(
                      'Video type',
                      _selectedVideoType,
                      ['Any', 'Live', 'Shorts', 'Videos'],
                      (v) {
                        if (v != null) {
                          setState(() => _selectedVideoType = v);
                        }
                      },
                    );

                    if (isNarrow) {
                      return Column(
                        children: [duration, const SizedBox(height: 12), type],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: duration),
                        const SizedBox(width: 12),
                        Expanded(child: type),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: widget.avoidWordsCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Words to avoid',
                    hintText: 'Spoilers, scary, loud',
                    prefixIcon: Icon(Icons.block_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: widget.advancedDescriptionCtrl,
                  minLines: 3,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Advanced description',
                    hintText: 'Describe the exact tape you want',
                    alignLabelWithHint: true,
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 56),
                      child: Icon(Icons.tune_rounded),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Divider(),
                const SizedBox(height: 12),
                Text('Save & Share', style: text.titleLarge),
                const SizedBox(height: 10),
                TextField(
                  controller: _categoryNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Category name',
                    hintText: 'Chill lo-fi evenings',
                    prefixIcon: Icon(Icons.bookmark_add_outlined),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                if (_savedCode != null) _buildSavedCode(),
                const SizedBox(height: 18),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 124,
                      child: RetroButton(
                        label: 'Reset',
                        icon: Icons.refresh_rounded,
                        isPrimary: false,
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
                      ),
                    ),
                    SizedBox(
                      width: 174,
                      child: _isSaving
                          ? const Center(
                              child: CircularProgressIndicator(strokeWidth: 3),
                            )
                          : RetroButton(
                              label: 'Save',
                              icon: Icons.bookmark_add_outlined,
                              isPrimary: false,
                              onPressed: _categoryNameCtrl.text.trim().isEmpty
                                  ? null
                                  : _saveCategory,
                            ),
                    ),
                    SizedBox(
                      width: 136,
                      child: RetroButton(
                        label: 'Apply',
                        icon: Icons.check_rounded,
                        onPressed: () {
                          widget.onApply(
                            _kidsMode,
                            _selectedDuration,
                            _selectedVideoType,
                            _filterClickbait,
                          );
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSavedCode() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: auroraGreen,
        border: Border.all(color: auroraInk, width: 3),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: auroraInk, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _savedCode!,
                style: const TextStyle(
                  color: auroraInk,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy_rounded, color: auroraInk),
              tooltip: 'Copy code',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _savedCode!));
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Code copied!')));
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SwitchBox extends StatelessWidget {
  const _SwitchBox({
    required this.title,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: auroraWhite,
        border: Border.all(color: auroraInk, width: 3),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        secondary: Icon(icon, color: auroraInk),
        title: Text(
          title,
          style: const TextStyle(
            color: auroraInk,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
