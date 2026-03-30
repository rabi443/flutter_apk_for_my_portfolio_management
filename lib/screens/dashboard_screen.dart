import 'package:flutter/material.dart';
import 'data_screen.dart';
import 'login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreen extends StatelessWidget {
  void logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
          (route) => false,
    );
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
      appBar: AppBar(title: Text("Admin Dashboard")),
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