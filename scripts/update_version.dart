// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

/// 读取 CHANGELOG.md，同步更新 app_version.json 和 metainfo.xml。
///
/// 用法:
///   dart run scripts/update_version.dart                     # 更新 version_desc + metainfo
///   dart run scripts/update_version.dart --version 1.8.13   # 同时更新 version 和 version_num
void main(List<String> args) {
  final projectRoot = _findProjectRoot();
  final changelogFile = File('$projectRoot/CHANGELOG.md');
  final versionFile = File('$projectRoot/assets/app_version.json');
  final metainfoFile = File(
    '$projectRoot/simple_live_app/assets/io.github.SlotSun.Slive.metainfo.xml',
  );

  if (!changelogFile.existsSync()) {
    stderr.writeln('❌ CHANGELOG.md 不存在');
    exit(2);
  }

  // 解析参数
  String? targetVersion;
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--version' && i + 1 < args.length) {
      targetVersion = args[i + 1];
    }
  }

  // 解析 CHANGELOG
  final entries = _parseChangelog(changelogFile.readAsStringSync());
  if (entries.isEmpty) {
    stderr.writeln('❌ CHANGELOG.md 中未找到任何版本条目 (格式: ## x.x.x)');
    exit(1);
  }

  final version = targetVersion ?? entries.keys.first;
  final changes = entries[version];
  if (changes == null || changes.isEmpty) {
    stderr.writeln('❌ 版本 $version 在 CHANGELOG.md 中无条目或条目为空');
    exit(1);
  }

  // --- 更新 app_version.json ---
  _updateVersionJson(versionFile, version, changes, targetVersion != null);

  // --- 更新 metainfo.xml ---
  _updateMetainfo(metainfoFile, entries);

  print('');
  print('✅ 全部更新完成');
}

// ─── app_version.json ───────────────────────────────────────────────────────────

void _updateVersionJson(
  File file,
  String version,
  List<String> changes,
  bool updateVersion,
) {
  if (!file.existsSync()) {
    stderr.writeln('⚠️  跳过 app_version.json: 文件不存在');
    return;
  }

  final versionDesc = changes.map((e) => '- $e').join(' \n');
  final json =
      jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

  if (updateVersion) {
    json['version'] = version;
    json['version_num'] = _versionToNum(version);
  }
  json['version_desc'] = versionDesc;

  const encoder = JsonEncoder.withIndent('    ');
  file.writeAsStringSync('${encoder.convert(json)}\n');

  print('📄 app_version.json');
  print('   version: ${json['version']}');
  print('   version_num: ${json['version_num']}');
  print('   version_desc: ${changes.length} 条变更');
}

// ─── metainfo.xml ───────────────────────────────────────────────────────────────

void _updateMetainfo(File file, Map<String, List<String>> entries) {
  if (!file.existsSync()) {
    stderr.writeln('⚠️  跳过 metainfo.xml: 文件不存在');
    return;
  }

  final today = DateTime.now().toIso8601String().split('T').first;
  final releaseBlocks = <String>[];
  for (final entry in entries.entries) {
    releaseBlocks.add(_buildReleaseBlock(entry.key, entry.value, today));
  }

  final content = file.readAsStringSync();
  final releasesReg = RegExp(
    r'(<releases\b[^>]*>)([\s\S]*?)(  </releases>)',
    multiLine: true,
    dotAll: true,
  );

  final newContent = content.replaceFirstMapped(
    releasesReg,
    (m) => '${m.group(1)}\n${releaseBlocks.join('\n')}${m.group(3)}',
  );

  file.writeAsStringSync(newContent);
  print('📄 metainfo.xml');
  print('   版本数: ${entries.length}');
}

String _buildReleaseBlock(String version, List<String> changes, String date) {
  final buffer = StringBuffer();
  buffer.writeln('    <release version="$version" date="$date">');
  buffer.writeln('      <description>');
  for (final line in changes) {
    buffer.writeln('        <p>${_xmlEscape(line)}</p>');
  }
  buffer.writeln('      </description>');
  buffer.writeln('    </release>');
  return buffer.toString();
}

// ─── 工具函数 ────────────────────────────────────────────────────────────────────

String _xmlEscape(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&apos;');

Map<String, List<String>> _parseChangelog(String content) {
  final entries = <String, List<String>>{};
  String? currentVersion;

  for (final line in content.split('\n')) {
    final trimmed = line.trim();
    final versionMatch = RegExp(r'^##\s+(\d+\.\d+\.\d+)').firstMatch(trimmed);
    if (versionMatch != null) {
      currentVersion = versionMatch.group(1)!;
      entries[currentVersion] = [];
      continue;
    }
    if (currentVersion != null && trimmed.startsWith('- ')) {
      entries[currentVersion]!.add(trimmed.substring(2).trimRight());
    }
  }

  return entries;
}

int _versionToNum(String version) {
  final parts = version.split('.');
  if (parts.length != 3) return 0;
  return int.parse(parts[0]) * 10000 +
      int.parse(parts[1]) * 100 +
      int.parse(parts[2]);
}

String _findProjectRoot() {
  var dir = Directory.current;
  while (true) {
    if (File('${dir.path}/pubspec.yaml').existsSync() &&
        Directory('${dir.path}/assets').existsSync()) {
      return dir.path;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) return Directory.current.path;
    dir = parent;
  }
}
