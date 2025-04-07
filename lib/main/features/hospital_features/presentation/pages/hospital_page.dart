import 'package:flutter/material.dart';
import 'package:medcave/main/features/hospital_features/model/hospitaldata.dart';
import 'package:medcave/main/features/hospital_features/presentation/widgets/doctors_list_hospital.dart';
import 'package:medcave/main/features/hospital_features/presentation/widgets/lab_list_hospital.dart';
import 'package:medcave/main/features/hospital_features/presentation/widgets/hospital_search.dart';
import 'package:medcave/main/features/hospital_features/presentation/widgets/hospital_tab_bar.dart';
import 'package:medcave/main/features/hospital_features/presentation/widgets/medicine_list_hospital.dart';
import 'package:medcave/config/colors/appcolor.dart';
import 'package:medcave/config/fonts/font.dart';
import 'package:medcave/main/features/hospital_features/presentation/widgets/paliativecare_inidicator.dart';
import 'package:medcave/main/features/hospital_features/presentation/widgets/vaccine_list_hospital_.dart';

class HospitalPage extends StatefulWidget {
  final String? initialHospitalId;

  const HospitalPage({
    Key? key,
    this.initialHospitalId,
  }) : super(key: key);

  @override
  State<HospitalPage> createState() => _HospitalPageState();
}

class _HospitalPageState extends State<HospitalPage> {
  int _selectedTabIndex = 0;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _headerKey = GlobalKey();
  final GlobalKey _tabBarKey = GlobalKey();
  bool _isTabBarSticky = false;
  bool _isSearchExpanded = false;
  double _headerHeight = 0;
  double _tabBarHeight = 0;
  String _searchQuery = '';

  // Hospital data state
  String _hospitalId = HospitalData.DEFAULT_HOSPITAL_ID;
  String _hospitalName = "Loading...";
  String _location = "Please wait...";
  Map<String, dynamic> _stats = HospitalData.defaultStats;

  // Palliative care data
  bool _hasPalliativeCare = false;
  String _palliativeCareDesc = "";
  String _palliativeCareContact = "";

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateStickyState);

    _hospitalId = widget.initialHospitalId ?? HospitalData.DEFAULT_HOSPITAL_ID;

    // Load hospital data
    _loadSelectedHospital();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureHeights();
    });
  }

  Future<void> _loadSelectedHospital() async {
    if (widget.initialHospitalId == null) {
      _hospitalId = await HospitalData.getSelectedHospitalId();
    }

    await _loadHospitalData(_hospitalId); // Await here to ensure data is loaded
  }

  Future<void> _loadHospitalData(String hospitalId) async {
    final hospitalData = await HospitalData.getHospitalById(hospitalId); // Await the Future

    if (hospitalData != null) {
      setState(() {
        _hospitalId = hospitalData["id"];
        _hospitalName = hospitalData["name"];
        _location = hospitalData["location"];
        _stats = hospitalData["stats"];

        if (hospitalData.containsKey("palliativeCare")) {
          _hasPalliativeCare = hospitalData["palliativeCare"]["available"] ?? false;
          _palliativeCareDesc = hospitalData["palliativeCare"]["description"] ?? "";
          _palliativeCareContact = hospitalData["palliativeCare"]["contactNumber"] ?? "";
        } else {
          _hasPalliativeCare = false;
          _palliativeCareDesc = "";
          _palliativeCareContact = "";
        }
      });
    } else {
      setState(() {
        _hospitalId = HospitalData.DEFAULT_HOSPITAL_ID;
        _hospitalName = "Srinivas Hospital";
        _location = "Surathkal, Mangaluru";
        _stats = HospitalData.defaultStats;
        _hasPalliativeCare = false;
        _palliativeCareDesc = "";
        _palliativeCareContact = "";
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateStickyState);
    _scrollController.dispose();
    super.dispose();
  }

  void _measureHeights() {
    final RenderBox? headerBox = _headerKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? tabBarBox = _tabBarKey.currentContext?.findRenderObject() as RenderBox?;

    if (headerBox != null && tabBarBox != null) {
      setState(() {
        _headerHeight = headerBox.size.height;
        _tabBarHeight = tabBarBox.size.height;
      });
    }
  }

  void _updateStickyState() {
    final isTabBarSticky = _scrollController.offset >= _headerHeight;

    if (isTabBarSticky != _isTabBarSticky) {
      setState(() {
        _isTabBarSticky = isTabBarSticky;
      });
    }
  }

  void _handleTabSelection(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _selectedTabIndex = index;
      });
    });
  }

  void _handleSearch(String query) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _searchQuery = query;
      });
    });
  }

  void _onHospitalSelected(String hospitalId, Map<String, dynamic>? hospitalData) {
    if (hospitalData != null) {
      HospitalData.saveSelectedHospitalId(hospitalId);

      setState(() {
        _hospitalId = hospitalId;
        _hospitalName = hospitalData["name"];
        _location = hospitalData["location"];
        _stats = hospitalData["stats"] ?? HospitalData.defaultStats;

        if (hospitalData.containsKey("palliativeCare")) {
          _hasPalliativeCare = hospitalData["palliativeCare"]["available"] ?? false;
          _palliativeCareDesc = hospitalData["palliativeCare"]["description"] ?? "";
          _palliativeCareContact = hospitalData["palliativeCare"]["contactNumber"] ?? "";
        } else {
          _hasPalliativeCare = false;
          _palliativeCareDesc = "";
          _palliativeCareContact = "";
        }

        _selectedTabIndex = 0;
        _searchQuery = '';
        _scrollController.animateTo(
          0,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearchExpanded = !_isSearchExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: NestedScrollView(
              controller: _scrollController,
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
                    child: Container(
                      key: _headerKey,
                      child: _buildHospitalHeader(),
                    ),
                  ),
                  SliverPersistentHeader(
                    delegate: _StickyTabBarDelegate(
                      child: Container(
                        key: _tabBarKey,
                        color: AppColor.secondaryBackgroundWhite,
                        child: HospitalTabBar(
                          selectedIndex: _selectedTabIndex,
                          onTabSelected: _handleTabSelection,
                          onSearch: _handleSearch,
                        ),
                      ),
                      minHeight: _tabBarHeight > 0 ? _tabBarHeight : 120,
                      maxHeight: _tabBarHeight > 0 ? _tabBarHeight : 120,
                    ),
                    pinned: true,
                  ),
                ];
              },
              body: IndexedStack(
                index: _selectedTabIndex,
                children: [
                  DoctorList(
                    hospitalId: _hospitalId,
                    searchQuery: _searchQuery,
                  ),
                  LabTestList(
                    hospitalId: _hospitalId,
                    searchQuery: _searchQuery,
                  ),
                  MedicineList(
                    hospitalId: _hospitalId,
                    searchQuery: _searchQuery,
                  ),
                  VaccineList(
                    hospitalId: _hospitalId,
                    searchQuery: _searchQuery,
                  ),
                ],
              ),
            ),
          ),
          if (_isSearchExpanded)
            Positioned.fill(
              child: NotificationListener<SearchStateNotification>(
                onNotification: (notification) {
                  setState(() {
                    _isSearchExpanded = notification.isExpanded;
                  });
                  return true;
                },
                child: ExpandingHospitalSearch(
                  onHospitalSelected: _onHospitalSelected,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHospitalHeader() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 300,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/hospitalsimages/1.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                bottom: 20,
                left: 20,
                child: PalliativeCareIndicator(
                  isAvailable: _hasPalliativeCare,
                  description: _palliativeCareDesc,
                  contactNumber: _palliativeCareContact, hospitalId: '',
                ),
              ),
              Positioned(
                top: 20,
                right: 20,
                child: !_isSearchExpanded
                    ? GestureDetector(
                        onTap: _toggleSearch,
                        child: Container(
                          width: 48,
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
                          child: Icon(
                            Icons.search,
                            color: const Color(0xff666666),
                          ),
                        ),
                      )
                    : SizedBox.shrink(),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                _hospitalName,
                style: FontStyles.heading,
                textAlign: TextAlign.center,
              ),
              Text(
                _location,
                style: FontStyles.heading,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _stats.entries.map((entry) {
                  return Column(
                    children: [
                      Text(
                        entry.value['count'].toString(),
                        style: FontStyles.bodyStrong,
                      ),
                      Text(
                        entry.key,
                        style: FontStyles.bodySmall.copyWith(color: AppColor.secondaryGrey),
                      ),
                    ],
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double minHeight;
  final double maxHeight;

  _StickyTabBarDelegate({
    required this.child,
    required this.minHeight,
    required this.maxHeight,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColor.secondaryBackgroundWhite,
      child: child,
    );
  }

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return oldDelegate.minHeight != minHeight ||
        oldDelegate.maxHeight != maxHeight ||
        oldDelegate.child != child;
  }
}