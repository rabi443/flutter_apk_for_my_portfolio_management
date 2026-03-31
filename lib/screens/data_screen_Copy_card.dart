import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:excel/excel.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class DataScreen extends StatefulWidget {
  final String title;
  final String endpoint;

  DataScreen({required this.title, required this.endpoint});

  @override
  _DataScreenState createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen> {
  List<dynamic> data = [];
  List<dynamic> filteredData = [];
  bool loading = true;
  bool isConnected = true;

  int currentPage = 1;
  int perPage = 10;

  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    checkInternet();
    fetchData();
  }

  Future<void> checkInternet() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    bool nowConnected = connectivityResult != ConnectivityResult.none;

    setState(() => isConnected = nowConnected);

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

  Future<void> refreshPage() async {
    await checkInternet();
    if (isConnected) fetchData();
    await Future.delayed(const Duration(milliseconds: 500));
  }

  void fetchData() async {
    if (!isConnected) {
      setState(() => loading = false);
      return;
    }

    setState(() => loading = true);
    try {
      List<dynamic>? result = await ApiService.getData(widget.endpoint);
      setState(() {
        data = result ?? [];
        filteredData = data;
        loading = false;
        currentPage = 1;
      });
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to fetch data: $e")),
      );
    }
  }

  void filterData(String query) {
    if (query.isEmpty) {
      setState(() => filteredData = data);
    } else {
      setState(() {
        filteredData = data
            .where((item) => item.values
            .any((v) => v.toString().toLowerCase().contains(query.toLowerCase())))
            .toList();
      });
    }
  }

  void confirmDelete(dynamic id) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this item?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) deleteItem(id);
  }

  void deleteItem(dynamic id) async {
    if (!isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No Internet Connection")),
      );
      return;
    }

    int parsedId = int.parse(id.toString());
    bool success = await ApiService.deleteData(widget.endpoint, parsedId);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? "Deleted successfully" : "Failed to delete")),
    );

    if (success) fetchData();
  }

  void openForm({Map<String, dynamic>? item}) {
    final _formKey = GlobalKey<FormState>();
    Map<String, dynamic> formData = item != null ? Map.from(item) : {};

    List<String> allowedFields = widget.endpoint == 'users'
        ? ['name', 'email', 'password']
        : data.isNotEmpty
        ? data[0].keys.where((k) => k != 'id' && k != 'created_at' && k != 'updated_at').toList()
        : [];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(item != null ? "Edit Item" : "Add Item"),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: allowedFields.map((k) {
                  String initialValue = (k == 'password' && item != null) ? '' : formData[k]?.toString() ?? '';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: TextFormField(
                      initialValue: initialValue,
                      obscureText: k == 'password',
                      decoration: InputDecoration(
                        labelText: k,
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      onSaved: (val) => formData[k] = val,
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (!isConnected) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("No Internet Connection")),
                  );
                  return;
                }

                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();

                  bool success = false;
                  try {
                    if (item != null) {
                      int parsedId = int.parse(item['id'].toString());
                      success = await ApiService.updateData(widget.endpoint, parsedId, formData);
                    } else {
                      success = await ApiService.createData(widget.endpoint, formData);
                    }

                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(success ? (item != null ? "Updated!" : "Created!") : "Failed"),
                    ));

                    if (success) fetchData();
                  } catch (e) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error: $e")),
                    );
                  }
                }
              },
              child: const Text("Submit"),
            ),
          ],
        );
      },
    );
  }

  // 📊 Export Excel
  Future<void> exportExcel() async {
    if (data.isEmpty) return;

    var excel = Excel.createExcel();
    Sheet sheet = excel['Sheet1'];

    sheet.appendRow(data[0].keys.map((k) => k.toString()).toList());

    for (var item in data) {
      sheet.appendRow(item.values.map((v) => v.toString()).toList());
    }

    Directory directory = await getApplicationDocumentsDirectory();
    String filePath = "${directory.path}/${widget.title}.xlsx";

    File(filePath)
      ..createSync(recursive: true)
      ..writeAsBytesSync(excel.encode()!);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Excel exported: $filePath")),
    );
  }

  @override
  Widget build(BuildContext context) {
    int totalPages = (filteredData.length / perPage).ceil();
    int start = (currentPage - 1) * perPage;
    int end = (start + perPage) > filteredData.length ? filteredData.length : (start + perPage);
    List<dynamic> pageData = filteredData.sublist(start, end);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(icon: const Icon(Icons.file_download), onPressed: exportExcel),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: refreshPage,
        child: loading
            ? ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 300),
            Center(child: CircularProgressIndicator()),
          ],
        )
            : Column(
          children: [
            if (!isConnected)
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  "No Internet Connection",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: "Search...",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: filterData,
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: pageData.length,
                itemBuilder: (context, index) {
                  var item = pageData[index];
                  return Card(
                    margin: const EdgeInsets.all(8),
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      title: Text(item.values.first.toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(item.values.skip(1).map((v) => v.toString()).join(", ")),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => openForm(item: item)),
                          IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => confirmDelete(item['id'])),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (totalPages > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: currentPage > 1 ? () => setState(() => currentPage--) : null,
                  ),
                  Text("Page $currentPage / $totalPages"),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: currentPage < totalPages ? () => setState(() => currentPage++) : null,
                  ),
                ],
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => openForm(),
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add),
      ),
    );
  }
}