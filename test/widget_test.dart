import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:pdm_aula10_apis/models/noticia_model.dart';
import 'package:pdm_aula10_apis/screens/detalhe_noticia_screen.dart';
import 'package:pdm_aula10_apis/screens/feed_noticias_screen.dart';
import 'package:pdm_aula10_apis/services/noticia_service.dart';

class ServiceFalso extends NoticiaService {
  final List<NoticiaModel> retorno;
  final bool falhar;
  final Duration atraso;

  ServiceFalso({
    this.retorno = const [],
    this.falhar = false,
    this.atraso = Duration.zero,
  });

  @override
  Future<List<NoticiaModel>> buscarNoticias({bool simularErro = false}) async {
    await Future.delayed(atraso);
    if (falhar || simularErro) {
      throw Exception('Falha ao conectar com a API');
    }
    return retorno;
  }
}

void main() {
  final noticiasFake = [
    NoticiaModel(id: 1, autorId: 10, titulo: 'Primeira noticia', resumo: 'Corpo da primeira'),
    NoticiaModel(id: 2, autorId: 20, titulo: 'Segunda noticia', resumo: 'Corpo da segunda'),
  ];

  Widget montarTela(NoticiaService service) {
    return MaterialApp(home: FeedNoticiasScreen(service: service));
  }

  group('NoticiaModel.fromJson', () {
    test('mapeia as chaves da API para os atributos em Dart', () {
      final noticia = NoticiaModel.fromJson({
        'id': 7,
        'userId': 3,
        'title': 'Titulo vindo da API',
        'body': 'Conteudo completo da noticia',
      });

      expect(noticia.id, 7);
      expect(noticia.autorId, 3);
      expect(noticia.titulo, 'Titulo vindo da API');
      expect(noticia.resumo, 'Conteudo completo da noticia');
    });

    test('aplica valores padrao quando as chaves vem nulas', () {
      final noticia = NoticiaModel.fromJson({
        'id': null,
        'userId': null,
        'title': null,
        'body': null,
      });

      expect(noticia.id, 0);
      expect(noticia.autorId, 0);
      expect(noticia.titulo, '');
      expect(noticia.resumo, '');
    });

    test('aplica valores padrao quando as chaves nao existem', () {
      final noticia = NoticiaModel.fromJson({});

      expect(noticia.id, 0);
      expect(noticia.titulo, '');
    });
  });

  group('NoticiaService', () {
    test('converte a lista JSON em objetos quando o status e 200', () async {
      final cliente = MockClient((request) async {
        return http.Response(
          jsonEncode([
            {'id': 1, 'userId': 5, 'title': 'Um', 'body': 'Corpo um'},
            {'id': 2, 'userId': 6, 'title': 'Dois', 'body': 'Corpo dois'},
          ]),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final lista = await NoticiaService(client: cliente).buscarNoticias();

      expect(lista.length, 2);
      expect(lista.first, isA<NoticiaModel>());
      expect(lista.first.titulo, 'Um');
      expect(lista.last.autorId, 6);
    });

    test('lanca excecao quando o status nao e 200', () async {
      final cliente = MockClient((request) async => http.Response('nao encontrado', 404));

      expect(
        () => NoticiaService(client: cliente).buscarNoticias(),
        throwsA(isA<Exception>()),
      );
    });

    test('lanca excecao quando a requisicao falha na rede', () async {
      final cliente = MockClient((request) async => throw Exception('sem conexao'));

      expect(
        () => NoticiaService(client: cliente).buscarNoticias(),
        throwsA(isA<Exception>()),
      );
    });

    test('usa a URL invalida quando simularErro e verdadeiro', () async {
      late Uri urlChamada;
      final cliente = MockClient((request) async {
        urlChamada = request.url;
        return http.Response('[]', 200);
      });

      await NoticiaService(client: cliente).buscarNoticias(simularErro: true);

      expect(urlChamada.host, contains('nao-existe'));
    });
  });

  group('FeedNoticiasScreen', () {
    testWidgets('exibe o indicador de carregamento antes dos dados chegarem',
        (tester) async {
      await tester.pumpWidget(montarTela(
        ServiceFalso(retorno: noticiasFake, atraso: const Duration(milliseconds: 300)),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Primeira noticia'), findsOneWidget);
    });

    testWidgets('renderiza um card para cada noticia recebida', (tester) async {
      await tester.pumpWidget(montarTela(ServiceFalso(retorno: noticiasFake)));
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsNWidgets(2));
      expect(find.text('Primeira noticia'), findsOneWidget);
      expect(find.text('Segunda noticia'), findsOneWidget);
    });

    testWidgets('exibe o estado de erro com botao de recarga', (tester) async {
      await tester.pumpWidget(montarTela(ServiceFalso(falhar: true)));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
      expect(find.text('Tentar Novamente'), findsOneWidget);
      expect(find.byType(Card), findsNothing);
    });

    testWidgets('exibe o estado vazio quando a API nao retorna itens',
        (tester) async {
      await tester.pumpWidget(montarTela(ServiceFalso(retorno: const [])));
      await tester.pumpAndSettle();

      expect(find.text('Nenhuma notícia encontrada.'), findsOneWidget);
    });

    testWidgets('o filtro reduz a lista pelo titulo', (tester) async {
      await tester.pumpWidget(montarTela(ServiceFalso(retorno: noticiasFake)));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'segunda');
      await tester.pump();

      expect(find.text('Segunda noticia'), findsOneWidget);
      expect(find.text('Primeira noticia'), findsNothing);
    });

    testWidgets('o filtro ignora maiusculas e minusculas', (tester) async {
      await tester.pumpWidget(montarTela(ServiceFalso(retorno: noticiasFake)));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'PRIMEIRA');
      await tester.pump();

      expect(find.text('Primeira noticia'), findsOneWidget);
      expect(find.byType(Card), findsNWidgets(1));
    });

    testWidgets('tocar no card abre a tela de detalhes com o objeto',
        (tester) async {
      await tester.pumpWidget(montarTela(ServiceFalso(retorno: noticiasFake)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Segunda noticia'));
      await tester.pumpAndSettle();

      expect(find.byType(DetalheNoticiaScreen), findsOneWidget);
      expect(find.text('Detalhes da Notícia'), findsOneWidget);
      expect(find.text('Corpo da segunda'), findsOneWidget);
      expect(find.text('Autor 20'), findsOneWidget);
    });
  });
}