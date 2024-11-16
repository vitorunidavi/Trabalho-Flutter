import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(AppTarefas());
}

class AppTarefas extends StatefulWidget {
  @override
  _AppTarefasState createState() => _AppTarefasState();
}

class _AppTarefasState extends State<AppTarefas> {
  bool _isDarkMode = false;

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App de Tarefas',
      theme: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: TelaPrincipal(onToggleTheme: _toggleTheme, isDarkMode: _isDarkMode),
    );
  }
}

class TelaPrincipal extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  TelaPrincipal({required this.onToggleTheme, required this.isDarkMode});

  @override
  _TelaPrincipalState createState() => _TelaPrincipalState();
}

class _TelaPrincipalState extends State<TelaPrincipal> {
  final List<Map<String, dynamic>> _tarefas = [];
  final TextEditingController _controller = TextEditingController();
  final List<String> _categorias = ["Trabalho", "Pessoal", "Compras"];
  String _categoriaSelecionada = "Trabalho";
  bool _showConcluded = false;

  @override
  void initState() {
    super.initState();
    _carregarTarefas();
  }

  void _carregarTarefas() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> tarefasSalvas = prefs.getStringList('tarefas') ?? [];
    setState(() {
      _tarefas.addAll(tarefasSalvas.map((t) {
        List<String> partes = t.split('|');
        return {
          'titulo': partes[0],
          'concluida': partes[1] == 'true',
          'dataConclusao':
              partes[2].isNotEmpty ? DateTime.parse(partes[2]) : null,
          'categoria': partes[3],
        };
      }).toList());
    });
  }

  void _salvarTarefas() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> tarefasParaSalvar = _tarefas.map((tarefa) {
      return "${tarefa['titulo']}|${tarefa['concluida']}|${tarefa['dataConclusao']?.toIso8601String() ?? ''}|${tarefa['categoria']}";
    }).toList();
    prefs.setStringList('tarefas', tarefasParaSalvar);
  }

  void _adicionarTarefa(String titulo) {
    if (titulo.isNotEmpty) {
      setState(() {
        _tarefas.add({
          'titulo': titulo,
          'concluida': false,
          'dataConclusao': null,
          'categoria': _categoriaSelecionada,
        });
      });
      _salvarTarefas();
      _controller.clear();
    }
  }

  void _toggleConclusao(int index) {
    setState(() {
      _tarefas[index]['concluida'] = !_tarefas[index]['concluida'];
      _tarefas[index]['dataConclusao'] =
          _tarefas[index]['concluida'] ? DateTime.now() : null;
    });
    _salvarTarefas();
  }

  void _removerTarefa(int index) {
    setState(() {
      _tarefas.removeAt(index);
    });
    _salvarTarefas();
  }

  void _toggleFiltro() {
    setState(() {
      _showConcluded = !_showConcluded;
    });
  }

  void _editarTarefa(int index) {
    if (_tarefas[index]['concluida'] == true)
      return; // Bloquear edição para tarefas concluídas
    _controller.text = _tarefas[index]['titulo'];
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _controller,
                decoration: InputDecoration(labelText: "Editar Tarefa"),
              ),
              DropdownButtonFormField(
                value: _tarefas[index]['categoria'],
                items: _categorias.map((categoria) {
                  return DropdownMenuItem(
                    value: categoria,
                    child: Text(categoria),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _tarefas[index]['categoria'] = value;
                  });
                },
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _tarefas[index]['titulo'] = _controller.text;
                  });
                  _salvarTarefas();
                  Navigator.pop(context);
                },
                child: Text("Salvar"),
              ),
            ],
          ),
        );
      },
    );
  }

  void _navegarParaDetalhes(String titulo, String categoria, bool concluida) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TelaDetalhes(
          tarefa: titulo,
          categoria: categoria,
          concluida: concluida,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> tarefasExibidas = _showConcluded
        ? _tarefas.where((tarefa) => tarefa['concluida'] == true).toList()
        : _tarefas.where((tarefa) => tarefa['concluida'] == false).toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lista de Tarefas'),
            Text(
              'Concluídas: ${_tarefas.where((t) => t['concluida']).length}',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16.0), // Ajuste para afastar os ícones da borda
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                      widget.isDarkMode ? Icons.dark_mode : Icons.light_mode),
                  onPressed: widget.onToggleTheme,
                  tooltip: 'Alternar Tema',
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                      _showConcluded ? Icons.visibility : Icons.visibility_off),
                  onPressed: _toggleFiltro,
                  tooltip:
                      'Mostrar ${_showConcluded ? "Pendentes" : "Concluídas"}',
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Nova Tarefa',
                border: OutlineInputBorder(),
              ),
              onSubmitted: _adicionarTarefa,
            ),
          ),
          DropdownButtonFormField(
            value: _categoriaSelecionada,
            items: _categorias.map((categoria) {
              return DropdownMenuItem(
                value: categoria,
                child: Text(categoria),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _categoriaSelecionada = value.toString();
              });
            },
          ),
          Expanded(
            child: ListView.builder(
              itemCount: tarefasExibidas.length,
              itemBuilder: (context, index) {
                final tarefa = tarefasExibidas[index];
                final tarefaIndex = _tarefas.indexOf(tarefa);
                return Card(
                  child: ListTile(
                    title: Text(
                      tarefa['titulo'],
                      style: TextStyle(
                        decoration: tarefa['concluida']
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    subtitle: tarefa['dataConclusao'] != null
                        ? Text("Concluída em: ${tarefa['dataConclusao']}")
                        : Text("Categoria: ${tarefa['categoria']}"),
                    leading: IconButton(
                      icon: Icon(
                        tarefa['concluida']
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                      ),
                      onPressed: () => _toggleConclusao(tarefaIndex),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit,
                              color: tarefa['concluida']
                                  ? Colors.grey
                                  : Colors.blue),
                          onPressed: tarefa['concluida']
                              ? null
                              : () => _editarTarefa(tarefaIndex),
                          tooltip: tarefa['concluida']
                              ? 'Tarefa concluída, não editável'
                              : 'Editar Tarefa',
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removerTarefa(tarefaIndex),
                        ),
                      ],
                    ),
                    onTap: () => _navegarParaDetalhes(
                      tarefa['titulo'],
                      tarefa['categoria'],
                      tarefa['concluida'],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _adicionarTarefa(_controller.text),
        child: Icon(Icons.add),
      ),
    );
  }
}

class TelaDetalhes extends StatelessWidget {
  final String tarefa;
  final String categoria;
  final bool concluida;

  TelaDetalhes({
    required this.tarefa,
    required this.categoria,
    required this.concluida,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Detalhes da Tarefa')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              tarefa,
              style: TextStyle(fontSize: 24),
            ),
            Text(
              'Categoria: $categoria',
              style: TextStyle(fontSize: 18),
            ),
            Text(
              concluida ? 'Status: Concluída' : 'Status: Pendente',
              style: TextStyle(
                  fontSize: 18, color: concluida ? Colors.green : Colors.red),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Voltar'),
            ),
          ],
        ),
      ),
    );
  }
}
