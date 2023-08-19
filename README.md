# Cumbuca

Desafio aceito: [link para o desafio](https://github.com/appcumbuca/desafios/blob/master/desafio-back-end.md)

## Checklist
- [ ] Cadastro de conta
- [ ] Autenticação
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

### Executar a aplicação em ambiente de desenvolvimento,
Execute o seguinte comando no terminal na raiz do projeto.
`$ _scripts/dev.sh`

Após entrar no bash do container, execute o seguinte comando no terminal :
`$ iex -S mix phx.server`

Para acessar o swagger navegue até:
`http://localhost:4001/swagger`

### Bibliotecas de terceiro utilizadas
- [phoenix framework](https://www.phoenixframework.org/)
| Framework base para aplicação
- [mix-test.watch](https://github.com/lpil/mix-test.watch)
| re-executa os testes quando existe modificação em arquivos
- [credo](https://github.com/lpil/mix-test.watch)
| análise estática de código
- [bee](https://github.com/andridus/mix-test.watch)
| Cria uma api de entidades menos verbosa através do Ecto.
