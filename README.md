# Cumbuca

Desafio aceito: [link para o desafio](https://github.com/appcumbuca/desafios/blob/master/desafio-back-end.md)

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
- [bee](https://github.com/andridus/mix-test.watch)
| Cria uma interface menos verbosa através do Ecto.
