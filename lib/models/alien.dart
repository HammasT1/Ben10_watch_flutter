import 'package:flutter/material.dart';

/// Ratings shown as bars on the info card, each 1..10.
class AlienStats {
  const AlienStats({
    required this.strength,
    required this.speed,
    required this.intelligence,
    required this.durability,
  });

  final int strength;
  final int speed;
  final int intelligence;
  final int durability;

  Map<String, int> get asMap => {
    'STRENGTH': strength,
    'SPEED': speed,
    'INTELLIGENCE': intelligence,
    'DURABILITY': durability,
  };
}

class Alien {
  const Alien({
    required this.name,
    required this.species,
    required this.homeworld,
    required this.description,
    required this.powers,
    required this.color,
    required this.stats,
    required this.image,
  });

  final String name;
  final String species;
  final String homeworld;
  final String description;
  final List<String> powers;

  /// Theme color: tints the rings, sparks, flash and transformed view.
  final Color color;
  final AlienStats stats;

  /// Asset path of the alien's silhouette image.
  final String image;
}
