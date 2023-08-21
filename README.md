# Cumbuca

Desafio aceito: [link para o desafio](https://github.com/appcumbuca/desafios/blob/master/desafio-back-end.md)

## Checklist
- [x] Cadastro de conta
- [x] Atualização de senha de acessoa a conta
- [x] Autenticação
- [ ] Atualização de senha de transacao da conta
- [ ] Cadastro de Transação
- [ ] Estorno de Transação
- [ ] Busca de Transações por data
- [ ] Visualização de Saldo

## Regras de Negócio
- [ ] Não deve ser possível forjar um token de autenticação. Os tokens devem identificar de forma única o usuário logado.
- [ ] Uma transação só deve ser realizada caso haja saldo suficiente na conta do usuário para realizá-la.
- [ ] Após a realização de uma transação, a conta do usuário enviante deve ter seu valor descontado do valor da transação e a do usuário recebedor acrescentada do valor da transação.
- [ ] Todas as transações realizadas devem ser registradas no banco de dados.
- [ ] Caso todas as transações no banco de dados sejam realizadas novamente a partir do estado inicial de todas as contas, os saldos devem equivaler aos saldos expostos na interface. Em outros termos: Para toda conta, se somarmos os valores de todas as transações no histórico dela a qualquer momento, o saldo total da conta deve ser o saldo atual.
- [ ] Uma transação só pode ser estornada uma vez.

### Algumas explicações
Utilizamos uma biblioteca própria (Bee), desenvolvida com o propósito de facilitar o uso do Ecto para as funções de CRUD mais comuns como Insert, Update, Delete e Get.

Dessa maneira, ao invés de utilizarmos `Repo.get(Account, id)`, utilizamos `Account.Api.get(id)`. Essa melhoria de leiturabilidade e manutenibilidade fornecida pela biblioteca Bee tem custo zero e evita.

Utilizamos uma fork da biblioteca phoenix_swagger, em que implementamos uma forma otimize a leiturabilidade quando aplicada sobre as actions e somente então utilizar o comportamento esperado da biblioteca e gerar o swagger.

### Executar em ambiente de desenvolvimento.
Execute o seguinte comando no terminal na raiz do projeto.
`$ _scripts/dev.sh`

Após entrar no bash do container, execute o seguinte comando no terminal:
`$ iex -S mix phx.server`

Para acessar o swagger navegue até:
`http://localhost:4001/swagger`

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


## Coisas a fazer
 - [ ] swagger devolver lista de objetos na resposta
 - [ ] swagger oneOf para as permissões