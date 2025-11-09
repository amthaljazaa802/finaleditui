import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'backend_config.dart';

class SearchSheet extends StatefulWidget {
  final Future<List<Map<String, dynamic>>> Function(String query)? onSearch;

  /// Optional callback when the user selects a result. The widget will
  /// also pop the sheet with the selected item as the result.
  final void Function(Map<String, dynamic> item)? onSelected;

  const SearchSheet({super.key, this.onSearch, this.onSelected});

  @override
  State<SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<SearchSheet> {
  final TextEditingController _controller = TextEditingController();
  String selectedFilter = 'الكل';
  List<Map<String, dynamic>> results = [];
  bool loading = false;
  WebSocket? _webSocket;
  Timer? _debounce;

  final filters = ['الكل', 'محطات', 'حافلات', 'بالقرب مني', 'قيد الخدمة'];

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
  }

  void _connectWebSocket() async {
    try {
      // Use configured backend URL. Update `lib/backend_config.dart` when
      // switching to a public ngrok (wss://...) URL.
      _webSocket = await WebSocket.connect(kWebSocketUrl);
      _webSocket!.listen(
        (data) {
          setState(() {
            results = List<Map<String, dynamic>>.from(json.decode(data));
          });
        },
        onError: (error) {
          debugPrint('WebSocket error: $error');
          _reconnectWebSocket();
        },
        onDone: () {
          debugPrint('WebSocket connection closed');
          _reconnectWebSocket();
        },
      );
    } catch (e) {
      debugPrint('Failed to connect to WebSocket: $e');
      Future.delayed(const Duration(seconds: 5), _connectWebSocket);
    }
  }

  void _reconnectWebSocket() {
    debugPrint('Attempting to reconnect to WebSocket...');
    Future.delayed(const Duration(seconds: 5), _connectWebSocket);
  }

  void _search() {
    _performSearch(_controller.text);
  }

  void _onQueryChanged(String q) {
    // debounce typing
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _performSearch(q);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() => results = []);
      return;
    }

    if (_webSocket != null && _webSocket!.readyState == WebSocket.open) {
      try {
        _webSocket!.add(json.encode({'query': query}));
      } catch (e) {
        debugPrint('Failed to send via WebSocket: $e');
        // fallback to onSearch if provided
        if (widget.onSearch != null) {
          setState(() => loading = true);
          try {
            final res = await widget.onSearch!(query);
            setState(() {
              results = res;
              loading = false;
            });
          } catch (err) {
            debugPrint('onSearch failed: $err');
            setState(() => loading = false);
          }
        }
      }
    } else if (widget.onSearch != null) {
      setState(() => loading = true);
      try {
        final res = await widget.onSearch!(query);
        setState(() {
          results = res;
          loading = false;
        });
      } catch (err) {
        debugPrint('onSearch failed: $err');
        setState(() => loading = false);
      }
    }
  }

  @override
  void dispose() {
    _webSocket?.close();
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black26)],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          children: [
            // شريط البحث
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onChanged: _onQueryChanged,
                    onSubmitted: (_) => _search(),
                    decoration: InputDecoration(
                      hintText: 'ابحث عن محطة أو حافلة...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Tabs (الفلاتر)
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final f = filters[index];
                  final selected = selectedFilter == f;
                  return ChoiceChip(
                    label: Text(f),
                    selected: selected,
                    onSelected: (_) => setState(() => selectedFilter = f),
                    selectedColor: Colors.blue.shade50,
                    backgroundColor: Colors.grey.shade100,
                    labelStyle: TextStyle(
                      color: selected ? Colors.blue : Colors.black87,
                      fontWeight: selected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : results.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'لا توجد نتائج',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'جرّب كلمات بحث مختلفة أو تحقق من اتصال الشبكة.',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: results.length,
                      itemBuilder: (context, i) => _buildResultCard(results[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(Map<String, dynamic> item) {
    final isStation = item['type'] == 'station';
    final color = isStation ? Colors.green.shade600 : Colors.blue.shade600;
    final icon = isStation
        ? Icons.location_on_rounded
        : Icons.directions_bus_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // let the caller know what was selected, and pop the sheet
            try {
              if (widget.onSelected != null) widget.onSelected!(item);
            } catch (_) {}
            Navigator.pop(context, item);
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(blurRadius: 6, color: Colors.black12),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // الاسم والسطر الثاني
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(icon, color: color),
                        const SizedBox(width: 8),
                        Text(
                          (item['title'] ?? '').toString(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (item['badge'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              _parseBadgeColor(item['badgeColor']) ??
                              Colors.green,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          item['badge'].toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 4),
                Text(
                  (item['subtitle'] ?? '').toString(),
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Try to parse the badge color which might be stored as an int or a
  /// hex string (e.g. '#ff00aa') or already a [Color]. Returns null on fail.
  Color? _parseBadgeColor(dynamic v) {
    if (v == null) return null;
    if (v is Color) return v;
    if (v is int) return Color(v);
    if (v is String) {
      var s = v.trim();
      if (s.startsWith('#')) s = s.substring(1);
      try {
        if (s.length == 6) s = 'FF$s'; // add alpha
        final hex = int.parse(s, radix: 16);
        return Color(hex);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
