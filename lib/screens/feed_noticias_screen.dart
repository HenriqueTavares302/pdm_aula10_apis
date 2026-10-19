import 'package:flutter/material.dart';
import '../models/noticia_model.dart';
import '../services/noticia_service.dart';

class FeedNoticiasScreen extends StatefulWidget {
  const FeedNoticiasScreen({super.key});

  @override
  State<FeedNoticiasScreen> createState() => _FeedNoticiasScreenState();
}

class _FeedNoticiasScreenState extends State<FeedNoticiasScreen> {
  final _service = NoticiaService();
  List<NoticiaModel> _noticias = [];
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarFeed();
  }

  Future<void> _carregarFeed() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final lista = await _service.buscarNoticias();
      setState(() => _noticias = lista);
    } catch (e) {
      setState(() => _erro = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feed de Notícias'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _carregarFeed)],
      ),
      body: _buildConteudo(),
    );
  }

  Widget _buildConteudo() {
    if (_carregando) return const Center(child: CircularProgressIndicator());

    if (_erro != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_erro!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _carregarFeed, child: const Text('Tentar Novamente')),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _noticias.length,
      padding: const EdgeInsets.all(12),
      itemBuilder: (context, index) {
        final noticia = _noticias[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(child: Text(noticia.id.toString())),
            title: Text(noticia.titulo, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(noticia.resumo, maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
        );
      },
    );
  }
}