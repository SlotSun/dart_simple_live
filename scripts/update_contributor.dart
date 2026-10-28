// ignore_for_file: avoid_print
import 'dart:io';

/// 将 GitHub 用户添加到 README.md 的 Contributors 区域。
///
/// 用法:
///   dart run scripts/add_contributor.dart https://github.com/username
///
/// README.md 中需要存在:
///   <!-- CONTRIBUTORS:START -->
///   <!-- CONTRIBUTORS:END -->
void main(List<String> args) {
  final projectRoot = _findProjectRoot();
  final readmeFile = File('$projectRoot/README.md');

  if (!readmeFile.existsSync()) {
    stderr.writeln('❌ README.md 不存在');
    exit(2);
  }

  if (args.isEmpty) {
    stderr.writeln('❌ 请提供 GitHub 用户主页链接');
    stderr.writeln(
      '   用法: dart run scripts/add_contributor.dart '
      'https://github.com/username',
    );
    exit(2);
  }

  final username = _parseGithubUsername(args.first);
  if (username == null) {
    stderr.writeln('❌ 无效的 GitHub 用户主页链接');
    stderr.writeln('   示例: https://github.com/username');
    exit(2);
  }

  const startMarker = '<!-- CONTRIBUTORS:START -->';
  const endMarker = '<!-- CONTRIBUTORS:END -->';

  final content = readmeFile.readAsStringSync();

  final start = content.indexOf(startMarker);
  final end = content.indexOf(endMarker);

  if (start == -1 || end == -1 || end < start) {
    stderr.writeln('❌ README.md 中未找到 Contributors 标记');
    stderr.writeln('   请添加:');
    stderr.writeln('   $startMarker');
    stderr.writeln('   $endMarker');
    exit(1);
  }

  final contributors = _parseContributors(content.substring(start + startMarker.length, end));

  if (contributors.contains(username)) {
    print('⚠️  @$username 已经存在，无需重复添加');
    return;
  }

  contributors.add(username);

  final newContributors = _buildContributors(contributors);

  final newContent = content.replaceRange(start + startMarker.length, end, '\n$newContributors\n');

  readmeFile.writeAsStringSync(newContent);

  print('📄 README.md');
  print('   contributor: @$username');
  print('   contributors: ${contributors.length}');
  print('');
  print('✅ Contributor 添加完成');
}

/// 从 GitHub 用户主页 URL 中提取 username。
String? _parseGithubUsername(String input) {
  final uri = Uri.tryParse(input.trim());

  if (uri == null || uri.scheme != 'https' || uri.host.toLowerCase() != 'github.com') {
    return null;
  }

  final segments = uri.pathSegments.where((e) => e.isNotEmpty).toList();

  if (segments.length != 1) {
    return null;
  }

  final username = segments.first;

  if (!RegExp(r'^[A-Za-z0-9-]+$').hasMatch(username)) {
    return null;
  }

  return username;
}

/// 从已有 Contributors HTML 中提取 GitHub 用户名。
List<String> _parseContributors(String content) {
  final contributors = <String>[];

  final regex = RegExp(r'<a\s+href="https://github\.com/([A-Za-z0-9-]+)"');

  for (final match in regex.allMatches(content)) {
    final username = match.group(1)!;

    if (!contributors.contains(username)) {
      contributors.add(username);
    }
  }

  return contributors;
}

/// 生成 Contributors HTML。
String _buildContributors(List<String> contributors) {
  const perLine = 8;

  final buffer = StringBuffer();
  buffer.writeln('<table>');

  for (var i = 0; i < contributors.length; i += perLine) {
    buffer.writeln('  <tr>');

    final end = (i + perLine).clamp(0, contributors.length);

    for (var j = i; j < end; j++) {
      final username = contributors[j];

      buffer.writeln('    <td align="center">');
      buffer.writeln(
        '      <a href="https://github.com/$username">',
      );
      buffer.writeln(
        '        <img src="https://github.com/$username.png" '
            'width="60px;" alt="$username"/>',
      );
      buffer.writeln('        <br />');
      buffer.writeln('        <sub><b>$username</b></sub>');
      buffer.writeln('      </a>');
      buffer.writeln('    </td>');
    }

    buffer.writeln('  </tr>');
  }

  buffer.writeln('</table>');

  return buffer.toString();
}

String _findProjectRoot() {
  var dir = Directory.current;

  while (true) {
    if (File('${dir.path}/pubspec.yaml').existsSync() && File('${dir.path}/README.md').existsSync()) {
      return dir.path;
    }

    final parent = dir.parent;

    if (parent.path == dir.path) {
      return Directory.current.path;
    }

    dir = parent;
  }
}
