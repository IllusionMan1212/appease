class Cheese {
  // TODO: decode the attributes and other stuff?

  final String name;
  final String link;
  final String imageURL;
  // late Object attributes;
  final String description;
  final List<dynamic> countryCodes;
  final List<dynamic> milks;

  Cheese({
    required this.name,
    required this.link,
    required this.imageURL,
    required this.description,
    required this.countryCodes,
    required this.milks,
  });

  factory Cheese.fromJson(Map<dynamic, dynamic> json) {
    String name = json['name'];
    String link = json['link'];
    String image = json['image'];
    String desc = json['description'];
    List<dynamic> countryCodes = json['country_codes'];
    List<dynamic> milks = json['milks'];

    return Cheese(
      name: name,
      link: link,
      imageURL: image,
      description: desc,
      countryCodes: countryCodes,
      milks: milks,
    );
  }
}
