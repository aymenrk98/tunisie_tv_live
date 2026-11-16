import 'package:flutter/material.dart';

enum ChannelCategory { publique, info, sport, divertissement }

extension ChannelCategoryLabel on ChannelCategory {
  String get label {
    switch (this) {
      case ChannelCategory.publique:
        return 'Publiques';
      case ChannelCategory.info:
        return 'Info';
      case ChannelCategory.sport:
        return 'Sport';
      case ChannelCategory.divertissement:
        return 'Divertissement';
    }
  }
}

class Channel {
  final String id;
  final String name;
  final String slug;
  final ChannelCategory category;
  final String logo;
  final List<Color> colors;
  final String? logoAsset;

  const Channel({
    required this.id,
    required this.name,
    required this.slug,
    required this.category,
    required this.logo,
    required this.colors,
    this.logoAsset,
  });

  String get embedUrl => 'https://www.elahmad.ru/tv/mobiletv/glarb.php?id=$slug';
}
