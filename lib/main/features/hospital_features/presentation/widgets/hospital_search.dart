import 'package:flutter/material.dart';
import 'package:medcave/main/features/hospital_features/model/hospitaldata.dart';
import 'package:medcave/config/colors/appcolor.dart';

// Custom notification to communicate search expansion state
class SearchStateNotification extends Notification {
  final bool isExpanded;

  SearchStateNotification(this.isExpanded);
}

class ExpandingHospitalSearch extends StatefulWidget {
  final Function(String, Map<String, dynamic>?) onHospitalSelected;

  const ExpandingHospitalSearch({
    Key? key,
    required this.onHospitalSelected,
  }) : super(key: key);

  @override
  State<ExpandingHospitalSearch> createState() =>
      _ExpandingHospitalSearchState();
}

class _ExpandingHospitalSearchState extends State<ExpandingHospitalSearch>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isExpanded = false;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false; // Add loading state

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _expandSearch();
      }
    });

    _searchController.addListener(_onSearchChanged);

    // Auto-expand search on initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _expandSearch();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _onSearchChanged() async {
    setState(() {
      _isLoading = true; // Show loading while fetching
    });

    final results = await HospitalData.searchHospitals(
        _searchController.text); // Await the Future

    if (mounted) {
      // Ensure the widget is still mounted before calling setState
      setState(() {
        _searchResults = results;
        _isLoading = false; // Hide loading after results are fetched
      });
    }
  }

  void _expandSearch() {
    if (!_isExpanded) {
      setState(() {
        _isExpanded = true;
      });
      _animationController.forward();

      SearchStateNotification(true).dispatch(context);

      Future.delayed(Duration(milliseconds: 100), () {
        FocusScope.of(context).requestFocus(_focusNode);
      });
    }
  }

  void _collapseSearch() {
    if (_isExpanded) {
      setState(() {
        _isExpanded = false;
        _searchResults = [];
        _searchController.clear();
      });
      _animationController.reverse();
      FocusManager.instance.primaryFocus?.unfocus();

      SearchStateNotification(false).dispatch(context);
    }
  }

  void _selectHospital(Map<String, dynamic> hospital) {
    HospitalData.saveSelectedHospitalId(hospital["id"]);
    widget.onHospitalSelected(
      hospital["id"],
      hospital,
    );
    _collapseSearch();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: SizedBox(
        width: _isExpanded ? MediaQuery.of(context).size.width : 48.0,
        height: _isExpanded ? MediaQuery.of(context).size.height : 48.0,
        child: Stack(
          children: [
            if (_isExpanded)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _collapseSearch,
                  child: Container(
                    color: Colors.black54,
                  ),
                ),
              ),
            Positioned(
              top: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  final width = Tween<double>(
                    begin: 48.0,
                    end: MediaQuery.of(context).size.width - 40.0,
                  ).evaluate(_animation);

                  return Container(
                    width: width,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColor.navigationBackColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: child,
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _isExpanded
                        ? IconButton(
                            icon: Icon(
                              Icons.arrow_back,
                              color: const Color(0xff666666),
                            ),
                            onPressed: _collapseSearch,
                          )
                        : IconButton(
                            icon: Icon(
                              Icons.search,
                              color: const Color(0xff666666),
                            ),
                            onPressed: _expandSearch,
                          ),
                    if (_isExpanded)
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _focusNode,
                          decoration: InputDecoration(
                            hintText: 'Search Hospital',
                            border: InputBorder.none,
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 10),
                          ),
                          onTap: _expandSearch,
                          autofocus: true,
                        ),
                      ),
                    if (_isExpanded && _searchController.text.isNotEmpty)
                      IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: const Color(0xff666666),
                        ),
                        onPressed: () {
                          _searchController.clear();
                        },
                      ),
                  ],
                ),
              ),
            ),
            if (_isExpanded)
              Positioned(
                top: 55,
                right: 0,
                width: MediaQuery.of(context).size.width - 40.0,
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: 300,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _isLoading
                        ? Center(
                            child:
                                CircularProgressIndicator()) // Show loading indicator
                        : _searchResults.isEmpty
                            ? Padding(
                                padding: EdgeInsets.all(16),
                                child: Text("No results found"),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                itemCount: _searchResults.length,
                                itemBuilder: (context, index) {
                                  final hospital = _searchResults[index];
                                  return ListTile(
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 4),
                                    title: Text(hospital["name"]),
                                    subtitle: Text(hospital["location"]),
                                    onTap: () => _selectHospital(hospital),
                                  );
                                },
                              ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
