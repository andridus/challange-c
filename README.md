# Cumbuca

Desafio aceito: [link para o desafio](https://github.com/appcumbuca/desafios/blob/master/desafio-back-end.md)

### Checklist
- [x] Cadastro de conta
- [x] Atualização de senha de acesso a conta
- [x] Autenticação
- [x] Atualização de senha de transação da conta
- [x] Cadastro de Transação
- [x] Cancelamento de Transação Pendente
- [x] Busca de Transações por data
- [x] Visualização de Saldo
- [x] Estorno de Transação

### Regras de Negócio
- [x] Não deve ser possível forjar um token de autenticação. Os tokens devem identificar de forma única o usuário logado.
- [x] Uma transação só deve ser realizada caso haja saldo suficiente na conta do usuário para realizá-la.
- [x] Após a realização de uma transação, a conta do usuário enviante deve ter seu valor descontado do valor da transação e a do usuário recebedor acrescentada do valor da transação.
- [x] Todas as transações realizadas devem ser registradas no banco de dados.
- [x] Caso todas as transações no banco de dados sejam realizadas novamente a partir do estado inicial de todas as contas, os saldos devem equivaler aos saldos expostos na interface. Em outros termos: Para toda conta, se somarmos os valores de todas as transações no histórico dela a qualquer momento, o saldo total da conta deve ser o saldo atual.
- [x] Uma transação só pode ser estornada uma vez.

### Algumas explicações gerais
Utilizamos uma biblioteca própria (Bee), desenvolvida com o propósito de facilitar o uso do Ecto para as funções de CRUD mais comuns como Insert, Update, Delete e Get.

Dessa maneira, ao invés de utilizarmos `Repo.get(Account, id)`, utilizamos `Account.Api.get(id)`. Essa melhoria de leiturabilidade e manutenibilidade fornecida pela biblioteca Bee tem custo zero e evita.

Utilizamos uma fork da biblioteca phoenix_swagger, em que implementamos uma forma que otimize a leiturabilidade quando aplicada sobre as actions e somente então utilizar o comportamento esperado da biblioteca e gerar o swagger.

### Explicações sobre a aplicação
  Criamos as seguintes tabelas
    - `accounts` - Contas e Accesso
    - `transactions` - Intenção de Transações
    - `consolidations` - Transações consolidadas (efetivadas) / extrato da conta
  Para o processo de teste, é necessário criar pelo menos duas `account` informando um cpf único e um saldo inicial diferente de zero, seguidamente criar a senha de acesso (que é codificada com Bcrypt no banco de dados) para realizar o login.

  Caso a senha de acesso não seja criada, a conta não estará ativa para fazer ou receber transações. (é um requisito para ativar a conta)

  Após então, com o token de acesso, é necessário criar uma senha de transação (que é usada o base64 pra codificacao simples - porque é usada somente em transação e precisa ser exibível para o usuário, caso ele esqueça a senha - preferencialmente 4 digitos)

  Em posse da senha de transação e com pelo menos duas contas ativas, realiza-se a transação informando o valor desejado e a senha de transação.

  A criação de uma intenção de transação fica em status PENDING até o worker obter esse registro e realizar as transacões

  WORKER:
    O worker funciona com um supervisor dinâmico por contas, ou seja, a partir do momento que é criado uma conta é adicionado um worker que fica esperando novas transações a partir desta conta. (o worker é um processo, e o Elixir suporta muitos processos).
    O worker tem uma fila que vai sendo populada a medida que vao sendo criadas intenções de transação. é uma fila do tipo Primeiro a Entrar, Primeiro a sair (FIFO).
    Caso o worker quebre, ele é restaurado automaticamente.

  É possível verificar o saldo da conta a qualquer momento na rota de `GET /api/accounts/:account_id/balance`
  É possível obter o histórico/extrato da conta conta a qualquer momento na rota de `GET /api/accounts/:account_id/consolidations`

### Processo de Teste
segundo arquivo do insomnia.json (use o [Insomnia](https://insomnia.rest/download))

 - `1.Accounts/create account` - Criar uma conta em rota pública  `POST /api/accounts`
 - `2.Accounts/set account access password` - Criar uma senha para acesso  `PATCH /api/:account_id/accounts/access-password`
 - `3.Auth/login` - Efetua o login usando os dados de acesso (CPF e Senha) `POST /api/auth/login`
 - `4.Accounts/set account transaction password` - Criar uma senha para efetuar transacões  `PATCH /api/:account_id/accounts/access-password`
 - `5.Accounts/get balance` - Obtem o saldo atual da conta `GET /api/accounts/:account_id/balance`
 - `6.Transactions/create transaction` - Cria uma intenção de transação para ser efetivada pelo worker `POST /api/transactions`
 - `7.Accounts/get consolidations` - Obtem o extrato da conta ordem de inserted_at desc `GET /api/accounts/:account_id/consolidations`
 - `8.Transactions/refund transaction` - Faz o extorno de uma trasação, dado o id dela `POST /api/transactions/:id/refund`

### Sobre a arquitetura da aplicação
Criamos uma estrutura pronta pensando em projetos manuteníveis baseando em arquitetura Ports and Adapters (Hexagonal), em detalhes.
  - `lib/cumbuca/context` - tem todas as funções principais e ações necessárias, bem como permissões e perfil exibições de dados para usuário autenticado ou não.
  - `lib/cumbuca/core` - tem todas as entidades e dentro de cada entidade a api para comunicação com o banco e quando necessário funções para esse tipo de conexao entidade-db, se encontrarão ali; também encontramos ali as validações mais inerentes a entidade e banco.
  - `lib/cumbuca/otp_core` - tem os modulos e funções relativos a concorrência.
  - `lib/cumbuca_web/controllers/api` - tem todas os controllers necessários bem como a definição de swagger para cada action(rota).
  - `lib/cumbuca_web/response.ex` - definições padrão de retorno de rota
  - `lib/cumbuca_web/status_message.ex` - definições das mensagens de retorno, viabilizando a internacionalização
  - `lib/cumbuca_web/auth.ex` - definição do Guardian
  - `test/cumbuca_web/controllers` - definição de testes dentro de escopos e isolados
  - `test/support/factory` - definição de schema de testes para facilitar os testes.
  - `insomnia.json` - definição de rotas no insomnia para facilitar os testes
  - `_docker` - definição das configurações do docker
  - `_scripts` - scripts úteis para utilização do docker

### Executar em ambiente de desenvolvimento.
Execute o seguinte comando no terminal na raiz do projeto.
`$ _scripts/dev.sh`

Após entrar no bash do container, execute o seguinte comando no terminal:
`$ iex -S mix phx.server`

Para acessar o swagger navegue até:
 `http://localhost:4001/swagger`

### Executando em cloud
  accesse  `https://cloud.h2sistemas.com.br`
  NOTA: O swagger não está habilitado neste ambiente

### Bibliotecas de terceiros utilizadas
- [phoenix framework](https://hexdocs.pm/phoenix)
| Framework base para aplicação
- [mix-test.watch](https://hexdocs.pm/mix_test_watch)
| re-executa os testes quando existe modificação em arquivos
- [credo](https://hexdocs.pm/credo)
| análise estática de código
- [bee](https://hexdocs.pm/bee)
| cria uma api de entidades menos verbosa através do Ecto.
- [phoenix_swagger](https://github.com/andridus/phoenix_swagger)
| gera o swagger das apis (fork andridus com implementacao do swagger via @doc)
- [happy](https://github.com/vic/happy)
| cria um fluxo de operações com facil gestão de erros
- [brcpfcnpj](https://hexdocs.pm/brcpfcnpj)
| manipula cpf e cnpj com validações e outras funções úteis
- [guardian](https://hexdocs.pm/guardian)
| autenticação de usuário


### Talvez Coisas a fazer no swagger (em outro momento)
 - [ ] swagger devolver lista de objetos na resposta
 - [ ] swagger oneOf para as permissões