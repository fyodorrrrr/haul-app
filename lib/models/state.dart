class StateModel {
  final String name;
  final String iso2;

  StateModel({required this.name, required this.iso2});

  factory StateModel.fromJson(Map<String, dynamic> json) {
    return StateModel(
      name: json['name'],
      iso2: json['iso2'],
    );
  }
}
