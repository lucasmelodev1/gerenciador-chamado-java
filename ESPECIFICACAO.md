# Ferramentas de IA usadas
Estou usando Opencode como Harness e usando puramente o DeepSeek V4.1 Flash como modelo.
Uso skills de autoração minha para que eu tenha maior controle sobre o que é gerado. Eu conheço 
melhor os limites do que minha IA consegue e não consegue fazer.

# Sugestões de IA aceitas
Nenhuma, eu não aceito sugestão de IA, toda decisão arquitetônica é feita por mim. A decisão da
IA se limita a escrever o código seguindo todas as minhas regras.

# Como validei conteúdo e código gerados
Cada iteração de funcionalidade e bugfix é isolada em um commit no git, e eu checo as diffs de 
todos os arquivos. Como as mudanças são pequenas e pontuais, isso não cria um gargalo de review.

# Quais decisões de negócio, segurança, escopo e aceite não foram delegadas à IA
Todas, mas eu vou listando por aqui todas as decisões que tomei.
- Manter campos de tempo de criação e tempo de deleção (pouco código agora, essencial pra auditoria)
- Utilizar TEXT ao invés de VARCHAR (recomendado pela própria documentação oficial do POSTGRESQL)
- Utilizar TEXT ao invés de enums (maior flexibilidade, checagem feita a nível de aplicação)

# Interações relevantes
1. Utilizei a IA para identificar padrões de nomenclatura e projeto na camada de banco de dados, 
especificamente para saber o padrão de escrita (camelCase, snake_case, etc) usado em enumeradores 
no formato string na camada do BD, e saber se havia algum tipo de soft delete aplicado com Hibernate.
2. IA quis mapear `deleted_at` como campo na classe da Area, mas o Hibernate já faz isso na sua versão 
mais nova. Jogando essa responsabilidade pra o Hibernate, temos menos área de superfície pra bugs.
3. IA quis usar H2 como banco de dados para executar os testes E2E, mesmo sem nenhuma mencao sobre. 
Como eu entendi a visao sobre os testes serem reprodutivos em multiplos ambientes, eu dei um upgrade na 
arquitetura de testes usando o proprio `docker compose` como motor para replicar o ambiente e utilizar o 
BD por la.
