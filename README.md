Desafio TEIA    
===================

Este é um projeto Flutter desenvolvido com o objetivo demonstrar o nivel 
de proficiéncia que participante detém na tecnologia mobile que mais domina. O nivel de proficiéncia é medido pelo escopo que o participante é capaz de atender no tempo 
delimitado e pelo nivel de qualidade atingido.  
Ele inclui diversas funcionalidades como captura de fotos, validação de dados de entrada, salvamento de dados localmente e acesso a uma API externa.

Estrutura do Projeto
--------------------

O projeto está organizado da seguinte forma:

*   **`lib/`**: Contém o código-fonte do aplicativo Flutter.
    *   **`main.dart`**: Arquivo principal do aplicativo, onde a execução começa e estão as funções codificadas.
    escrita de arquivos.
*   **`android/`** e **`ios/`**: Contêm arquivos específicos da plataforma para a construção do aplicativo nativo.
*   **`pubspec.yaml`**: Arquivo de manifesto do Flutter que lista as dependências do projeto.

Funcionalidades Principais
--------------------------

### Captura de Fotos

O aplicativo permite que os usuários capturem fotos usando a câmera do dispositivo. A captura de fotos é realizada na tela inicial (`_HomeScreen()`) e a foto capturada é exibida em um preview.

### Validação de Dados de Entrada

Os dados inseridos pelos usuários são validados antes de serem salvos. A tela inicial (`_HomeScreen()`) inclui um campo de entrada para o apelido do usuário, que deve conter entre 3 e 20 caracteres alfanuméricos.

### Salvamento de Dados Localmente

Os dados inseridos pelos usuários, incluindo o apelido, o PAT e a foto capturada, são salvos localmente em um arquivo JSON. Isso é feito utilizando funções de leitura e escrita de arquivos na pasta de documentos do aplicativo.

### Acesso a uma API Externa

O aplicativo também pode acessar uma API externa para obter dados. A tela de API (`_APIScreen()`) exibe várias abas, cada uma representando um endpoint da API. Os dados são recuperados usando requisições HTTP e exibidos na interface do usuário.

Dependências
------------

O projeto faz uso das seguintes dependências:

*   **`camera`**: Para captura de fotos.
*   **`image_picker`**: Para selecionar ou capturar imagens.
*   **`path_provider`**: Para acessar o sistema de arquivos local.
*   **`http`**: Para fazer requisições HTTP.
*   **`uni_links`**: Para lidar com links de deep linking.

Como Executar
-------------

1.  Certifique-se de ter o ambiente de desenvolvimento Flutter configurado.
2.  Clone este repositório.
3.  Navegue até o diretório do projeto e execute `flutter pub get` para instalar as dependências.
4.  Execute o aplicativo em um dispositivo ou emulador com `flutter run`.

Contribuição
------------

Contribuições são bem-vindas! Se encontrar um problema ou tiver alguma sugestão, sinta-se à vontade para abrir uma issue ou enviar um pull request.

Licença
-------

Este projeto está licenciado sob a Licença MIT.