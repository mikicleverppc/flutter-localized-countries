library flutter_localized_countries;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

// Base class for country and locale names
class _BaseNames {
  final String locale;
  final Map<String, String> data;
  _BaseNames(this.locale, this.data);

  String nameOf(String code) => data[code];

  List<MapEntry<String, String>> get sortedByCode {
    return data.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
  }

  List<MapEntry<String, String>> get sortedByName {
    return data.entries.toList()..sort((a, b) => a.value.compareTo(b.value));
  }

  toString() => locale;
}

class CountryNames extends _BaseNames {
  CountryNames(String locale, Map<String, String> data) : super(locale, data);

  static CountryNames of(BuildContext context) {
    return Localizations.of<CountryNames>(context, CountryNames);
  }
}

class LocaleNames extends _BaseNames {
  LocaleNames(String locale, Map<String, String> data) : super(locale, data);

  static LocaleNames of(BuildContext context) {
    return Localizations.of<LocaleNames>(context, LocaleNames);
  }
}

abstract class _BaseNamesLocalizationsDelegate<T> extends LocalizationsDelegate<T> {
  final AssetBundle bundle;
  final dataPath;
  const _BaseNamesLocalizationsDelegate({this.bundle, this.dataPath});

  Future<List<String>> codes() async {
    return List<String>.from(await _loadJSON('$dataPath/_codes.json') as List<dynamic>);
  }

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<T> load(Locale locale) async {
    var codes = Set<String>.from(await this.codes());

    var availableLocale = _getAvailableLocale(locale, codes, 'en');
    if (availableLocale == null) {
      return null;
    }

    final data = Map<String, String>.from(
        await _loadJSON('$dataPath/$availableLocale.json') as Map<dynamic, dynamic>);
    switch (T) {
      case CountryNames:
        return CountryNames(availableLocale, data) as T;
      case LocaleNames:
      default:
        return LocaleNames(availableLocale, data) as T;
    }
  }

  @override
  bool shouldReload(LocalizationsDelegate<T> old) {
    return false;
  }

  String _getAvailableLocale(Locale locale, Set<String> codes, [String fallbackLocale]) {
    final String name = locale.countryCode == null ? locale.languageCode : locale.toString();
    final String canonicalLocale = Intl.canonicalizedLocale(name);

    return Intl.verifiedLocale(
      canonicalLocale,
      (locale) => codes.contains(locale),
      onFailure: (_) => fallbackLocale,
    );
  }

  // Fix found here: https://github.com/flutter/flutter/issues/44182
  Future<dynamic> _loadJSON(key) async {
    ByteData data = await rootBundle.load('packages/flutter_localized_countries/' + key);
    String jsonContent = utf8.decode(data.buffer.asUint8List());
    return json.decode(jsonContent);
  }
}

class CountryNamesLocalizationsDelegate extends _BaseNamesLocalizationsDelegate<CountryNames> {
  const CountryNamesLocalizationsDelegate({AssetBundle bundle})
      : super(bundle: bundle, dataPath: 'data/countries');
}

class LocaleNamesLocalizationsDelegate extends _BaseNamesLocalizationsDelegate<LocaleNames> {
  const LocaleNamesLocalizationsDelegate({AssetBundle bundle})
      : super(bundle: bundle, dataPath: 'data/locales');

  /// Returns a [Map] of locale codes to their native locale name.
  Future<Map<String, String>> getLocaleNativeNames() async {
    return Map<String, String>.from(
      await _loadJSON('data/locales/_locales_native_names.json'),
    );
  }
}
