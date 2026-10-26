import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/widgets.dart';

/// Footprint Guard iconography.
/// Feather Icons — premium thin-stroke line icons only.
/// STRICT RULE: no emojis anywhere in this application.
class FGI {
  static const IconData shield = FeatherIcons.shield;
  static const IconData shieldOff = FeatherIcons.shieldOff;
  static const IconData mail = FeatherIcons.mail;
  static const IconData atSign = FeatherIcons.atSign;
  static const IconData user = FeatherIcons.user;
  static const IconData users = FeatherIcons.users;
  static const IconData phone = FeatherIcons.phone;
  static const IconData smartphone = FeatherIcons.smartphone;
  static const IconData key = FeatherIcons.key;
  static const IconData lock = FeatherIcons.lock;
  static const IconData unlock = FeatherIcons.unlock;
  static const IconData eye = FeatherIcons.eye;
  static const IconData eyeOff = FeatherIcons.eyeOff;
  static const IconData globe = FeatherIcons.globe;
  static const IconData clock = FeatherIcons.clock;
  static const IconData calendar = FeatherIcons.calendar;
  static const IconData fileText = FeatherIcons.fileText;
  static const IconData download = FeatherIcons.download;
  static const IconData printer = FeatherIcons.printer;
  static const IconData search = FeatherIcons.search;
  static const IconData activity = FeatherIcons.activity;
  static const IconData alertTriangle = FeatherIcons.alertTriangle;
  static const IconData alertCircle = FeatherIcons.alertCircle;
  static const IconData checkCircle = FeatherIcons.checkCircle;
  static const IconData xCircle = FeatherIcons.xCircle;
  static const IconData info = FeatherIcons.info;
  static const IconData mapPin = FeatherIcons.mapPin;
  static const IconData creditCard = FeatherIcons.creditCard;
  static const IconData hash = FeatherIcons.hash;
  static const IconData database = FeatherIcons.database;
  static const IconData server = FeatherIcons.server;
  static const IconData wifi = FeatherIcons.wifi;
  static const IconData refresh = FeatherIcons.refreshCw;
  static const IconData copy = FeatherIcons.copy;
  static const IconData share = FeatherIcons.share2;
  static const IconData chevronRight = FeatherIcons.chevronRight;
  static const IconData chevronDown = FeatherIcons.chevronDown;
  static const IconData sliders = FeatherIcons.sliders;
  static const IconData zap = FeatherIcons.zap;
  static const IconData target = FeatherIcons.target;
  static const IconData crosshair = FeatherIcons.crosshair;
  static const IconData layers = FeatherIcons.layers;
  static const IconData list = FeatherIcons.list;
  static const IconData grid = FeatherIcons.grid;
  static const IconData help = FeatherIcons.helpCircle;
  static const IconData x = FeatherIcons.x;
  static const IconData check = FeatherIcons.check;
  static const IconData trendingUp = FeatherIcons.trendingUp;
  static const IconData external = FeatherIcons.externalLink;

  /// Monochromatic icon per leaked data class (warning colour applied by UI).
  static IconData forDataClass(String dataClass) {
    switch (dataClass) {
      case 'Passwords':
      case 'Password hints':
        return key;
      case 'Email addresses':
        return mail;
      case 'Phone numbers':
        return phone;
      case 'IP addresses':
        return wifi;
      case 'Physical addresses':
        return mapPin;
      case 'Dates of birth':
        return calendar;
      case 'Credit cards':
      case 'Bank account numbers':
        return creditCard;
      case 'Social security numbers':
      case 'Government issued IDs':
      case 'Passport numbers':
        return hash;
      case 'Security questions and answers':
        return help;
      case 'Names':
        return user;
      case 'Usernames':
        return atSign;
      case 'Geographic locations':
        return globe;
      case 'Social media profiles':
        return users;
      default:
        return database;
    }
  }

  /// Icon per platform category.
  static IconData forCategory(String category) {
    switch (category) {
      case 'dev':
        return FeatherIcons.code;
      case 'social':
        return users;
      case 'media':
        return FeatherIcons.playCircle;
      case 'gaming':
        return target;
      case 'creative':
        return FeatherIcons.camera;
      case 'writing':
        return FeatherIcons.edit3;
      case 'creator':
        return zap;
      default:
        return globe;
    }
  }

  /// Icon per remediation rule key.
  static IconData forKey(String keyName) {
    switch (keyName) {
      case 'key':
        return key;
      case 'refresh':
        return refresh;
      case 'creditCard':
        return creditCard;
      case 'shield':
        return shield;
      case 'smartphone':
        return smartphone;
      case 'help':
        return help;
      case 'phone':
        return phone;
      case 'eyeOff':
        return eyeOff;
      case 'eye':
        return eye;
      case 'mapPin':
        return mapPin;
      case 'checkCircle':
        return checkCircle;
      default:
        return activity;
    }
  }
}
