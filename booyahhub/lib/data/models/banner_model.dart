class BannerModel {
  final int id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final DateTime startDate;
  final DateTime endDate;
  final String status; // aktif, draft, expired
  final String? link;
  final int? priority;
  final DateTime createdAt;

  BannerModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.link,
    this.priority,
    required this.createdAt,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'],
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      imageUrl: json['image_url'] ?? '',
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      status: json['status'] ?? 'draft',
      link: json['link'],
      priority: json['priority'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'image_url': imageUrl,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'status': status,
      'link': link,
      'priority': priority,
      'created_at': createdAt.toIso8601String(),
    };
  }
}