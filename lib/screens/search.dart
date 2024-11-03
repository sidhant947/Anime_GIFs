import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import '../utils/gif.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<Gif> searchResults = [];
  bool isLoading = false;
  final TextEditingController _controller = TextEditingController();

  Future<void> searchGifs(String query) async {
    if (query.isEmpty) return;

    setState(() {
      isLoading = true;
      searchResults.clear();
    });

    final response = await http.get(Uri.parse(
        'https://nekos.best/api/v2/search?query=$query&type=gif&amount=10'));

    if (response.statusCode == 200) {
      final List<dynamic> json = jsonDecode(response.body)['results'];
      setState(() {
        searchResults = json.map((gif) => Gif.fromJson(gif)).toList();
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      throw Exception('Failed to search GIFs');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search GIFs'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Search for GIFs...',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    searchGifs(_controller.text);
                  },
                ),
              ),
              onSubmitted: (value) {
                searchGifs(value);
              },
            ),
          ),
          if (isLoading) CircularProgressIndicator(),
          Expanded(
            child: ListView.builder(
              itemCount: searchResults.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    // Handle what happens when a GIF is tapped
                    downloadGif(searchResults[index].url);
                  },
                  child: Card(
                    color: Colors.black,
                    child: Column(
                      children: [
                        CachedNetworkImage(
                          imageUrl: searchResults[index].url,
                          placeholder: (context, url) =>
                              CircularProgressIndicator(),
                          errorWidget: (context, url, error) =>
                              Icon(Icons.error, color: Colors.white),
                        ),
                        SizedBox(height: 8),
                        Text(
                          searchResults[index].animeName,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> downloadGif(String url) async {
    try {
      var dir = await getApplicationDocumentsDirectory();
      String savePath = "${dir.path}/${url.split('/').last}";

      Dio dio = Dio();
      await dio.download(url, savePath);

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Downloaded to $savePath')));
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to download GIF')));
    }
  }
}
