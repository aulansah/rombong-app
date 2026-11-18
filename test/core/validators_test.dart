import 'package:ecommerce_app/core/widgets/form_widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('strongPassword mirrors the backend policy', () {
    expect(Validators.strongPassword('Secret123'), isNull);
    expect(Validators.strongPassword('Se1'), isNotNull);
    expect(Validators.strongPassword('secret123'), isNotNull);
    expect(Validators.strongPassword('SECRET123'), isNotNull);
    expect(Validators.strongPassword('SecretSecret'), isNotNull);
    expect(Validators.strongPassword('Aa1' * 25), isNotNull);
  });

  test('email', () {
    expect(Validators.email('auldy@example.com'), isNull);
    expect(Validators.email('auldy@'), isNotNull);
    expect(Validators.email(''), isNotNull);
  });
}
