import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const String baseUrl = 'https://use.api.co.id/regional/indonesia';
  const Map<String, String> headers = {
    'x-api-co-id': '3i8RB3sYgI1F1wctRxNBi0WWmHucDNOg48hGBGOPVi2uPbDbun'
  };

  final queries = ['jember', 'JEMBER', 'TEGAL BESAR', 'tegal besar', 'kaliwates'];
  final endpoints = ['villages', 'district', 'village', 'regency'];

  for (var ep in endpoints) {
    print('--- \$ep ---');
    for (var q in queries) {
      final uri = Uri.parse('\$baseUrl/\$ep?name=\${Uri.encodeComponent(q)}');
      final res = await http.get(uri, headers: headers);
      print('\$q -> \${res.statusCode}: \${res.body.length > 100 ? res.body.substring(0, 100) + "..." : res.body}');
    }
  }
}
