import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/dashboard_models.dart';

abstract interface class LaborDirectoryRepository {
  Future<List<LaborDepartment>> loadDepartments();
}

class DemoLaborDirectoryRepository implements LaborDirectoryRepository {
  const DemoLaborDirectoryRepository();

  static const _departments = [
    LaborDepartment(
      code: 'DEMO-CARE',
      name: 'Resident Care',
      employees: [
        LaborEmployee(
          code: 'DEMO-101',
          name: 'Robin Silva',
          rateType: 'hourly',
          rateAmount: 36.50,
        ),
        LaborEmployee(
          code: 'DEMO-102',
          name: 'Jamie Patel',
          rateType: 'hourly',
          rateAmount: 32,
        ),
        LaborEmployee(
          code: 'DEMO-103',
          name: 'Sam Rivera',
          rateType: 'hourly',
          rateAmount: 28.75,
        ),
      ],
    ),
    LaborDepartment(
      code: 'DEMO-DINING',
      name: 'Dining Services',
      employees: [
        LaborEmployee(
          code: 'DEMO-201',
          name: 'Casey Nguyen',
          rateType: 'hourly',
          rateAmount: 22.50,
        ),
        LaborEmployee(
          code: 'DEMO-202',
          name: 'Parker James',
          rateType: 'hourly',
          rateAmount: 21.25,
        ),
        LaborEmployee(
          code: 'DEMO-203',
          name: 'Riley Chen',
          rateType: 'hourly',
          rateAmount: 23,
        ),
      ],
    ),
    LaborDepartment(
      code: 'DEMO-HOUSEKEEPING',
      name: 'Housekeeping',
      employees: [
        LaborEmployee(
          code: 'DEMO-301',
          name: 'Avery Brooks',
          rateType: 'hourly',
          rateAmount: 21.50,
        ),
        LaborEmployee(
          code: 'DEMO-302',
          name: 'Taylor Carter',
          rateType: 'hourly',
          rateAmount: 20.75,
        ),
        LaborEmployee(
          code: 'DEMO-303',
          name: 'Morgan Diaz',
          rateType: 'hourly',
          rateAmount: 22.25,
        ),
      ],
    ),
    LaborDepartment(
      code: 'DEMO-ADMIN',
      name: 'Administration',
      employees: [
        LaborEmployee(
          code: 'DEMO-401',
          name: 'Drew Ellis',
          rateType: 'salary',
          rateAmount: 68000,
        ),
        LaborEmployee(
          code: 'DEMO-402',
          name: 'Quinn Foster',
          rateType: 'salary',
          rateAmount: 74500,
        ),
        LaborEmployee(
          code: 'DEMO-403',
          name: 'Jordan Lee',
          rateType: 'hourly',
          rateAmount: 25.50,
        ),
      ],
    ),
  ];

  @override
  Future<List<LaborDepartment>> loadDepartments() async => _departments;
}

class HttpLaborDirectoryRepository implements LaborDirectoryRepository {
  const HttpLaborDirectoryRepository({this.client});

  final http.Client? client;

  @override
  Future<List<LaborDepartment>> loadDepartments() async {
    const configuredBaseUrl = String.fromEnvironment('LABOR_API_BASE_URL');
    final baseUri = configuredBaseUrl.isEmpty
        ? Uri.base
        : Uri.parse(configuredBaseUrl);
    final response = await (client?.get ?? http.get)(
      baseUri.resolve('/api/labor-directory'),
    );
    final decoded = jsonDecode(response.body);

    if (response.statusCode != 200) {
      final message = decoded is Map<String, dynamic>
          ? decoded['error']?.toString()
          : null;
      throw StateError(message ?? 'Labor directory request failed.');
    }
    if (decoded is! List<dynamic>) {
      throw const FormatException('Labor directory response is invalid.');
    }

    return decoded
        .map(
          (department) =>
              LaborDepartment.fromJson(department as Map<String, dynamic>),
        )
        .toList();
  }
}
