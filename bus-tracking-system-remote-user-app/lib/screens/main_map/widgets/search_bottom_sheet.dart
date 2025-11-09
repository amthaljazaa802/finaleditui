import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../models/search_result.dart';
import '../../../services/search_service.dart';
import 'package:latlong2/latlong.dart';

/// شاشة البحث المنبثقة (Bottom Sheet)
class SearchBottomSheet extends StatefulWidget {
  final Function(LatLng)? onLocationSelected;
  final bool useMockData;
  final List<dynamic>? busStops;
  final List<dynamic>? buses;
  final List<dynamic>? busLines;

  const SearchBottomSheet({
    super.key,
    this.onLocationSelected,
    this.useMockData = false,
    this.busStops,
    this.buses,
    this.busLines,
  });

  @override
  State<SearchBottomSheet> createState() => _SearchBottomSheetState();
}

class _SearchBottomSheetState extends State<SearchBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  final SearchService _searchService = SearchService();

  SearchCategory _selectedCategory = SearchCategory.all;
  List<SearchResult> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      List<SearchResult> results;

      if (widget.useMockData) {
        // بحث محلي
        results = _searchService.searchLocal(
          query: query,
          busStops: widget.busStops ?? [],
          buses: widget.buses ?? [],
          busLines: widget.busLines ?? [],
          category: _selectedCategory,
        );
      } else {
        // بحث من السيرفر
        results = await _searchService.search(
          query: query,
          category: _selectedCategory,
        );
      }

      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[Search] Error: $e');
      setState(() {
        _results = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: AppBorders.circular,
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Back button
                IconButton(
                  icon: Icon(Icons.arrow_forward, color: AppColors.textPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),

                // Search input
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: AppBorders.large,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: AppColors.primary, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'ابحث عن محطة أو حافلة...',
                              hintStyle: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textHint,
                              ),
                              border: InputBorder.none,
                            ),
                            style: AppTextStyles.bodyMedium,
                            textInputAction: TextInputAction.search,
                            onSubmitted: (_) => _performSearch(),
                            onChanged: (value) {
                              if (value.isEmpty) {
                                setState(() {
                                  _results = [];
                                  _hasSearched = false;
                                });
                              }
                            },
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _results = [];
                                _hasSearched = false;
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Microphone button (optional)
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.mic_none, color: AppColors.textSecondary),
                    onPressed: () {
                      // يمكن إضافة البحث الصوتي هنا
                    },
                  ),
                ),
              ],
            ),
          ),

          // Category filters
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: SearchCategory.values.map((category) {
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: ChoiceChip(
                    label: Text(category.label),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                      if (_searchController.text.isNotEmpty) {
                        _performSearch();
                      }
                    },
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.filterInactive,
                    labelStyle: AppTextStyles.bodySmall.copyWith(
                      color: isSelected
                          ? AppColors.textOnPrimary
                          : AppColors.textPrimary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: StadiumBorder(
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primaryDark
                            : AppColors.divider,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const Divider(height: 1),

          // Results
          Expanded(child: _buildResultsBody()),
        ],
      ),
    );
  }

  Widget _buildResultsBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(
              'ابحث عن محطة أو حافلة',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(
              'لا توجد نتائج',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'جرب البحث بكلمات مختلفة',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final result = _results[index];
        return _buildResultItem(result);
      },
    );
  }

  Widget _buildResultItem(SearchResult result) {
    IconData icon;
    Color iconColor;

    switch (result.type) {
      case SearchResultType.busStop:
        icon = Icons.location_on;
        iconColor = AppColors.accent;
        break;
      case SearchResultType.bus:
        icon = Icons.directions_bus;
        iconColor = AppColors.primary;
        break;
      case SearchResultType.busLine:
        icon = Icons.route;
        iconColor = AppColors.info;
        break;
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: AppBorders.medium,
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(
        result.title,
        style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        result.subtitle,
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
      ),
      trailing: result.type == SearchResultType.busStop
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: AppBorders.small,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'قريب',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '3 د',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            )
          : result.type == SearchResultType.bus
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: AppBorders.small,
              ),
              child: Text(
                'ETA 5 د',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.info,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
      onTap: () {
        if (result.location != null && widget.onLocationSelected != null) {
          widget.onLocationSelected!(result.location!);
          Navigator.pop(context);
        }
      },
    );
  }
}
