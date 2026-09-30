# Arquitetura do Seedgen-jobs

O `seedgen-jobs` é um sistema de orquestração de vagas automatizado utilizando **n8n** como motor de fluxo e **PostgreSQL** como armazenamento estruturado de longo prazo.

## Fluxo de Dados (Data Pipeline)

O ciclo de vida de uma vaga no sistema é:
1. **Busca (Discovery):** Um workflow no n8n faz scrapping ou chama APIs de agregadores (RSS, GraphQL, REST).
2. **Normalização & Deduplicação:** A vaga recebe um hash. Se for única e não estiver no banco, ela entra como `NEW`.
3. **Análise de IA (Analyzer):** O n8n pega as vagas `NEW`, injeta o `profile.json` + `resume-master.md` + `job_description` em um prompt para a LLM (Gemini/OpenAI).
4. **Extração de Score:** A LLM retorna um JSON (com scores e compatibilidade).
5. **Classificação & Persistência:** O resultado é gravado na tabela `job_analysis`. Se o score estiver acima do `HIGH_SCORE`, o status vira `READY` ou `MATCHED`.
6. **Adaptação (Personalizer):** Gera-se um currículo Markdown focado na vaga.
7. **Notificação & Revisão (Human-in-the-loop):** O candidato recebe a notificação (via Telegram/Email) de que o pacote está pronto, e realiza a candidatura se desejar.

## Tabelas e Propósitos
- `jobs`: Armazena a vaga crua coletada.
- `job_analysis`: Armazena a inteligência e o match calculado pela IA.
- `candidate_profiles`: Dados base do candidato, para não precisar ler do disco todo momento no futuro (pode ser migrado do JSON).
- `applications`: Rastreamento da candidatura.

## Componentes Técnicos
- **Docker Compose:** Orquestra n8n e Postgres.
- **Node.js/N8N:** Toda lógica de polling e HTTP requests rodando em Nodes dentro do n8n.
- **Google Gemini API:** Utilizado pelo node HTTP Request (ou node LLM integrado) do n8n para classificar a vaga.
