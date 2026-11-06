import 'package:daily_motivation_ai/models/media_art.dart';

/// How a service is delivered.
enum ServiceMode { online, inPerson, both }

extension ServiceModeLabel on ServiceMode {
  String get label => switch (this) {
        ServiceMode.online => 'Online',
        ServiceMode.inPerson => 'In person',
        ServiceMode.both => 'Online or in person',
      };
}

const List<String> serviceCategories = ['All', 'Coaching', 'Creative', 'Tech', 'Food', 'Travel', 'Learning'];

/// Something a person on Orbit offers to others: a coaching session, a photo
/// shoot, a code review. Booking starts as a chat request; payment for
/// real-world services is arranged between the two people.
class OrbitService {
  final String id;
  final String providerId;
  final String title;
  final String category;
  final String description;
  final int price;
  final String currency;
  final String unit;
  final ServiceMode mode;
  final double rating;
  final int reviews;
  final MediaArt art;
  final bool featured;

  const OrbitService({
    required this.id,
    required this.providerId,
    required this.title,
    required this.category,
    required this.description,
    required this.price,
    this.currency = '₹',
    required this.unit,
    required this.mode,
    this.rating = 0,
    this.reviews = 0,
    required this.art,
    this.featured = false,
  });

  String get priceLabel => price == 0 ? 'Free' : '$currency$price';

  OrbitService copyWith({bool? featured}) => OrbitService(
        id: id,
        providerId: providerId,
        title: title,
        category: category,
        description: description,
        price: price,
        currency: currency,
        unit: unit,
        mode: mode,
        rating: rating,
        reviews: reviews,
        art: art,
        featured: featured ?? this.featured,
      );
}
