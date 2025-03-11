import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import '../../../services/api_utils.dart';
// import 'dart:html' as html;

class AddNewsPage extends StatefulWidget {
  @override
  _AddNewsPageState createState() => _AddNewsPageState();
}

class _AddNewsPageState extends State<AddNewsPage> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _fullNewsController = TextEditingController();
  Uint8List? _imageBytes;
  String? _imageName;
  final _formKey = GlobalKey<FormState>();

  // Function to pick an image (Flutter web support)
  Future<void> _pickImage() async {
    // final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
    // uploadInput.accept = 'image/*';
    // uploadInput.click();

    // uploadInput.onChange.listen((event) {
    //   final files = uploadInput.files;
    //   if (files!.isNotEmpty) {
    //     final file = files[0];
    //     final reader = html.FileReader();

    //     reader.readAsArrayBuffer(file);
    //     reader.onLoadEnd.listen((e) {
    //       setState(() {
    //         _imageBytes = reader.result as Uint8List;
    //         _imageName = file.name;
    //       });
    //     });
    //   }
    // });
  }

  // Function to submit news to backend
  Future<void> _submitNews() async {
    if (_formKey.currentState!.validate() && _imageBytes != null) {
      try {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('${ApiUtils.baseUrl}/api/news'),
        );

        Map<String, String> newsData = {
          "descriptionParagraph": _descriptionController.text.replaceAll('\n', '\\n').replaceAll('"', '\\"'),
          "fullNews": _fullNewsController.text.replaceAll('\n', '\\n').replaceAll('"', '\\"'),
        };

        request.fields['news'] = jsonEncode(newsData);
        request.files.add(http.MultipartFile.fromBytes('image', _imageBytes!, filename: _imageName));

        var response = await request.send();

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("News added successfully!")),
          );
          _descriptionController.clear();
          _fullNewsController.clear();
          setState(() {
            _imageBytes = null;
            _imageName = null;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to add news")),
          );
        }
      } catch (e) {
        print("Error submitting news: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error submitting news")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill all fields and select an image.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add News")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Description field with improved scrolling and selection
              Scrollbar(
                thumbVisibility: true,
                child: TextFormField(
                  controller: _descriptionController,
                  maxLines: 5,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    labelText: "Enter news description",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Description is required";
                    }
                    return null;
                  },
                  enableInteractiveSelection: true, // Enables text selection
                  cursorWidth: 2, // Set cursor width
                  cursorColor: Colors.blue,
                  showCursor: true, // Ensures cursor visibility
                ),
              ),
              SizedBox(height: 20),

              // Full news field with scrolling and better UX
              Scrollbar(
                thumbVisibility: true,
                child: Container(
                  height: 250,
                  child: SingleChildScrollView(
                    child: TextFormField(
                      controller: _fullNewsController,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                        labelText: "Enter full news",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Full news is required";
                        }
                        return null;
                      },
                      enableInteractiveSelection: true, // Enables text selection
                      cursorWidth: 2, // Fixes cursor visibility
                      cursorColor: Colors.blue,
                      showCursor: true,
                      textAlignVertical: TextAlignVertical.top,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),

              _imageBytes == null
                  ? Text("No image selected", style: TextStyle(color: Colors.red))
                  : Image.memory(_imageBytes!, height: 150, width: double.infinity, fit: BoxFit.cover),
              SizedBox(height: 20),

              ElevatedButton(
                onPressed: _pickImage,
                child: Text("Pick Image"),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitNews,
                child: Text("Submit News"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
