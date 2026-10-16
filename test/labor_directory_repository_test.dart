import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:laurel_lake_dashboard/repositories/labor_directory_repository.dart';

void main() {
  test('loads grouped departments and derives pay subtitles', () async {
    final repository = HttpLaborDirectoryRepository(
      client: MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/labor-directory');
        return http.Response(
          jsonEncode([
            {
              'code': '53',
              'name': 'Housekeeping',
              'employees': [
                {
                  'code': '101627',
                  'name': 'Anthony Spehar',
                  'rateType': 'hourly',
                  'rateAmount': 30,
                },
                {
                  'code': '101628',
                  'name': 'Luenah Sachtjen',
                  'rateType': 'salary',
                  'rateAmount': 40,
                },
              ],
            },
          ]),
          200,
        );
      }),
    );

    final departments = await repository.loadDepartments();

    expect(departments, hasLength(1));
    expect(departments.single.name, 'Housekeeping');
    expect(departments.single.employees[0].rateSubtitle, 'Hourly · \$30/hr');
    expect(departments.single.employees[1].rateSubtitle, 'Salary · \$40');
  });
}
