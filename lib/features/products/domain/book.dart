class Book {
  final String id;
  final String title;
  final String author;
  final int price;
  final String? coverUrl;
  final String? description;
  final String? category;
  final String? readingPath;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.price,
    this.coverUrl,
    this.description,
    this.category,
    this.readingPath,
  });

  // Conversion manuelle : On prend le JSON de Supabase et on remplit l'objet
  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'].toString(),
      title: json['title'] as String,
      author: json['author'] as String,
      price: (json['price'] as num).toInt(), // Sécurité si c'est un double
      coverUrl: json['cover_url'] as String?,
      description: json['description'] as String?,
      category: json['category'] as String?,
      readingPath: json['reading_path'] as String?,
    );
  }
}
