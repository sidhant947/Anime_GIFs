import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import '../utils/gif.dart';

class GifList extends StatefulWidget {
  @override
  _GifListState createState() => _GifListState();
}

class _GifListState extends State<GifList> {
  List<Gif> gifs = [];
  bool isLoading = false;
  int amount = 10;

  @override
  void initState() {
    super.initState();
    fetchGifs();
  }

  Future<void> fetchGifs() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    final response = await http
        .get(Uri.parse('https://nekos.best/api/v2/hug?amount=$amount'));

    if (response.statusCode == 200) {
      final List<dynamic> json = jsonDecode(response.body)['results'];
      if (mounted) {
        setState(() {
          gifs.addAll(json.map((gif) => Gif.fromJson(gif)).toList());
          isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      throw Exception('Failed to load GIFs');
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Anime GIFs'),
        centerTitle: true,
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (!isLoading &&
              scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
            fetchGifs();
          }
          return true;
        },
        child: ListView.builder(
          itemCount: gifs.length + (isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == gifs.length) {
              return Center(child: CircularProgressIndicator());
            }

            return Card(
              color: Colors.black,
              child: Column(
                children: [
                  CachedNetworkImage(
                    imageUrl: gifs[index].url,
                    placeholder: (context, url) => CircularProgressIndicator(),
                    errorWidget: (context, url, error) =>
                        Icon(Icons.error, color: Colors.white),
                  ),
                  SizedBox(height: 8),
                  Text(
                    gifs[index].animeName,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => downloadGif(gifs[index].url),
                    child: Text('Download'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
