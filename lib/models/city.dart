class City {
  final String name;

  City({required this.name});

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      name: json['name'],
    );
  }
}
