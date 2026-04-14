class SearchOptions {
  final String keyword;
  final bool kidsMode;
  final String selectedDuration;
  final String avoidWords;
  final String advancedDescription;

  const SearchOptions({
    required this.keyword,
    required this.kidsMode,
    required this.selectedDuration,
    required this.avoidWords,
    required this.advancedDescription,
  });
}