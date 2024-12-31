class CategoryModel {
  // 카테고리 아이디
  final String id;

  // 카테고리 이름
  final String name;

  // 카테고리 설명
  final String? description;

  CategoryModel({
    required this.id,
    required this.name,
    this.description,
  });

  // JSON -> CategoryModel
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
    );
  }

  // CategoryModel -> JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }
}
