import 'package:flutter/material.dart';
import 'package:medcave/Users/Mobilescreens/commonWidget/quotewidget.dart';
import 'package:medcave/common/services/medicine_notification_service.dart';
import 'package:medcave/config/colors/appcolor.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medcave/Users/Mobilescreens/features/ambulance_tracking/presentation/pages/driver/details_ambulancedriver.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _setupNotificationListener();
  }

  // Listen for new notifications while screen is open
  void _setupNotificationListener() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Refresh the notification list when a new notification arrives
      _loadNotifications();
    });

    // Also listen to our stream from MedicineNotificationService if it exists
    try {
      MedicineNotificationService.notificationStream.listen((_) {
        // Refresh the notification list when a new notification is added to history
        _loadNotifications();
      });
    } catch (e) {
      // Stream might not be defined
      if (kDebugMode) {
        print('Notification stream not available: $e');
      }
    }
  }

  // Load all notifications from storage
  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Try to get notifications from the MedicineNotificationService
      List<Map<String, dynamic>> notifications = [];

      try {
        // Use MedicineNotificationService if available
        notifications =
            await MedicineNotificationService.getNotificationHistory();
      } catch (e) {
        // Fallback to direct SharedPreferences access
        if (kDebugMode) {
          print('Error getting notifications from service: $e');
          print('Falling back to direct SharedPreferences access');
        }

        final prefs = await SharedPreferences.getInstance();
        final notificationsJson =
            prefs.getString('notification_history') ?? '[]';

        final List<dynamic> parsed = jsonDecode(notificationsJson);
        notifications = parsed.map<Map<String, dynamic>>((item) {
          try {
            // Parse the ISO date string back to DateTime
            final DateTime time = item['time'] != null
                ? DateTime.parse(item['time'])
                : DateTime.now();

            return {
              ...item,
              'time': time,
            };
          } catch (e) {
            // If time parsing fails, use current time
            return {
              ...item,
              'time': DateTime.now(),
            };
          }
        }).toList();
      }

      // Process notifications to ensure proper type identification
      // and remove duplicates (based on title and timestamp)
      final processedNotifications =
          _removeDuplicateMedicineNotifications(notifications);

      // Sort by time (newest first)
      processedNotifications.sort(
          (a, b) => (b['time'] as DateTime).compareTo(a['time'] as DateTime));

      setState(() {
        _notifications = processedNotifications;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading notifications: $e');
      }
      setState(() {
        _notifications = [];
        _isLoading = false;
      });
    }
  }

  // Helper method to remove duplicate medicine notifications
  List<Map<String, dynamic>> _removeDuplicateMedicineNotifications(
      List<Map<String, dynamic>> notifications) {
    final uniqueNotifications = <Map<String, dynamic>>[];
    final seenKeys = <String>{};

    for (final notification in notifications) {
      // Process notification type
      if (_isMedicineNotification(notification) &&
          notification['type'] != 'medication') {
        notification['type'] = 'medication';
      }

      // Create a unique key for each notification based on critical fields
      final String title = notification['title']?.toString() ?? '';
      final DateTime time = notification['time'] as DateTime;
      final String timeFormatted = DateFormat('yyyy-MM-dd').format(time);
      final String type = notification['type']?.toString() ?? '';
      final bool isPending = notification['isPending'] == true;

      // For medicine notifications, use title and date (not exact timestamp)
      // to avoid duplicates from scheduling the same medicine multiple times
      // For pending notifications, include pending status in the key
      String uniqueKey;
      if (type == 'medication') {
        final String medicineName = _extractMedicineName(title);
        uniqueKey =
            '$medicineName-$timeFormatted-$type-${isPending ? 'pending' : 'delivered'}';
      } else {
        // For other notifications, use full details
        uniqueKey = '$title-${time.toIso8601String()}-$type';
      }

      if (!seenKeys.contains(uniqueKey)) {
        seenKeys.add(uniqueKey);
        uniqueNotifications.add(notification);
      }
    }

    return uniqueNotifications;
  }

  // Extract medicine name from notification title
  String _extractMedicineName(String title) {
    // Remove common prefixes from medicine notification titles
    String cleanTitle = title
        .replaceAll('Medicine Reminder: ', '')
        .replaceAll('Take your ', '')
        .replaceAll('Time to take ', '')
        .trim();

    // If there's still a colon, take the part after it
    if (cleanTitle.contains(':')) {
      cleanTitle = cleanTitle.split(':').last.trim();
    }

    return cleanTitle;
  }

  // Helper method to detect medicine notifications
  bool _isMedicineNotification(Map<String, dynamic> notification) {
    // Check type field first
    if (notification['type'] == 'medication' ||
        notification['type'] == 'medicine') {
      return true;
    }

    // Check title
    final String title = notification['title']?.toString().toLowerCase() ?? '';
    if (title.contains('medicine') ||
        title.contains('medication') ||
        title.contains('dose') ||
        title.contains('pill') ||
        title.contains('tablet')) {
      return true;
    }

    // Check body
    final String body = notification['body']?.toString().toLowerCase() ?? '';
    if (body.contains('medicine') ||
        body.contains('medication') ||
        body.contains('dose') ||
        body.contains('take your')) {
      return true;
    }

    // Check data
    final data = notification['data'] ?? {};
    if (data is Map) {
      if (data['type'] == 'medication' ||
          data['medicineName'] != null ||
          data['medicine'] != null) {
        return true;
      }
    }

    return false;
  }

  // Get icon based on notification type - updated version
  Widget _getNotificationIcon(String type) {
    // Normalize the type to handle variations
    final String normalizedType = type.toString().toLowerCase().trim();

    // Use more robust type detection
    if (normalizedType == 'medication' ||
        normalizedType == 'medicine' ||
        normalizedType.contains('med')) {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.blue[700],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.medication_outlined,
          color: Colors.white,
          size: 30,
        ),
      );
    } else if (normalizedType == 'appointment' ||
        normalizedType.contains('appt')) {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.green[700],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.medical_services_outlined,
          color: Colors.white,
          size: 30,
        ),
      );
    } else if (normalizedType == 'ambulance_request' ||
        normalizedType.contains('ambulance')) {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.red[700],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.local_hospital_outlined,
          color: Colors.white,
          size: 30,
        ),
      );
    } else if (normalizedType == 'emergency' ||
        normalizedType.contains('emerg')) {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.orange[700],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.warning_amber_outlined,
          color: Colors.white,
          size: 30,
        ),
      );
    } else {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.notifications_outlined,
          color: Colors.white,
          size: 30,
        ),
      );
    }
  }

  // Format time for delivered notifications
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      // Today - show time only
      return 'Today at ${DateFormat('hh:mm a').format(time)}';
    } else if (difference.inDays == 1) {
      // Yesterday
      return 'Yesterday at ${DateFormat('hh:mm a').format(time)}';
    } else if (difference.inDays < 7) {
      // This week
      return '${DateFormat('EEEE').format(time)} at ${DateFormat('hh:mm a').format(time)}';
    } else {
      // Older
      return '${DateFormat('dd MMM yyyy').format(time)} at ${DateFormat('hh:mm a').format(time)}';
    }
  }

  // Format time for scheduled notifications
  String _formatScheduledTime(DateTime scheduledTime) {
    final now = DateTime.now();
    final difference = scheduledTime.difference(now);

    // If it's today
    if (scheduledTime.year == now.year &&
        scheduledTime.month == now.month &&
        scheduledTime.day == now.day) {
      return 'Today at ${DateFormat('hh:mm a').format(scheduledTime)}';
    }
    // If it's tomorrow
    else if (scheduledTime.year == now.year &&
        scheduledTime.month == now.month &&
        scheduledTime.day == now.day + 1) {
      return 'Tomorrow at ${DateFormat('hh:mm a').format(scheduledTime)}';
    }
    // If it's within the next 7 days
    else if (difference.inDays < 7) {
      return '${DateFormat('EEEE').format(scheduledTime)} at ${DateFormat('hh:mm a').format(scheduledTime)}';
    }
    // If it's beyond 7 days
    else {
      return '${DateFormat('MMM dd').format(scheduledTime)} at ${DateFormat('hh:mm a').format(scheduledTime)}';
    }
  }

  // Delete notification
  void _deleteNotification(String id) async {
    try {
      // Try to use MedicineNotificationService
      try {
        await MedicineNotificationService.deleteNotification(id);
      } catch (e) {
        // Fallback to direct SharedPreferences if service method isn't available
        if (kDebugMode) {
          print(
              'Error using MedicineNotificationService.deleteNotification: $e');
          print('Falling back to direct SharedPreferences manipulation');
        }

        final prefs = await SharedPreferences.getInstance();
        final notificationsJson =
            prefs.getString('notification_history') ?? '[]';

        List<dynamic> notifications = [];
        try {
          notifications = jsonDecode(notificationsJson);

          // Remove the notification with matching ID
          notifications.removeWhere((item) => item['id'] == id);

          // Save back to storage
          await prefs.setString(
              'notification_history', jsonEncode(notifications));
        } catch (e) {
          if (kDebugMode) {
            print('Error manipulating notifications in SharedPreferences: $e');
          }
        }
      }

      // Update UI
      setState(() {
        _notifications.removeWhere((notification) => notification['id'] == id);
      });

      if (!mounted) return;

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

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete notification'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // Clear all notifications
  void _clearAllNotifications() async {
    try {
      // Try to use MedicineNotificationService
      try {
        await MedicineNotificationService.clearNotificationHistory();
      } catch (e) {
        // Fallback to direct SharedPreferences if service method isn't available
        if (kDebugMode) {
          print(
              'Error using MedicineNotificationService.clearNotificationHistory: $e');
          print('Falling back to direct SharedPreferences manipulation');
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('notification_history', '[]');
        await prefs.setString('pending_notifications', '[]');
      }

      // Update UI
      setState(() {
        _notifications.clear();
      });

      if (!mounted) return;

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

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to clear notifications'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // Refresh notifications list
  Future<void> _refreshNotifications() async {
    await _loadNotifications();
  }

  // Handle notification tap
  void _handleNotificationTap(Map<String, dynamic> notification) async {
    try {
      final data = notification['data'];
      final type = notification['type'].toString().toLowerCase();
      final bool isPending = notification['isPending'] == true;

      // If it's a pending notification, show different behavior
      if (isPending) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'This medicine reminder is scheduled for ${_formatScheduledTime(notification['time'])}'),
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      if (type == 'ambulance_request' &&
          data != null &&
          data['requestId'] != null) {
        // Handle ambulance request
        await _fetchRequestDataAndNavigate(data['requestId']);
      } else if (type == 'medication' ||
          type == 'medicine' ||
          _isMedicineNotification(notification)) {
        // Navigate to medicines screen if available
        try {
          Navigator.of(context).pushNamed('/medicines');
        } catch (e) {
          if (kDebugMode) {
            print('Error navigating to medicines screen: $e');
          }
          // Handle navigation error gracefully
        }
      } else if (type == 'appointment') {
        // Navigate to appointments screen if available
        try {
          Navigator.of(context).pushNamed('/appointments');
        } catch (e) {
          if (kDebugMode) {
            print('Error navigating to appointments screen: $e');
          }
          // Handle navigation error gracefully
        }
      } else if (type == 'emergency') {
        // Navigate to emergency screen if available
        try {
          Navigator.of(context).pushNamed('/emergency');
        } catch (e) {
          if (kDebugMode) {
            print('Error navigating to emergency screen: $e');
          }
          // Handle navigation error gracefully
        }
      }
      // For general notifications, just showing the detail is enough
    } catch (e) {
      if (kDebugMode) {
        print('Error handling notification tap: $e');
      }
    }
  }

  // Fetch ambulance request data and navigate
  Future<void> _fetchRequestDataAndNavigate(String requestId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('ambulanceRequests')
          .doc(requestId)
          .get();

      if (!doc.exists) {
        if (kDebugMode) {
          print('Request document not found: $requestId');
        }
        return;
      }

      final Map<String, dynamic> completeData = {
        ...doc.data() as Map<String, dynamic>,
        'id': doc.id,
      };

      if (!mounted) return;

      // Navigate to detail page
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

  // Render a notification item with pending support
  Widget _renderNotificationItem(Map<String, dynamic> notification) {
    final bool isPending = notification['isPending'] == true ||
        notification['status'] == 'pending';

    return InkWell(
      onTap: () => _handleNotificationTap(notification),
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 6.0,
        ),
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
              // Notification icon (with pending indicator if needed)
              Stack(
                children: [
                  _getNotificationIcon(notification['type'] ?? 'general'),
                  if (isPending)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.schedule,
                            size: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              // Notification content
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
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    // Show scheduled time differently for pending notifications
                    Text(
                      isPending
                          ? _formatScheduledTime(
                              notification['scheduledTime'] != null
                                  ? DateTime.parse(
                                      notification['scheduledTime'])
                                  : notification['time'] as DateTime)
                          : _formatTime(notification['time'] ?? DateTime.now()),
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isPending ? Colors.orange[700] : Colors.grey[600],
                        fontWeight:
                            isPending ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    // Type indicator with status
                    Row(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getTypeColor(
                                notification['type'] ?? 'general'),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getTypeText(notification['type'] ?? 'general'),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (isPending) ...[
                          const SizedBox(width: 6),
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange[700],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'SCHEDULED',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Delete button
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.grey,
                ),
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
      backgroundColor: AppColor.backgroundGrey,
      // Make the whole screen scrollable with SingleChildScrollView
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshNotifications,
          child: CustomScrollView(
            slivers: [
              // App bar with back button and title
              SliverAppBar(
                backgroundColor: AppColor.backgroundGrey,
                elevation: 0,
                floating: true,
                toolbarHeight: 48, // Set explicit height for toolbar
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  background: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        16.0, 0, 16.0, 0), // Adjusted padding
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment:
                          MainAxisAlignment.end, // Align to bottom
                      children: [
                        // Back button row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                width: 40, // Smaller
                                height: 40, // Smaller
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.grey,
                                  size: 20, // Smaller
                                ),
                              ),
                            ),
                            // Clear button moved here to save vertical space
                            if (_notifications.isNotEmpty)
                              TextButton.icon(
                                onPressed: _clearAllNotifications,
                                icon: const Icon(Icons.delete_sweep_outlined,
                                    size: 18),
                                label: const Text('Clear All',
                                    style: TextStyle(fontSize: 12)),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                expandedHeight: 48, // Reduced from 120
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Notifications',
                        style: TextStyle(
                          fontSize: 28, // Reduced from 32
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 4),
                    ],
                  ),
                ),
              ),

              // Loading indicator
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),

              // Empty state
              if (!_isLoading && _notifications.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_off_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No notifications',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Pull down to refresh',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Notification list
              if (!_isLoading && _notifications.isNotEmpty)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == _notifications.length) {
                        // Footer at the end of the list
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
                    childCount: _notifications.length + 1, // +1 for footer
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Get color based on notification type
  Color _getTypeColor(String type) {
    final String normalizedType = type.toString().toLowerCase().trim();

    if (normalizedType == 'medication' ||
        normalizedType == 'medicine' ||
        normalizedType.contains('med')) {
      return Colors.blue[700]!;
    } else if (normalizedType == 'appointment' ||
        normalizedType.contains('appt')) {
      return Colors.green[700]!;
    } else if (normalizedType == 'ambulance_request' ||
        normalizedType.contains('ambulance')) {
      return Colors.red[700]!;
    } else if (normalizedType == 'emergency' ||
        normalizedType.contains('emerg')) {
      return Colors.orange[700]!;
    } else {
      return Colors.grey[700]!;
    }
  }

  // Get text for notification type
  String _getTypeText(String type) {
    final String normalizedType = type.toString().toLowerCase().trim();

    if (normalizedType == 'medication' ||
        normalizedType == 'medicine' ||
        normalizedType.contains('med')) {
      return 'MEDICINE';
    } else if (normalizedType == 'appointment' ||
        normalizedType.contains('appt')) {
      return 'APPOINTMENT';
    } else if (normalizedType == 'ambulance_request' ||
        normalizedType.contains('ambulance')) {
      return 'AMBULANCE';
    } else if (normalizedType == 'emergency' ||
        normalizedType.contains('emerg')) {
      return 'EMERGENCY';
    } else {
      return 'NOTIFICATION';
    }
  }
}
