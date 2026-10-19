import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/noticia_model.dart';

class NoticiaService {
  static const String _endpoint = 'https://jsonplaceholder.typicode.com/posts';
  static const String _endpointInvalido = 'https://endereco-que-nao-existe-pdm.com/posts';

  final http.Client _client;

  NoticiaService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<NoticiaModel>> buscarNoticias({bool simularErro = false}) async {
    final url = simularErro ? _endpointInvalido : _endpoint;

    try {
      final response = await _client.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> listaJson = jsonDecode(response.body);
        return listaJson.map((json) => NoticiaModel.fromJson(json)).toList();
      } else {
        throw Exception('Status HTTP de erro: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Falha ao conectar com a API: $e');
    }
  }
}