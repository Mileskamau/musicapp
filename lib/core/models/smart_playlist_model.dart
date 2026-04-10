import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import 'song_model.dart';

part 'smart_playlist_model.g.dart';

enum SmartRuleField {
  artist,
  album,
  genre,
  year,
  playCount,
  lastPlayed,
  rating,
  title,
}

enum SmartRuleOperator {
  equals,
  notEquals,
  contains,
  notContains,
  greaterThan,
  lessThan,
  greaterThanOrEqual,
  lessThanOrEqual,
}

enum SmartRuleLogic {
  and,
  or,
}

@HiveType(typeId: 6)
class SmartRule extends Equatable {
  @HiveField(0)
  final int fieldIndex;
  
  @HiveField(1)
  final int operatorIndex;
  
  @HiveField(2)
  final String value;

  SmartRule({
    required this.fieldIndex,
    required this.operatorIndex,
    required this.value,
  });

  SmartRuleField get field => SmartRuleField.values[fieldIndex];
  SmartRuleOperator get operator => SmartRuleOperator.values[operatorIndex];

  bool evaluate(SongModel song) {
    final songValue = _getSongValue(song);
    return _evaluateCondition(songValue);
  }

  String _getSongValue(SongModel song) {
    switch (field) {
      case SmartRuleField.artist:
        return song.artist.toLowerCase();
      case SmartRuleField.album:
        return song.album.toLowerCase();
      case SmartRuleField.genre:
        return (song.genre ?? '').toLowerCase();
      case SmartRuleField.year:
        return song.year.toString();
      case SmartRuleField.playCount:
        return song.playCount.toString();
      case SmartRuleField.lastPlayed:
        return song.lastPlayed.toString();
      case SmartRuleField.rating:
        return '0';
      case SmartRuleField.title:
        return song.title.toLowerCase();
    }
  }

  bool _evaluateCondition(String songValue) {
    final ruleValue = value.toLowerCase();

    switch (operator) {
      case SmartRuleOperator.equals:
        return songValue == ruleValue;
      case SmartRuleOperator.notEquals:
        return songValue != ruleValue;
      case SmartRuleOperator.contains:
        return songValue.contains(ruleValue);
      case SmartRuleOperator.notContains:
        return !songValue.contains(ruleValue);
      case SmartRuleOperator.greaterThan:
        return _compareNumeric(songValue, ruleValue) > 0;
      case SmartRuleOperator.lessThan:
        return _compareNumeric(songValue, ruleValue) < 0;
      case SmartRuleOperator.greaterThanOrEqual:
        return _compareNumeric(songValue, ruleValue) >= 0;
      case SmartRuleOperator.lessThanOrEqual:
        return _compareNumeric(songValue, ruleValue) <= 0;
    }
  }

  int _compareNumeric(String a, String b) {
    final aNum = int.tryParse(a) ?? 0;
    final bNum = int.tryParse(b) ?? 0;
    return aNum.compareTo(bNum);
  }

  Map<String, dynamic> toJson() => {
    'fieldIndex': fieldIndex,
    'operatorIndex': operatorIndex,
    'value': value,
  };

  factory SmartRule.fromJson(Map<String, dynamic> json) => SmartRule(
    fieldIndex: json['fieldIndex'] as int,
    operatorIndex: json['operatorIndex'] as int,
    value: json['value'] as String,
  );

  @override
  List<Object?> get props => [fieldIndex, operatorIndex, value];
}

@HiveType(typeId: 7)
class SmartPlaylistRule extends Equatable {
  @HiveField(0)
  final List<Map<String, dynamic>> rules;
  
  @HiveField(1)
  final int logicIndex;

  SmartPlaylistRule({
    required this.rules,
    this.logicIndex = 0,
  });

  SmartRuleLogic get logic => SmartRuleLogic.values[logicIndex];

  List<SmartRule> get parsedRules => rules.map((r) => SmartRule.fromJson(r)).toList();

  List<SongModel> filterSongs(List<SongModel> allSongs) {
    if (rules.isEmpty) return allSongs;

    final parsed = parsedRules;

    return allSongs.where((song) {
      if (logic == SmartRuleLogic.and) {
        return parsed.every((rule) => rule.evaluate(song));
      } else {
        return parsed.any((rule) => rule.evaluate(song));
      }
    }).toList();
  }

  @override
  List<Object?> get props => [rules, logicIndex];
}