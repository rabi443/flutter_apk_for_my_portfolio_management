import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DataScreen extends StatefulWidget {
  final String title;
  final String endpoint;

  DataScreen({required this.title, required this.endpoint});

  @override
  _DataScreenState createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen> {
  List<dynamic> data = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  void fetchData() async {
    setState(() => loading = true);
    try {
      List<dynamic>? result = await ApiService.getData(widget.endpoint);
      setState(() {
        data = result ?? [];
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to fetch data: $e")));
    }
  }

  void confirmDelete(dynamic id) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirm Delete"),
        content: Text("Are you sure you want to delete this item?"),
        actions: [
          TextButton(child: Text("Cancel"), onPressed: () => Navigator.pop(context, false)),
          ElevatedButton(
            child: Text("Delete"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm) deleteItem(id);
  }

  void deleteItem(dynamic id) async {
    int parsedId = int.parse(id.toString());
    bool success = await ApiService.deleteData(widget.endpoint, parsedId);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success ? "Deleted successfully" : "Failed to delete"),
      duration: Duration(seconds: 2),
    ));
    if (success) fetchData();
  }

  void openForm({Map<String, dynamic>? item}) {
    final _formKey = GlobalKey<FormState>();
    Map<String, dynamic> formData = item != null ? Map.from(item) : {};
    List<String> allowedFields;
    if (widget.endpoint == 'users') {
      allowedFields = ['name', 'email', 'password'];
    } else {
      allowedFields = data.isNotEmpty
          ? data[0].keys
          .where((k) => k != 'id' && k != 'created_at' && k != 'updated_at')
          .toList()
          : [];
    }

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
                children: allowedFields.map<Widget>((k) {
                  String? initialValue =
                  (k == 'password' && item != null) ? '' : formData[k]?.toString() ?? '';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
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
            TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
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
                      duration: Duration(seconds: 2),
                    ));
                    if (success) fetchData();
                  } catch (e) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error: $e"), duration: Duration(seconds: 2)));
                  }
                }
              },
              child: Text("Submit"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title), backgroundColor: Colors.deepPurple),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : data.isEmpty
          ? Center(
        child: Text(
          "No records found",
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      )
          : SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          margin: EdgeInsets.all(12),
          child: DataTable(
            headingRowColor: MaterialStateColor.resolveWith(
                    (states) => Colors.deepPurple.shade100),
            columnSpacing: 20,
            dataRowHeight: 60,
            columns: [
              ...data[0].keys
                  .map<DataColumn>((k) => DataColumn(
                label: Text(
                  k.toString(),
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple),
                ),
              ))
                  .toList(),
              DataColumn(
                  label: Text(
                    'Actions',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.deepPurple),
                  )),
            ],
            rows: data
                .map<DataRow>((item) => DataRow(cells: [
              ...item.values
                  .map<DataCell>((v) => DataCell(Text(v.toString())))
                  .toList(),
              DataCell(Row(
                children: [
                  IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => openForm(item: item)),
                  IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => confirmDelete(item['id'])),
                ],
              ))
            ]))
                .toList(),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => openForm(),
        child: Icon(Icons.add),
        backgroundColor: Colors.deepPurple,
      ),
    );
  }
}