import 'package:flutter/material.dart';

import '../models/alien.dart';

/// The aliens on the dial, in slot order (slot N uses `assets/images/N.png`).
///
/// Edit freely: names, text, colors and stats are all read from here.
/// Entries marked "UNCONFIRMED" were identified from the silhouette only.
const List<Alien> aliens = [
  Alien(
    name: 'XLR8',
    species: 'Kineceleran',
    homeworld: 'Kinet',
    description:
        'A raptor-like speedster who can run faster than sound and react '
        'before most opponents finish blinking.',
    powers: ['Super speed', 'Enhanced reflexes', 'Wall running', 'Cyclones'],
    color: Color(0xFF3BA8FF),
    stats: AlienStats(strength: 4, speed: 10, intelligence: 5, durability: 4),
    image: 'assets/images/1.png',
  ),
  Alien(
    name: 'Wildvine',
    species: 'Florauna',
    homeworld: 'Flors Verdance',
    description:
        'A walking plant that can stretch, root itself into the ground and '
        'regrow from almost any damage.',
    powers: ['Elasticity', 'Regeneration', 'Explosive seeds', 'Burrowing'],
    color: Color(0xFF7BE35A),
    stats: AlienStats(strength: 5, speed: 4, intelligence: 4, durability: 7),
    image: 'assets/images/2.png',
  ),
  Alien(
    name: 'Stinkfly',
    species: 'Lepidopterran',
    homeworld: 'Lepidopterra',
    description:
        'An insectoid flyer that sprays sticky goo and noxious gas from '
        'above while staying out of reach.',
    powers: ['Flight', 'Slime spray', 'Toxic gas', '360° vision'],
    color: Color(0xFFC8E83A),
    stats: AlienStats(strength: 3, speed: 7, intelligence: 4, durability: 3),
    image: 'assets/images/3.png',
  ),
  Alien(
    // UNCONFIRMED: identified from the silhouette only.
    name: 'Heatblast',
    species: 'Pyronite',
    homeworld: 'Pyros',
    description:
        'A living star-fire being made of burning rock who throws fireballs '
        'and can surf on columns of flame.',
    powers: ['Pyrokinesis', 'Flame flight', 'Heat immunity', 'Fireballs'],
    color: Color(0xFFFF7A1A),
    stats: AlienStats(strength: 6, speed: 5, intelligence: 5, durability: 6),
    image: 'assets/images/4.png',
  ),
  Alien(
    name: 'Wildmutt',
    species: 'Vulpimancer',
    homeworld: 'Vulpin',
    description:
        'An eyeless beast that senses the world through smell and hearing, '
        'with the agility to pounce on anything.',
    powers: ['Enhanced senses', 'Agility', 'Quill launch', 'Wall climbing'],
    color: Color(0xFFFF9F43),
    stats: AlienStats(strength: 6, speed: 7, intelligence: 3, durability: 5),
    image: 'assets/images/5.png',
  ),
  Alien(
    // UNCONFIRMED: identified from the silhouette only.
    name: 'Diamondhead',
    species: 'Petrosapien',
    homeworld: 'Petropia',
    description:
        'A crystal warrior who grows blades, shields and spikes from his '
        'own body and reflects energy attacks.',
    powers: ['Crystal growth', 'Energy reflection', 'Toughness', 'Shards'],
    color: Color(0xFF3FF3D6),
    stats: AlienStats(strength: 7, speed: 4, intelligence: 6, durability: 9),
    image: 'assets/images/6.png',
  ),
  Alien(
    // UNCONFIRMED: identified from the silhouette only.
    name: 'Upchuck',
    species: 'Gourmand',
    homeworld: 'Peptos XI',
    description:
        'Small but endlessly hungry: eats almost anything and spits it back '
        'out as explosive energy blasts.',
    powers: ['Matter digestion', 'Energy spit', 'Long tongues', 'Iron gut'],
    color: Color(0xFF9BE15D),
    stats: AlienStats(strength: 4, speed: 3, intelligence: 4, durability: 6),
    image: 'assets/images/7.png',
  ),
  Alien(
    // UNCONFIRMED: identified from the silhouette only.
    name: 'Upgrade',
    species: 'Galvanic Mechamorph',
    homeworld: 'Galvan B',
    description:
        'Living technology that merges with machines and upgrades them into '
        'far more powerful versions.',
    powers: ['Tech merging', 'Shapeshifting', 'Optic blasts', 'Hacking'],
    color: Color(0xFF39FF14),
    stats: AlienStats(strength: 4, speed: 5, intelligence: 9, durability: 5),
    image: 'assets/images/8.png',
  ),
  Alien(
    // UNCONFIRMED: identified from the silhouette only.
    name: 'Benwolf',
    species: 'Loboan',
    homeworld: 'Anur Transyl',
    description:
        'A werewolf-like hunter with a sonic howl that can shatter stone '
        'and senses sharp enough to track anything.',
    powers: ['Sonic howl', 'Night vision', 'Claws', 'Enhanced smell'],
    color: Color(0xFFB0C4DE),
    stats: AlienStats(strength: 7, speed: 6, intelligence: 4, durability: 6),
    image: 'assets/images/9.png',
  ),
  Alien(
    // UNCONFIRMED: identified from the silhouette only.
    name: 'Cannonbolt',
    species: 'Arburian Pelarota',
    homeworld: 'Arburia',
    description:
        'Curls into an armored ball and rolls like a wrecking ball, '
        'ricocheting off walls at high speed.',
    powers: ['Armored ball form', 'Ricochet', 'Toughness', 'Momentum'],
    color: Color(0xFFFFD34D),
    stats: AlienStats(strength: 7, speed: 7, intelligence: 3, durability: 9),
    image: 'assets/images/10.png',
  ),
  Alien(
    name: 'Four Arms',
    species: 'Tetramand',
    homeworld: 'Khoros',
    description:
        'A towering four-armed powerhouse who can lift huge weights and '
        'create shockwaves by clapping.',
    powers: ['Super strength', 'Shockwave clap', 'Leaping', 'Four arms'],
    color: Color(0xFFFF4D4D),
    stats: AlienStats(strength: 10, speed: 4, intelligence: 4, durability: 8),
    image: 'assets/images/11.png',
  ),
];
