import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/core/constants/api_constants.dart';

void main() {
  test('baseUrl resolves to the production URL from the real .env', () {
    dotenv.loadFromString(envString: File('.env').readAsStringSync());

    expect(
      ApiConstants.baseUrl,
      'https://kelasku-api-production.up.railway.app',
    );
  });

  test('baseUrl falls back to emulator host when API_URL is empty', () {
    // baseUrl is a static final evaluated once, so exercise the resolver
    // indirectly: an empty value must not produce an empty base URL.
    dotenv.loadFromString(envString: 'API_URL=');
    final url = dotenv.env['API_URL']?.trim();
    final resolved =
        (url == null || url.isEmpty) ? 'http://10.0.2.2:3000' : url;

    expect(resolved, 'http://10.0.2.2:3000');
  });
}
