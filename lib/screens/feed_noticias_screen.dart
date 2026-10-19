import 'package:flutter/material.dart';
import '../models/noticia_model.dart';
import '../services/noticia_service.dart';
import 'detalhe_noticia_screen.dart';

class FeedNoticiasScreen extends StatefulWidget {
  final NoticiaService? service;

  const FeedNoticiasScreen({super.key, this.service});

  @override
  State<FeedNoticiasScreen> createState() => _FeedNoticiasScreenState();
}

class _FeedNoticiasScreenState extends State<FeedNoticiasScreen> {
 late final NoticiaService _service;
  final _buscaController = TextEditingController();

  List<NoticiaModel> _noticias = [];
  bool _carregando = true;
  bool _modoErro = false;
  String? _erro;
  String _filtro = '';

    @override
  void initState() {
    super.initState();
    _service = widget.service ?? NoticiaService();
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
      final lista = await _service.buscarNoticias(simularErro: _modoErro);
      setState(() => _noticias = lista);
    } catch (e) {
      setState(() => _erro = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _carregando = false);
    }
  }

  void _alternarModoErro() {
    setState(() => _modoErro = !_modoErro);
    _carregarFeed();
  }

  void _abrirDetalhes(NoticiaModel noticia) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetalheNoticiaScreen(noticia: noticia),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mostrarBusca = !_carregando && _erro == null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feed de Notícias'),
        actions: [
          IconButton(
            icon: Icon(_modoErro ? Icons.bug_report : Icons.bug_report_outlined),
            color: _modoErro ? Colors.red : null,
            tooltip: 'Simular erro de conexão',
            onPressed: _alternarModoErro,
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _carregarFeed),
        ],
      ),
      body: Column(
        children: [
          if (_modoErro)
            Container(
              width: double.infinity,
              color: Colors.red.shade100,
              padding: const EdgeInsets.all(8),
              child: const Text(
                'Modo de teste: usando URL inválida',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12),
              ),
            ),
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, size: 56, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _erro!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _carregarFeed, child: const Text('Tentar Novamente')),
            ],
          ),
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
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _abrirDetalhes(noticia),
          ),
        );
      },
    );
  }
}