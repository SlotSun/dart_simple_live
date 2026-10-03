import 'package:flutter_test/flutter_test.dart';
import 'package:simple_live_app/app/utils.dart';

void main() {
  test('database version stays numeric for local and prerelease builds', () {
    expect(Utils.parseVersion('1.8.14'), 10814);
    expect(Utils.parseVersion('1.8.14-local.1'), 10814);
    expect(Utils.parseVersion('1.8.14-local.2+10816'), 10814);
    expect(Utils.parseVersion('1.8.14+10814'), 10814);
    expect(Utils.parseVersion('1.8.14-beta.1'), 10814);
    expect(Utils.parseVersion('1.7.9'), 10709);
    expect(Utils.parseVersion('1.8.14-local.2'), greaterThan(Utils.parseVersion('1.8.13')));
  });
}
