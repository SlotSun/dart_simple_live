import "dart:io";

import "package:path/path.dart" as p;

/// Setting item annotation. `defaultValue` is required, `key` is optional and
/// falls back to a key generated from the field name.
///
/// ```dart
/// @SettingItem(defaultValue: true, key: LocalStorageService.kHardwareDecode)
/// var hardwareDecode = true.obs;
///
/// @SettingItem(defaultValue: 2)          // -> kQualityLevel = "QualityLevel"
/// var qualityLevel = 1.obs;
///
/// @SettingItem(defaultValue: null)
/// FollowSnapshot? followSnapshot;
/// ```
class SettingItem {
  /// Storage key as source expression; a known `LocalStorageService.kXxx` is
  /// resolved to its literal value in the generated constant, so the constant
  /// can be dropped later. Generated from the field name when omitted.
  final String? key;

  /// Default value, may be null.
  final Object? defaultValue;

  const SettingItem({this.key, required this.defaultValue});
}

/// A scanned setting item. [key] is the generated constant name used by the
/// setter/getter, [keySource] is that constant's value, [rx] tells whether the
/// field is an Rx field (uses `.value`).
typedef SettingGenItem = ({
  String name,
  String type,
  String key,
  String keySource,
  String defaultValue,
  bool rx,
});

/// Reads `@SettingItem` from a source file and writes setters/getters and the
/// storage keys into the part file declared by `part 'xxx.g.dart';`.
class SettingGenUtil {
  /// One item. Placeholders: `{name}`, `{Name}`, `{type}`, `{key}`,
  /// `{defaultValue}`, `{target}` (Rx `.value` or the plain field) and `{read}`
  /// (`getValue`, or `getNullValue` for a null default where `getValue` would
  /// infer `T = Null`).
  static const String itemTemplate = """  void set{Name}({type} e) {
    {target} = e;
    LocalStorageService.instance.setValue({key}, e);
  }

  void get{Name}() {
    {target} = LocalStorageService.instance.{read};
  }
""";

  /// The `.g.dart` file. Placeholders: `{source}`, `{className}`, `{members}`,
  /// `{keys}` (constants appended at the end).
  static const String partTemplate = """// GENERATED CODE - DO NOT MODIFY BY HAND
part of "{source}";

extension {className}SettingGen on {className} {
{members}
}
{keys}""";

  /// `@SettingItem(defaultValue: ..., key: ...)`
  static final RegExp _annotationPattern = RegExp(r"@SettingItem\(\s*([^)]*)\)");

  /// Field declaration below the annotation. group(1): declared type (null for
  /// `var`/`final`), group(2): field name, group(3): initializer.
  static final RegExp _fieldPattern =
      RegExp(r"^\s*(?:late\s+)?(?:var|final|([\w<>,?\s]+?))\s+([A-Za-z_]\w*)\s*(?:=\s*([^;]*?))?\s*;");

  /// `part "xxx.g.dart";`
  static final RegExp _partPattern = RegExp("part\\s+['\"]([^'\"]+\\.g\\.dart)['\"]\\s*;");

  /// First `class` in the source file.
  static final RegExp _classPattern = RegExp(r"class\s+([A-Za-z_]\w*)");

  /// Relative path from `part "xxx.g.dart";`, or null.
  static String? findPartPath(String source) => _partPattern.firstMatch(source)?.group(1);

  /// Storage key constants of a `local_storage_service.dart`:
  /// `kScaleMode` -> `ScaleMode`.
  static Map<String, String> parseStorageKeys(File constantsFile) {
    if (!constantsFile.existsSync()) return const {};
    final source = constantsFile.readAsStringSync();
    final pattern = RegExp("static const String (k\\w+)\\s*=\\s*[\"']([^\"']*)[\"']\\s*;");
    return {for (final match in pattern.allMatches(source)) match.group(1)!: match.group(2)!};
  }

  /// [parseStorageKeys] of the `lib/services/local_storage_service.dart` above
  /// [sourceFile], or an empty map.
  static Map<String, String> findStorageKeys(File sourceFile) {
    var directory = sourceFile.parent;
    while (true) {
      final keys = parseStorageKeys(
        File(p.join(directory.path, "lib", "services", "local_storage_service.dart")),
      );
      if (keys.isNotEmpty) return keys;
      final parent = directory.parent;
      if (parent.path == directory.path) return const {};
      directory = parent;
    }
  }

  /// Scans the annotations and the field declaration below each one.
  static List<SettingGenItem> scan(String source, {Map<String, String> storageKeys = const {}}) {
    final items = <SettingGenItem>[];
    for (final match in _annotationPattern.allMatches(source)) {
      final field = _fieldPattern.firstMatch(source.substring(match.end));
      if (field == null) continue;
      String? key;
      String? defaultValue;
      for (final arg in _splitArgs(match.group(1)!)) {
        if (arg.startsWith("key:")) {
          key = arg.substring("key:".length).trim();
        } else if (arg.startsWith("defaultValue:")) {
          defaultValue = arg.substring("defaultValue:".length).trim();
        } else {
          defaultValue ??= arg; // positional form
        }
      }
      if (defaultValue == null) continue;
      final name = field.group(2)!;
      final declared = field.group(1);
      final initializer = field.group(3);
      items.add((
        name: name,
        type: defaultValue == "null" ? nullableTypeOf(declared) : typeOf(defaultValue),
        key: keyName(name),
        keySource: _keySource(key, name, storageKeys),
        defaultValue: defaultValue,
        rx: (declared != null && declared.contains("Rx")) || (initializer?.contains(".obs") ?? false),
      ));
    }
    return items;
  }

  /// Constant name for a field: `hardwareDecode` -> `kHardwareDecode`.
  static String keyName(String name) => "k${upperFirst(name)}";

  /// Value of the generated key constant: the literal behind a known
  /// `LocalStorageService.kXxx`, otherwise the expression itself, otherwise
  /// `"FieldName"`.
  static String _keySource(String? key, String name, Map<String, String> storageKeys) {
    if (key == null) return '"${keyValue(name)}"';
    final match = RegExp(r"^LocalStorageService\.(\w+)$").firstMatch(key);
    final value = match == null ? null : storageKeys[match.group(1)];
    return value == null ? key : '"$value"';
  }

  /// Stored value when `key` is omitted: `hardwareDecode` -> "HardwareDecode".
  static String keyValue(String name) => upperFirst(name);

  /// Type inferred from the default value source.
  static String typeOf(String defaultValue) {
    final value = defaultValue.trim();
    if (value == "true" || value == "false") return "bool";
    if (RegExp(r"^-?\d+$").hasMatch(value)) return "int";
    if (RegExp(r"^-?\d+\.\d+$").hasMatch(value)) return "double";
    if (RegExp(r"^-?\d+(\.\d+)?\s*/\s*-?\d+(\.\d+)?$").hasMatch(value)) return "double"; // 16 / 9
    if (value.startsWith("\"") || value.startsWith("'")) return "String";
    return "dynamic";
  }

  /// Type for a null default: the declared field type (e.g. `FollowSnapshot?`),
  /// or `dynamic`.
  static String nullableTypeOf(String? declared) => declared == null ? "dynamic" : declared.trim();

  /// Renders one setting item.
  static String generateItem(SettingGenItem item) {
    final target = item.rx ? "${item.name}.value" : item.name;
    final read =
        item.defaultValue == "null" ? "getNullValue(${item.key}, null)" : "getValue(${item.key}, ${item.defaultValue})";
    return itemTemplate
        .replaceAll("{target}", target)
        .replaceAll("{read}", read)
        .replaceAll("{name}", item.name)
        .replaceAll("{Name}", upperFirst(item.name))
        .replaceAll("{type}", item.type)
        .replaceAll("{key}", item.key)
        .replaceAll("{defaultValue}", item.defaultValue);
  }

  /// Renders the whole `.g.dart` content: the extension plus one storage key
  /// constant per item.
  static String generatePartContent({
    required String source,
    required String className,
    required List<SettingGenItem> items,
  }) {
    final keys = items.map((e) => 'const String ${e.key} = ${e.keySource};').join("\n");
    return partTemplate
        .replaceAll("{source}", source)
        .replaceAll("{className}", className)
        .replaceAll("{members}", items.map((e) => generateItem(e).trimRight()).join("\n\n"))
        .replaceAll("{keys}", keys.isEmpty ? "" : "\n// storage keys\n$keys\n");
  }

  /// Writes the generated code into the part file declared by [sourceFile].
  static File generateForFile(File sourceFile) {
    final source = sourceFile.readAsStringSync();
    final partPath = findPartPath(source);
    if (partPath == null) {
      throw StateError("${sourceFile.path} has no part \"xxx.g.dart\";");
    }
    final className = _classPattern.firstMatch(source)?.group(1);
    if (className == null) {
      throw StateError("${sourceFile.path} has no class to attach the extension to");
    }
    final content = generatePartContent(
      source: p.basename(sourceFile.path),
      className: className,
      items: scan(source, storageKeys: findStorageKeys(sourceFile)),
    );
    final target = File(p.join(sourceFile.parent.path, partPath));
    target.writeAsStringSync(content);
    return target;
  }

  /// Splits annotation arguments on commas.
  static List<String> _splitArgs(String args) =>
      args.split(",").map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  /// Uppercases the first character.
  static String upperFirst(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}
