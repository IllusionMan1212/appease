import 'package:flutter/material.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart';
import 'package:http/http.dart' as http;

class CheeseAttributes {
  final String? made;
  final List<dynamic> countries;
  final String? region;
  final String? family;
  final List<dynamic> types;
  final String? fat;
  final String? calcium;
  final List<dynamic> textures;
  final String? rind;
  final String? color;
  final List<dynamic> flavors;
  final List<dynamic> aromas;
  final bool? vegetarian;
  final List<dynamic> producers;
  final List<dynamic> synonyms;
  final List<dynamic> alternativeSpellings;

  CheeseAttributes({
    this.made,
    required this.countries,
    this.region,
    this.family,
    required this.types,
    this.fat,
    this.calcium,
    required this.textures,
    this.rind,
    this.color,
    required this.flavors,
    required this.aromas,
    this.vegetarian,
    required this.producers,
    required this.synonyms,
    required this.alternativeSpellings,
  });

  factory CheeseAttributes.fromJson(Map<String, dynamic> json) {
    String? made = json['made'];
    List<dynamic> countries = json['countries'];
    String? region = json['region'];
    String? family = json['family'];
    List<dynamic> types = json['types'];
    String? fat = json['fat'];
    String? calcium = json['calcium'];
    List<dynamic> textures = json['textures'];
    String? rind = json['rind'];
    String? color = json['color'];
    List<dynamic> flavors = json['flavors'];
    List<dynamic> aromas = json['aromas'];
    bool? vegetarian = json['vegetarian'];
    List<dynamic> producers = json['producers'];
    List<dynamic> synonyms = json['synonyms'];
    List<dynamic> alternativeSpellings = json['alternative_spellings'];

    return CheeseAttributes(
      made: made,
      countries: countries,
      region: region,
      family: family,
      types: types,
      fat: fat,
      calcium: calcium,
      textures: textures,
      rind: rind,
      color: color,
      flavors: flavors,
      aromas: aromas,
      vegetarian: vegetarian,
      producers: producers,
      synonyms: synonyms,
      alternativeSpellings: alternativeSpellings,
    );
  }
}

class Cheese {
  final String name;
  final String link;
  final String imageURL;
  final CheeseAttributes attributes;
  final String description;
  final List<dynamic> countryCodes;
  final List<dynamic> milks;

  Cheese({
    required this.name,
    required this.link,
    required this.imageURL,
    required this.attributes,
    required this.description,
    required this.countryCodes,
    required this.milks,
  });

  factory Cheese.fromJson(Map<String, dynamic> json) {
    String name = json['name'];
    String link = json['link'];
    String image = json['image'];
    String desc = json['description'];
    List<dynamic> countryCodes = json['country_codes'];
    List<dynamic> milks = json['milks'];
    CheeseAttributes attributes = CheeseAttributes.fromJson(json['attributes']);

    return Cheese(
      name: name,
      link: link,
      imageURL: image,
      attributes: attributes,
      description: desc,
      countryCodes: countryCodes,
      milks: milks,
    );
  }
}

class CheeseDetails extends StatelessWidget {
  final Cheese cheese;
  const CheeseDetails(this.cheese, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(cheese.name),
      ),
      body: SizedBox(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: 270,
                child: FutureBuilder<http.Response>(
                    future: http.get(Uri.parse(cheese.imageURL)),
                    builder: (context, snapshot) {
                      switch (snapshot.connectionState) {
                        case ConnectionState.none:
                          return const SizedBox(height: 270);
                        case ConnectionState.active:
                        case ConnectionState.waiting:
                          return const Center(
                              child: CircularProgressIndicator());
                        case ConnectionState.done:
                          if (snapshot.hasError) {
                            return const Icon(Icons.broken_image, size: 200);
                          }
                          final contentType =
                              snapshot.requireData.headers['content-type'];
                          if (contentType != null &&
                              contentType.contains('svg')) {
                            return ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxHeight: 270),
                                child: Image(
                                    image:
                                        const Svg('assets/cheese-default.svg'),
                                    width: MediaQuery.of(context).size.width,
                                    fit: BoxFit.fitWidth));
                          }
                          return ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 270),
                              child: Image.memory(
                                  snapshot.requireData.bodyBytes,
                                  width: MediaQuery.of(context).size.width,
                                  fit: BoxFit.fitWidth));
                      }
                    }),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                margin: const EdgeInsets.symmetric(vertical: 24),
                child: Wrap(
                  runSpacing: 20,
                  children: [
                    Wrap(
                      runSpacing: 15,
                      children: [
                        if (cheese.attributes.made != null)
                          Row(children: [
                            const Icon(Icons.science),
                            const SizedBox(width: 10),
                            Flexible(child: Text(cheese.attributes.made!))
                          ]),
                        if (cheese.attributes.countries.isNotEmpty)
                          Row(children: [
                            const Icon(Icons.flag),
                            const SizedBox(width: 10),
                            Flexible(
                              child: RichText(
                                text: TextSpan(
                                  text: "Countries: ",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black),
                                  children: [
                                    TextSpan(
                                      text: cheese.attributes.countries
                                          .join(', '),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.normal),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ]),
                        if (cheese.attributes.region != null)
                          Row(children: [
                            const Icon(Icons.public),
                            const SizedBox(width: 10),
                            Flexible(
                              child: RichText(
                                text: TextSpan(
                                  text: "Region: ",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black),
                                  children: [
                                    TextSpan(
                                      text: cheese.attributes.region!,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.normal),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ]),
                        if (cheese.attributes.family != null)
                          Row(children: [
                            const Icon(Icons.emoji_people),
                            const SizedBox(width: 10),
                            Flexible(
                              child: RichText(
                                text: TextSpan(
                                  text: "Family: ",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black),
                                  children: [
                                    TextSpan(
                                      text: cheese.attributes.family!,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.normal),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ]),
                        if (cheese.attributes.types.isNotEmpty)
                          Row(children: [
                            const Icon(Icons.category),
                            const SizedBox(width: 10),
                            Flexible(
                              child: RichText(
                                text: TextSpan(
                                  text: "Types: ",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black),
                                  children: [
                                    TextSpan(
                                      text: cheese.attributes.types.join(', '),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.normal),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ]),
                        if (cheese.attributes.fat != null)
                          Row(children: [
                            const Icon(Icons.tune),
                            const SizedBox(width: 10),
                            Flexible(
                              child: RichText(
                                text: TextSpan(
                                  text: "Fat: ",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black),
                                  children: [
                                    TextSpan(
                                      text: cheese.attributes.fat!,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.normal),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ]),
                        if (cheese.attributes.calcium != null)
                          Row(children: [
                            const Icon(Icons.colorize),
                            const SizedBox(width: 10),
                            Flexible(
                              child: RichText(
                                text: TextSpan(
                                  text: "Calcium: ",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black),
                                  children: [
                                    TextSpan(
                                      text: cheese.attributes.calcium!,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.normal),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ]),
                        if (cheese.attributes.textures.isNotEmpty)
                          Row(children: [
                            const Icon(Icons.pie_chart),
                            const SizedBox(width: 10),
                            Flexible(
                              child: RichText(
                                text: TextSpan(
                                  text: "Textures: ",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black),
                                  children: [
                                    TextSpan(
                                      text:
                                          cheese.attributes.textures.join(', '),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.normal),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ]),
                        if (cheese.attributes.rind != null)
                          Row(children: [
                            const Icon(Icons.brush),
                            const SizedBox(width: 10),
                            Flexible(
                              child: RichText(
                                text: TextSpan(
                                  text: "Rind: ",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black),
                                  children: [
                                    TextSpan(
                                      text: cheese.attributes.rind!,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.normal),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ]),
                        if (cheese.attributes.color != null)
                          Row(children: [
                            const Icon(Icons.water_drop),
                            const SizedBox(width: 10),
                            Flexible(
                              child: RichText(
                                text: TextSpan(
                                  text: "Color: ",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black),
                                  children: [
                                    TextSpan(
                                      text: cheese.attributes.color!,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.normal),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ]),
                        if (cheese.attributes.flavors.isNotEmpty)
                          Row(children: [
                            const Icon(Icons.local_dining),
                            const SizedBox(width: 10),
                            Flexible(
                              child: RichText(
                                text: TextSpan(
                                  text: "Flavors: ",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black),
                                  children: [
                                    TextSpan(
                                      text:
                                          cheese.attributes.flavors.join(', '),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.normal),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ]),
                        if (cheese.attributes.aromas.isNotEmpty)
                          Row(children: [
                            const Icon(Icons.restaurant),
                            const SizedBox(width: 10),
                            Flexible(
                              child: RichText(
                                text: TextSpan(
                                  text: "Aromas: ",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black),
                                  children: [
                                    TextSpan(
                                      text: cheese.attributes.aromas.join(', '),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.normal),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ]),
                        if (cheese.attributes.vegetarian != null)
                          Row(children: [
                            const Icon(Icons.local_florist),
                            const SizedBox(width: 10),
                            Flexible(
                              child: RichText(
                                text: TextSpan(
                                  text: "Vegetarian: ",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black),
                                  children: [
                                    TextSpan(
                                      text: cheese.attributes.vegetarian!
                                          ? 'Yes'
                                          : 'No',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.normal),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ]),
                        if (cheese.attributes.producers.isNotEmpty)
                          Row(children: [
                            const Icon(Icons.factory),
                            const SizedBox(width: 10),
                            Flexible(
                              child: RichText(
                                text: TextSpan(
                                  text: "Producers: ",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black),
                                  children: [
                                    TextSpan(
                                      text: cheese.attributes.producers
                                          .join(', '),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.normal),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ]),
                        if (cheese.attributes.synonyms.isNotEmpty)
                          Row(children: [
                            const Icon(Icons.translate),
                            const SizedBox(width: 10),
                            Flexible(
                              child: RichText(
                                text: TextSpan(
                                  text: "Synoynms: ",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black),
                                  children: [
                                    TextSpan(
                                      text:
                                          cheese.attributes.synonyms.join(', '),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.normal),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ]),
                        if (cheese.attributes.alternativeSpellings.isNotEmpty)
                          Row(children: [
                            const Icon(Icons.subtitles),
                            const SizedBox(width: 10),
                            Flexible(
                              child: RichText(
                                text: TextSpan(
                                  text: "Alternative Spellings: ",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black),
                                  children: [
                                    TextSpan(
                                      text: cheese
                                          .attributes.alternativeSpellings
                                          .join(', '),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.normal),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          ]),
                      ],
                    ),
                    Text(cheese.description,
                        style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
