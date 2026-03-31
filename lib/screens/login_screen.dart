import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'dashboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();

  bool loading = false;
  bool rememberMe = false;
  bool isConnected = true;

  @override
  void initState() {
    super.initState();
    checkInternet();
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
    // Reset form
    email.clear();
    password.clear();

    setState(() {
      rememberMe = false;
    });

    // Check internet
    await checkInternet();

    // Small delay for smooth UI
    await Future.delayed(const Duration(milliseconds: 800));
  }

  // 🔐 Login
  void loginUser() async {
    if (!isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Connect to Internet first")),
      );
      return;
    }

    if (email.text.isEmpty || password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Email and Password are required"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => loading = true);

    var result = await ApiService.login(
      email.text,
      password.text,
      rememberMe,
    );

    setState(() => loading = false);

    if (result != null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', result['token']);
      await prefs.setBool('rememberMe', rememberMe);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DashboardScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Invalid Credentials"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 🔁 Forgot Password Logic
  void forgotPassword() async {
    if (email.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter your email first")),
      );
      return;
    }

    if (!isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No Internet Connection")),
      );
      return;
    }

    var result = await ApiService.forgotPassword(email.text);

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Reset link sent to your email"),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to send reset link"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: refreshPage,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue, Colors.purple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.admin_panel_settings,
                            size: 60, color: Colors.blue),
                        const SizedBox(height: 10),
                        const Text("Admin Login",
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold)),

                        const SizedBox(height: 20),

                        TextField(
                          controller: email,
                          decoration: InputDecoration(
                            labelText: "Email",
                            prefixIcon: const Icon(Icons.email),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),

                        const SizedBox(height: 15),

                        TextField(
                          controller: password,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: "Password",
                            prefixIcon: const Icon(Icons.lock),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: rememberMe,
                                  onChanged: (val) {
                                    setState(() {
                                      rememberMe = val ?? false;
                                    });
                                  },
                                ),
                                const Text("Remember Me"),
                              ],
                            ),

                            // 🔐 Forgot Password Button
                            TextButton(
                              onPressed: forgotPassword,
                              child: const Text("Forgot Password?"),
                            )
                          ],
                        ),

                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: loading ? null : loginUser,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding:
                              const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: loading
                                ? const CircularProgressIndicator(
                                color: Colors.white)
                                : const Text("Login"),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // 🌐 Show Internet Status
                        if (!isConnected)
                          const Text(
                            "No Internet Connection",
                            style: TextStyle(color: Colors.red),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}