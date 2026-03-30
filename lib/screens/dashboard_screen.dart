import 'package:flutter/material.dart';
import 'data_screen.dart';
import 'login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreen extends StatelessWidget {
  // Logout function with confirmation
  void logout(BuildContext context) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              "Logout",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != null && confirm) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
            (route) => false,
      );
    }
  }

  Widget buildMenuItem(BuildContext context, String title, String endpoint) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        trailing: Icon(Icons.arrow_forward_ios),
        onTap: () {
          if (title == "Logout") {
            logout(context);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DataScreen(title: title, endpoint: endpoint),
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Admin Dashboard"), centerTitle: true),
      body: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade200, Colors.purple.shade200],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView(
          children: [
            buildMenuItem(context, "Manage Users", "users"),
            buildMenuItem(context, "Manage Personal Information", "personal-info"),
            buildMenuItem(context, "Manage Visitors Messages", "contact-messages"),
            buildMenuItem(context, "Manage Projects", "projects"),
            buildMenuItem(context, "Manage Skills", "skills"),
            buildMenuItem(context, "Logout", ""),
          ],
        ),
      ),
    );
  }
}