import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/dashboard_models.dart';

abstract interface class LaborDirectoryRepository {
  Future<List<LaborDepartment>> loadDepartments();
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
