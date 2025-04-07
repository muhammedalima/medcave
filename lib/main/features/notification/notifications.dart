import 'dart:async';
import 'package:flutter/material.dart';
import 'package:medcave/main/commonWidget/customnavbar.dart';
import 'package:medcave/main/commonWidget/quotewidget.dart';
import 'package:medcave/common/services/medicine_notification_service.dart';
import 'package:medcave/config/colors/appcolor.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medcave/main/features/ambulance_tracking/presentation/pages/driver/details_ambulancedriver.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  StreamSubscription? _notificationStreamSubscription;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _setupNotificationListener();
  }

  @override
  void dispose() {
    _notificationStreamSubscription?.cancel();
    super.dispose();
  }

  void _setupNotificationListener() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (mounted) {
        _loadNotifications();
      }
    });

    try {
      _notificationStreamSubscription =
          MedicineNotificationService.notificationStream.listen((_) {
        if (mounted) {
          _loadNotifications();
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('Notification stream not available: $e');
      }
    }
  }

  Future<void> _loadNotifications() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      List<Map<String, dynamic>> notifications =
          await MedicineNotificationService.getNotificationHistory();

      if (kDebugMode) {
        print(
            'Loaded ${notifications.length} notifications from MedicineNotificationService');
      }

      // Filter to show only past notifications
      final now = DateTime.now();
      notifications = notifications.where((notification) {
        final bool isPending = notification['isPending'] == true;
        final DateTime time = notification['time'] as DateTime;
        return !isPending &&
            time.isBefore(now); // Only past, non-pending notifications
      }).toList();

      // Sort by time (newest first)
      notifications.sort(
          (a, b) => (b['time'] as DateTime).compareTo(a['time'] as DateTime));

      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading notifications: $e');
      }
      if (mounted) {
        setState(() {
          _notifications = [];
          _isLoading = false;
        });
      }
    }
  }

  bool _isMedicineNotification(Map<String, dynamic> notification) {
    if (notification['type'] == 'medication' ||
        notification['type'] == 'medicine') {
      return true;
    }

    final String title = notification['title']?.toString().toLowerCase() ?? '';
    final String body = notification['body']?.toString().toLowerCase() ?? '';
    final data = notification['data'] ?? {};

    return title.contains('medicine') ||
        title.contains('dose') ||
        body.contains('medicine') ||
        body.contains('dose') ||
        (data is Map &&
            (data['medicineName'] != null || data['medicine'] != null));
  }

  Widget _getNotificationIcon(String type) {
    final String normalizedType = type.toString().toLowerCase().trim();

    switch (normalizedType) {
      case 'medication':
      case 'medicine':
        return Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.blue[700],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.medication_outlined,
              color: Colors.white, size: 30),
        );
      case 'appointment':
        return Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.green[700],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.medical_services_outlined,
              color: Colors.white, size: 30),
        );
      case 'ambulance_request':
        return Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.red[700],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.local_hospital_outlined,
              color: Colors.white, size: 30),
        );
      case 'emergency':
        return Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.orange[700],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.warning_amber_outlined,
              color: Colors.white, size: 30),
        );
      default:
        return Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.notifications_outlined,
              color: Colors.white, size: 30),
        );
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      return 'Today at ${DateFormat('hh:mm a').format(time)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${DateFormat('hh:mm a').format(time)}';
    } else if (difference.inDays < 7) {
      return '${DateFormat('EEEE').format(time)} at ${DateFormat('hh:mm a').format(time)}';
    } else {
      return '${DateFormat('dd MMM yyyy').format(time)} at ${DateFormat('hh:mm a').format(time)}';
    }
  }

  void _deleteNotification(String id) async {
    if (!mounted) return;

    try {
      await MedicineNotificationService.deleteNotification(id);

      setState(() {
        _notifications.removeWhere((notification) => notification['id'] == id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification deleted'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting notification: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete notification'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _clearAllNotifications() async {
    if (!mounted) return;

    try {
      await MedicineNotificationService.clearNotificationHistory();

      setState(() {
        _notifications.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications cleared'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing notifications: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to clear notifications'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _refreshNotifications() async {
    await _loadNotifications();
  }

  void _handleNotificationTap(Map<String, dynamic> notification) async {
    if (!mounted) return;

    try {
      final data = notification['data'];
      final type = notification['type'].toString().toLowerCase();

      if (type == 'ambulance_request' &&
          data != null &&
          data['requestId'] != null) {
        await _fetchRequestDataAndNavigate(data['requestId']);
      } else if (type == 'medication' ||
          type == 'medicine' ||
          _isMedicineNotification(notification)) {
        Navigator.of(context).pushNamed('/medicines');
      } else if (type == 'appointment') {
        Navigator.of(context).pushNamed('/appointments');
      } else if (type == 'emergency') {
        Navigator.of(context).pushNamed('/emergency');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error handling notification tap: $e');
      }
    }
  }

  Future<void> _fetchRequestDataAndNavigate(String requestId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('ambulanceRequests')
          .doc(requestId)
          .get();

      if (!doc.exists || !mounted) return;

      final Map<String, dynamic> completeData = {
        ...doc.data() as Map<String, dynamic>,
        'id': doc.id,
      };

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AmbulanceDetailDriver(
            completeData: completeData,
            requestId: requestId,
            isPastRide: false,
          ),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching request data: $e');
      }
    }
  }

  Widget _renderNotificationItem(Map<String, dynamic> notification) {
    return InkWell(
      onTap: () => _handleNotificationTap(notification),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _getNotificationIcon(notification['type'] ?? 'general'),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification['title'] ?? 'Notification',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    if (notification['body'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        notification['body'],
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      _formatTime(notification['time'] ?? DateTime.now()),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getTypeColor(notification['type'] ?? 'general'),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getTypeText(notification['type'] ?? 'general'),
                        style:
                            const TextStyle(fontSize: 10, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.grey),
                onPressed: () => _deleteNotification(notification['id']),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        onPressed: () => Navigator.pop(context),
        rightIcon:
            _notifications.isNotEmpty ? Icons.delete_sweep_outlined : null,
        onRightPressed: _clearAllNotifications,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshNotifications,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Past Notifications',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 4),
                    ],
                  ),
                ),
              ),
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (!_isLoading && _notifications.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off_outlined,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No past notifications',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Pull down to refresh',
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                ),
              if (!_isLoading && _notifications.isNotEmpty)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == _notifications.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Center(
                            child: WaveyMessage(
                              message: 'We Never\nMiss Care!',
                              textColor: AppColor.backgroundWhite,
                              waveyLineColor: Colors.black,
                            ),
                          ),
                        );
                      }
                      final notification = _notifications[index];
                      return _renderNotificationItem(notification);
                    },
                    childCount: _notifications.length + 1,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    final String normalizedType = type.toString().toLowerCase().trim();
    switch (normalizedType) {
      case 'medication':
      case 'medicine':
        return Colors.blue[700]!;
      case 'appointment':
        return Colors.green[700]!;
      case 'ambulance_request':
        return Colors.red[700]!;
      case 'emergency':
        return Colors.orange[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  String _getTypeText(String type) {
    final String normalizedType = type.toString().toLowerCase().trim();
    switch (normalizedType) {
      case 'medication':
      case 'medicine':
        return 'MEDICINE';
      case 'appointment':
        return 'APPOINTMENT';
      case 'ambulance_request':
        return 'AMBULANCE';
      case 'emergency':
        return 'EMERGENCY';
      default:
        return 'NOTIFICATION';
    }
  }
}
