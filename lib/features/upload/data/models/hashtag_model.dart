class HashtagModel {
  final String query;
  final int count;

  HashtagModel({
    required this.query,
    required this.count,
  });

  // JSON에서 모델로 변환
  factory HashtagModel.fromJson(Map<String, dynamic> json) {
    return HashtagModel(
      query: json['query'] as String,
      count: json['count'] as int,
    );
  }

  // 모델에서 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'count': count,
    };
  }

  // copyWith 메소드
  HashtagModel copyWith({
    String? query,
    int? count,
  }) {
    return HashtagModel(
      query: query ?? this.query,
      count: count ?? this.count,
    );
  }

}