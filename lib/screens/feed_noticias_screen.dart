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
  final _buscaController = TextEditingController();

  List<NoticiaModel> _noticias = [];
  bool _carregando = true;
  String? _erro;
  String _filtro = '';

  @override
  void initState() {
    super.initState();
    _carregarFeed();
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  List<NoticiaModel> get _noticiasFiltradas {
    if (_filtro.isEmpty) return _noticias;
    final termo = _filtro.toLowerCase();
    return _noticias
        .where((noticia) => noticia.titulo.toLowerCase().contains(termo))
        .toList();
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
    final mostrarBusca = !_carregando && _erro == null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feed de Notícias'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _carregarFeed)],
      ),
      body: Column(
        children: [
          if (mostrarBusca)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: TextField(
                controller: _buscaController,
                onChanged: (valor) => setState(() => _filtro = valor),
                decoration: InputDecoration(
                  hintText: 'Buscar por título...',
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  suffixIcon: _filtro.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _buscaController.clear();
                            setState(() => _filtro = '');
                          },
                        ),
                ),
              ),
            ),
          Expanded(child: _buildConteudo()),
        ],
      ),
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

    final lista = _noticiasFiltradas;

    if (lista.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey[500]),
            const SizedBox(height: 12),
            const Text('Nenhuma notícia encontrada.'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: lista.length,
      padding: const EdgeInsets.all(12),
      itemBuilder: (context, index) {
        final noticia = lista[index];
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