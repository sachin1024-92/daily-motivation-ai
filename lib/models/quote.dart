class Quote {
  final String text;
  final String author;

  const Quote({required this.text, required this.author});

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      text: json['text'] ?? '',
      author: json['author'] ?? 'Unknown',
    );
  }
}

final List<Quote> defaultQuotes = const [
  Quote(text: "The only way to do great work is to love what you do.", author: "Steve Jobs"),
  Quote(text: "Success is not final, failure is not fatal: it is the courage to continue that counts.", author: "Winston Churchill"),
  Quote(text: "Believe you can and you're halfway there.", author: "Theodore Roosevelt"),
  Quote(text: "The future belongs to those who believe in the beauty of their dreams.", author: "Eleanor Roosevelt"),
  Quote(text: "It always seems impossible until it's done.", author: "Nelson Mandela"),
];
