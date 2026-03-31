import 'package:flutter/material.dart';
import 'data_screen.dart';
import 'login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int unreadMessages = 0;
  bool isConnected = true;

  @override
  void initState() {
    super.initState();
    checkInternet();
    fetchUnreadCount();
  }

  // 🌐 Check Internet
  Future<void> checkInternet() async {
    var connectivityResult = await Connectivity().checkConnectivity();

    bool nowConnected = connectivityResult != ConnectivityResult.none;

    setState(() {
      isConnected = nowConnected;
    });

    if (!nowConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No Internet Connection ❌"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // 🔄 Pull to Refresh
  Future<void> refreshPage() async {
    await checkInternet();

    if (isConnected) {
      fetchUnreadCount(); // reload data
    }

    await Future.delayed(const Duration(milliseconds: 800));
  }

  // 📩 Fetch unread messages
  void fetchUnreadCount() async {
    try {
      int count = await ApiService.getUnreadCount();
      setState(() => unreadMessages = count);
    } catch (e) {
      if (e.toString().contains("unauthorized")) {
        redirectToLogin();
      }
    }
  }

  void redirectToLogin() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
          (route) => false,
    );
  }

  void logout(BuildContext context) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Logout",
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != null && confirm) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      redirectToLogin();
    }
  }

  Widget buildMenuItem(BuildContext context, String title, String endpoint,
      {int badgeCount = 0}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 5,
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Row(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (badgeCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12)),
                child: Text(
                  badgeCount.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              )
            ]
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          if (title == "Logout") {
            logout(context);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      DataScreen(title: title, endpoint: endpoint)),
            ).then((_) => fetchUnreadCount());
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
      AppBar(title: const Text("Admin Dashboard"), centerTitle: true),
      body: RefreshIndicator(
        onRefresh: refreshPage,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            padding: const EdgeInsets.all(16),
            height: MediaQuery.of(context).size.height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade200, Colors.purple.shade200],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                // 🌐 Internet warning
                if (!isConnected)
                  const Text(
                    "No Internet Connection",
                    style: TextStyle(color: Colors.red),
                  ),

                buildMenuItem(context, "Manage Users", "users"),
                buildMenuItem(context, "Manage Personal Information", "personal-info"),
                buildMenuItem(
                  context,
                  "Manage Visitors Messages",
                  "contact-messages",
                  badgeCount: unreadMessages,
                ),
                buildMenuItem(context, "Manage Projects", "projects"),
                buildMenuItem(context, "Manage Skills", "skills"),
                buildMenuItem(context, "Logout", ""),
              ],
            ),
          ),
        ),
      ),
    );
  }
}