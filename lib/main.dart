import 'package:flutter/material.dart';
import 'package:camera/camera.dart'; 
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:uni_links/uni_links.dart';
import 'dart:async';
import 'package:flutter/services.dart' show PlatformException;
import 'package:image_picker/image_picker.dart';

class Dados {
  String apelido;
  int pat;
  String? foto;

  Dados({
    required this.apelido,
    required this.pat,
    this.foto,
  });

  Map<String, dynamic> toJson() {
    return {
      'apelido': apelido,
      'pat': pat,
      'foto': foto,
    };
  }
}


final TextEditingController _apelidoController = TextEditingController();
bool _isApelidoValid = false;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();

}

class _HomeScreenState extends State<HomeScreen> {
  int _pat = 0; // Valor inicial do PAT
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _handleDeepLink();
  }

  @override
  void dispose() {
    _apelidoController.dispose();
    super.dispose();
  }

  void _validateApelido(String value) {
    setState(() {
      _isApelidoValid = value.length >= 3 && value.length <= 20 && RegExp(r'^[a-zA-Z0-9]*$').hasMatch(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entrada de Dados'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'PAT: $_pat',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _imageFile != null
                ? Image.file(
                    _imageFile!,
                    height: 150,
                    width: 150,
                    fit: BoxFit.cover,
                  )
                : ElevatedButton(
                    onPressed: () => _pickImage(),
                    child: const Text('Capturar Foto'),
                  ),
            const SizedBox(height: 10),
            TextField(
              controller: _apelidoController,
              decoration: const InputDecoration(labelText: 'Apelido'),
              onChanged: _validateApelido,
            ),
            const SizedBox(height: 10),
            Text(
              _isApelidoValid ? 'Apelido válido' : 'Apelido inválido: Deve conter de 3 a 20 caracteres sendo letras e/ou números',
              style: TextStyle(color: _isApelidoValid ? Colors.green : Colors.red),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isApelidoValid ? () => _salvarDados(_apelidoController.text, _pat) : null,
              child: const Text('Salvar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SavedDataScreen()),
                );
              },
              child: const Text('Dados Salvos'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const APIScreen()),
                );
              },
              child: const Text('Acessar API Screen'),
            ),
          ],
        ),
      ),
    );
  }

  void _salvarDados(apelido, pat) async {

    try {
      final dados = Dados(
        apelido: apelido,
        pat: _pat,
        foto: _imageFile != null ? base64Encode(await _imageFile!.readAsBytes()) : null,
      );

      final file = await _getLocalFile();

      // Verifica se o arquivo já existe
      if (!await file.exists()) {
        await file.create();
      }

      // Lê o conteúdo atual do arquivo
      List<dynamic> listaDados = [];

      // Tenta decodificar o JSON do arquivo
      try {
        listaDados = jsonDecode(await file.readAsString());
      } catch (e) {
        // Se ocorrer uma exceção ao decodificar o JSON, trata o erro aqui
        print('Erro ao decodificar o JSON: $e');
      }

      // Verifica se o apelido já está na lista
      if (listaDados.any((item) => item['apelido'] == apelido)) {
        // Se o apelido já estiver na lista, exibe uma mensagem de erro
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('O apelido "$apelido" já está na lista.'),
            backgroundColor: Colors.red,
          ),
        );
        return; // Sai da função sem salvar os dados
      }

      // Adiciona os novos dados à lista
      listaDados.add(dados.toJson());

      // Salva os dados atualizados no arquivo
      await file.writeAsString(jsonEncode(listaDados));

      // Exibe mensagem de sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dados salvos com sucesso! Apelido: $apelido'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Exibe mensagem de erro
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar os dados: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<File> _getLocalFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path;
    return File('$path/dados.json');
  }

  void _handleDeepLink() async {
    String? initialLink;
    try {
      initialLink = await getInitialLink();
      if (initialLink != null) {
        _processLink(Uri.parse(initialLink));
      }
    } on PlatformException {
      // Lidar com exceções se houver problemas ao obter o link inicial
    }
  }

  void _processLink(Uri link) {
    if (link.scheme == 'caixa.gov.br' && link.host == 'meupat') {
      final pat = link.queryParameters['pat'];
      if (pat != null) {
        // Atualizar o estado do widget com o PAT recebido
        setState(() {
          _pat = int.tryParse(pat) ?? 0; // Converta o PAT para um inteiro
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.getImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }
}


class APIScreen extends StatefulWidget {
  const APIScreen({Key? key}) : super(key: key);

  @override
  _APIScreenState createState() => _APIScreenState();
}

class _APIScreenState extends State<APIScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this); // Número de abas (correspondendo ao número de solicitações)
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<dynamic> fetchData(String route, [String? method]) async {
  late http.Response response;
  route = "https://jsonplaceholder.typicode.com$route";
  if (method != null) {
    switch (method.toUpperCase()) {
      case 'GET':
        response = await http.get(Uri.parse(route));
        break;
      case 'POST':
        response = await http.post(Uri.parse(route));
        break;
      case 'PUT':
        response = await http.put(Uri.parse(route));
        break;
      case 'PATCH':
        response = await http.patch(Uri.parse(route));
        break;
      case 'DELETE':
        response = await http.delete(Uri.parse(route));
        break;
      default:
        throw Exception('Unsupported HTTP method: $method');
    }
  } else {
    response = await http.get(Uri.parse(route));
  }
  
  if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse is List ? jsonResponse : [jsonResponse];
    } else {
      throw Exception('Failed to load data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Posts da API'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'GET /posts'),
            Tab(text: 'GET /posts/1'),
            Tab(text: 'GET /posts/1/comments'),
            Tab(text: 'POST /posts'),
            Tab(text: 'PUT /posts/1'),
            Tab(text: 'PATCH /posts/1'),
            Tab(text: 'DELETE /posts/1'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TabContent(route: '/posts', method: 'GET', fetchData: fetchData),
          _TabContent(route: '/posts/1', method: 'GET', fetchData: fetchData),
          _TabContent(route: '/posts/1/comments', method: 'GET', fetchData: fetchData),
          _TabContent(route: '/posts', method: 'POST', fetchData: fetchData),
          _TabContent(route: '/posts/1', method: 'PUT', fetchData: fetchData),
          _TabContent(route: '/posts/1', method: 'PATCH', fetchData: fetchData),
          _TabContent(route: '/posts/1', method: 'DELETE', fetchData: fetchData),
        ],
      ),
    );
  }
}

class _TabContent extends StatefulWidget {
  final String route;
  final String? method;
  final Future<dynamic> Function(String) fetchData;

  const _TabContent({Key? key, required this.route, this.method, required this.fetchData}) : super(key: key);

  @override
  __TabContentState createState() => __TabContentState();
}

class __TabContentState extends State<_TabContent> {
  late Future<dynamic> _futureData;

  @override
  void initState() {
    super.initState();
    _futureData = widget.fetchData(widget.route);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: _futureData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Text('Erro: ${snapshot.error}'),
          );
        } else {
          return _buildDataWidget(snapshot.data);
        }
      },
    );
  }

  Widget _buildDataWidget(dynamic data) {
    return ListView.builder(
      itemCount: data.length,
      itemBuilder: (context, index) {
        final item = data[index];
        return ListTile(
          title: Text(item['title'] ?? ''),
          subtitle: Text(item['body'] ?? ''),
        );
      },
    );
  }
}

class Post {
  final int id;
  final String title;
  final String body;

  Post({required this.id, required this.title, required this.body});

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      title: json['title'],
      body: json['body'],
    );
  }
}

void _showCameraScreen(BuildContext context) async {
  try {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CameraApp(camera: firstCamera)),
    );
  } catch (e) {
    print('Erro ao acessar a câmera: $e');
    // Tratar o erro
  }
}

class CameraApp extends StatelessWidget {
  final CameraDescription camera;

  const CameraApp({
    Key? key,
    required this.camera,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: CameraScreen(camera: camera),
    );
  }
}

class CameraScreen extends StatefulWidget {
  final CameraDescription camera;

  const CameraScreen({
    Key? key,
    required this.camera,
  }) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();

    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
    );

    _initializeControllerFuture = _controller.initialize().catchError((error) {
      print('Erro ao inicializar o controlador da câmera: $error');
      // Tratar o erro
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Camera Example')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraPreview(_controller);
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

class SavedDataScreen extends StatefulWidget {
  const SavedDataScreen({Key? key}) : super(key: key);

  @override
  _SavedDataScreenState createState() => _SavedDataScreenState();
}

class _SavedDataScreenState extends State<SavedDataScreen> {
  late Future<List<Map<String, dynamic>>> _futureData;

  @override
  void initState() {
    super.initState();
    _futureData = _loadSavedData();
  }

  Future<List<Map<String, dynamic>>> _loadSavedData() async {
    try {
      final file = await _getLocalFile();
      if (!await file.exists()) {
        return []; // Retorna uma lista vazia se o arquivo não existir
      }
      final jsonData = await file.readAsString();
      final List<dynamic> decodedData = jsonDecode(jsonData);
      return decodedData.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Erro ao carregar os dados salvos: $e');
      return []; // Retorna uma lista vazia em caso de erro
    }
  }

  Future<File> _getLocalFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path;
    return File('$path/dados.json');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dados Salvos'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Erro: ${snapshot.error}'),
            );
          } else {
            final List<Map<String, dynamic>> data = snapshot.data!;
            if (data.isEmpty) {
              return const Center(child: Text('Nenhum dado salvo.'));
            } else {
              return ListView.builder(
                itemCount: data.length,
                itemBuilder: (context, index) {
                  final item = data[index];
                  return ListTile(
                    leading: Image.memory(base64Decode(item['foto'])), // Exibindo a foto
                    title: Text('Apelido: ${item['apelido']}, PAT: ${item['pat']}'),

                  );
                },
              );
            }
          }
        },
      ),
    );
  }
}