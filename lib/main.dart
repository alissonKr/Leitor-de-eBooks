import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:vocsy_epub_viewer/epub_viewer.dart';

void main() {
  runApp(MeuApp());
}

class Livro {
  final int id;
  final String title;
  final String author;
  final String coverUrl;
  final String downloadUrl;

  Livro({
    required this.id,
    required this.title,
    required this.author,
    required this.coverUrl,
    required this.downloadUrl,
  });

  factory Livro.fromJson(Map<String, dynamic> json) {
    return Livro(
      id: json['id'],
      title: json['title'],
      author: json['author'],
      coverUrl: json['cover_url'],
      downloadUrl: json['download_url'],
    );
  }
}

class MeuApp extends StatefulWidget {
  @override
  _MeuAppState createState() => _MeuAppState();
}

class _MeuAppState extends State<MeuApp> {
  late Future<List<Livro>> _livros;

  @override
  void initState() {
    super.initState();
    _livros = fetchBookList();
  }

  Future<List<Livro>> fetchBookList() async {
    final response =
        await http.get(Uri.parse('https://escribo.com/books.json'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Livro.fromJson(json)).toList().cast<Livro>();
    } else {
      throw Exception('Failed to load book list');
    }
  }

  Future<String> downloadAndSaveBook(Livro livro) async {
    final response = await http.get(Uri.parse(livro.downloadUrl));
    if (response.statusCode == 200) {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/${livro.title}.epub';
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      Fluttertoast.showToast(
        msg: "Download concluído",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return filePath;
    } else {
      throw Exception('Failed to download book');
    }
  }

  void openEpubBook(BuildContext context, String filePath) {
    try {
      VocsyEpub.open(
        filePath,
        lastLocation: null, // You can provide the last location if needed
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Failed to open the EPUB book. Error: $e'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Estante Virtual'),
        ),
        body: FutureBuilder<List<Livro>>(
          future: _livros,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                ),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      downloadAndSaveBook(snapshot.data![index])
                          .then((filePath) => openEpubBook(context, filePath));
                    },
                    child: Image.network(snapshot.data![index].coverUrl),
                  );
                },
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Text('Erro ao carregar a lista de livros'),
              );
            }
            return Center(
              child: CircularProgressIndicator(),
            );
          },
        ),
      ),
    );
  }
}
