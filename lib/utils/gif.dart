class Gif {
  final String animeName;
  final String url;

  Gif({required this.animeName, required this.url});

  factory Gif.fromJson(Map<String, dynamic> json) {
    return Gif(
      animeName: json['anime_name'],
      url: json['url'],
    );
  }
}
