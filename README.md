# 🎯 Seedgen-Jobs

<p align="center">
  <strong>Pipeline de automação end-to-end que busca vagas de emprego em APIs públicas, analisa compatibilidade com IA generativa, gera currículos otimizados para ATS e notifica o candidato — tudo no piloto automático.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white" />
  <img src="https://img.shields.io/badge/PostgreSQL_16-4169E1?style=for-the-badge&logo=postgresql&logoColor=white" />
  <img src="https://img.shields.io/badge/n8n-EA4B71?style=for-the-badge&logo=n8n&logoColor=white" />
  <img src="https://img.shields.io/badge/Google_Gemini-886FBF?style=for-the-badge&logo=googlegemini&logoColor=white" />
  <img src="https://img.shields.io/badge/JavaScript_ES6+-F7DF1E?style=for-the-badge&logo=javascript&logoColor=black" />
  <img src="https://img.shields.io/badge/Telegram_Bot-26A5E4?style=for-the-badge&logo=telegram&logoColor=white" />
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" />
</p>

---

## 🧩 Motivação e Problema

Candidatar-se a vagas de tecnologia é um processo **repetitivo e demorado**:

- Entrar em dezenas de sites de vagas todos os dias
- Ler cada descrição, avaliar se faz sentido para o seu perfil
- Adaptar o currículo para cada vaga (palavras-chave diferentes, ênfases diferentes)
- Formatar o currículo em DOCX ou PDF compatível com sistemas ATS
- Acompanhar o status de cada candidatura

O **Seedgen-Jobs** automatiza **todo esse ciclo**, desde a coleta até a geração do material de candidatura — deixando o candidato livre para focar em estudar, fazer projetos e se preparar para entrevistas.

---

## 📋 O que o sistema faz (Visão Geral)

```
  Fontes de Vagas          Pipeline de IA              Saída
  ══════════════          ══════════════              ═════
                                                        
  ┌──────────┐     ┌────────────────────┐     ┌──────────────┐
  │ Remotive │────▶│  1. Coleta + Hash  │────▶│  PostgreSQL  │
  │   API    │     │  (Deduplicação)    │     │  (6 tabelas) │
  └──────────┘     └────────┬───────────┘     └──────┬───────┘
                            │                        │
  ┌──────────┐              │                        ▼
  │Arbeitnow │──────────────┘               ┌──────────────┐
  │   API    │                              │  2. Análise   │
  └──────────┘                              │  Gemini AI    │
                                            │  (Score 0-100)│
  ┌──────────┐                              └──────┬───────┘
  │ Futuras  │                                     │
  │ Fontes   │─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─(extensível)  ▼
  └──────────┘                              ┌──────────────┐
                                            │ 3. Otimizador│
                                            │    ATS       │
                                            │ (4 chamadas) │
                                            └──────┬───────┘
                                                   │
                              ┌─────────────┬──────┴──────┐
                              ▼             ▼             ▼
                        ┌──────────┐  ┌──────────┐  ┌──────────┐
                        │ Currículo│  │ Telegram  │  │Dashboard │
                        │ MD/DOCX  │  │  Alerta   │  │  HTML    │
                        └──────────┘  └──────────┘  └──────────┘
```

---

## 🧠 Como o Pipeline de IA funciona (Detalhado)

O coração do sistema é o **workflow `09_ats_optimizer`**, que executa uma **cadeia de 4 chamadas sequenciais** à API do Google Gemini. Cada etapa recebe o output da anterior, criando um raciocínio progressivo:

### Etapa 1 — Keyword Extractor
A IA recebe a **descrição completa da vaga** e extrai todas as palavras-chave técnicas, classificando-as em 3 níveis:
- **MANDATORY** — Skills obrigatórias (ex: "Java", "Spring Boot")
- **IMPORTANT** — Skills desejáveis (ex: "Docker", "CI/CD")
- **OPTIONAL** — Diferenciais (ex: "Kubernetes", "AWS")

### Etapa 2 — Keyword Matching
A IA recebe as keywords extraídas **+ o perfil real do candidato** (`profile.json`) e faz o cruzamento honesto:
- Quais skills o candidato **tem** → `matched_keywords`
- Quais skills o candidato **não tem** → `missing_keywords`
- Calcula o `ats_keyword_score` (% de cobertura)

> ⚠️ A IA é instruída a **nunca inventar skills** que não estão no perfil — garantindo que o currículo gerado seja verdadeiro.

### Etapa 3 — ATS Optimizer
Com base no cruzamento, a IA gera:
- Um **resumo profissional adaptado** (3-5 linhas) focado nas keywords que o candidato realmente possui
- Um **título de cargo adaptado** para a vaga
- **Instruções** para reorganizar as seções do currículo

### Etapa 4 — Resume Generator
A IA gera o **currículo completo em Markdown** seguindo boas práticas de ATS:
- Formato limpo sem tabelas, colunas ou gráficos (que sistemas ATS não leem)
- Keywords estrategicamente posicionadas no resumo, competências e projetos
- Validação anti-alucinação: verifica se não houve repetição excessiva ou skills inventadas

### Pós-geração
Após a IA gerar o Markdown, o sistema:
1. **Salva o arquivo `.md`** na pasta `generated/resumes/`
2. **Converte para `.docx`** usando `marked.js` + `html-docx-js`
3. **Converte para `.pdf`** usando `markdown-pdf`
4. **Envia notificação no Telegram** informando que o material está pronto

---

## 🗄️ Modelo de Dados (PostgreSQL)

O banco foi modelado para representar todo o **ciclo de vida** de uma vaga — desde a coleta até a candidatura:

```sql
-- 1. Vagas coletadas (dados brutos normalizados)
jobs
├── id, source, external_id, title, company
├── location, remote_type, salary, description, url
├── published_at, collected_at
├── hash (SHA-256 para deduplicação)
└── status (NEW → ANALYZED → MATCHED → APPLIED)

-- 2. Inteligência calculada pela IA
job_analysis
├── job_id (FK → jobs)
├── overall_score (0-100)
├── skill_match, missing_skills (JSONB)
├── seniority, location_match, education_match
└── explanation, recommendation_reason

-- 3. Análise de otimização ATS
ats_analysis
├── job_id (FK → jobs)
├── job_title_adapted, ats_keyword_score
├── keyword_coverage, required_keyword_coverage
├── matched_keywords, missing_keywords (JSONB)
└── validation_passed (boolean)

-- 4. Rastreamento de candidaturas
applications
├── job_id (FK → jobs)
├── status (REVIEW → APPLIED → INTERVIEW → OFFER)
├── resume_version, cover_letter, notes
└── date_applied

-- 5. Perfil do candidato (cache do JSON)
candidate_profiles
├── user_id (FK → users)
└── profile_data (JSONB)

-- 6. Logs de execução dos workflows
automation_runs
├── workflow_name, status
├── jobs_processed, new_jobs_found, ai_requests_made
└── errors, started_at, completed_at
```

### Decisões de design:
- **`hash` com `UNIQUE` constraint** na tabela `jobs` → garante deduplicação sem lógica extra na aplicação. Se a mesma vaga for coletada duas vezes, o `INSERT ... ON CONFLICT (hash) DO NOTHING` silenciosamente ignora
- **JSONB** para `skill_match`, `missing_skills`, `matched_keywords` → permite consultas flexíveis sem precisar de tabelas de junção
- **`ON DELETE CASCADE`** em `job_analysis` e `ats_analysis` → se uma vaga for removida, toda a inteligência associada é limpa automaticamente

---

## 🔧 Workflows n8n (Detalhado)

O sistema é composto por **10 workflows** que operam de forma modular — cada um com uma responsabilidade única:

### `01_job_discovery` — Coleta de Vagas
**Trigger:** Cron (a cada 4 horas)

Consulta duas APIs REST públicas em paralelo:
- **Remotive API** (`remotive.com/api/remote-jobs`) — vagas remotas globais de software
- **Arbeitnow API** (`arbeitnow.com/api/job-board-api`) — vagas da Europa com filtro remoto

Cada vaga passa por um **Adapter Pattern**: um node de código JavaScript normaliza os campos de diferentes formatos para um schema único, gera um hash SHA-256 para deduplicação, e insere no PostgreSQL com `ON CONFLICT DO NOTHING`.

### `02_job_analyzer` — Análise com IA
**Trigger:** Webhook (disparado pelo workflow 01 ou manualmente)

Puxa vagas com status `NEW` do banco, injeta a descrição + `profile.json` + `resume-master.md` em um prompt estruturado para o Google Gemini, e extrai um JSON com scores de compatibilidade em múltiplas dimensões (backend, frontend, fullstack, estágio). O resultado é persistido na tabela `job_analysis`.

### `03_resume_personalizer` — Currículo Customizado
**Trigger:** Webhook

Recebe o ID de uma vaga, busca a análise + perfil do candidato, e solicita ao Gemini que gere um currículo Markdown focado nas competências relevantes para aquela vaga específica. O output é salvo na pasta `generated/resumes/`.

### `04_message_generator` — Mensagem de Candidatura
**Trigger:** Webhook

Gera uma mensagem personalizada de apresentação para acompanhar a candidatura — com tom profissional, mencionando as competências mais relevantes para a vaga e demonstrando conhecimento sobre a empresa.

### `05_notification` — Alertas Telegram
**Trigger:** Webhook (disparado automaticamente quando score > threshold)

Envia uma notificação formatada no Telegram com:
- Nome da empresa e cargo
- Localização e tipo (remoto/presencial)
- Score de compatibilidade
- Link direto para a vaga

Após notificar, atualiza o status da vaga para `REVIEW`.

### `06_application_tracker` — Rastreamento
**Trigger:** Manual

Registra na tabela `applications` quando uma candidatura foi efetivamente enviada, com a versão do currículo utilizada e notas do candidato.

### `07_daily_report` — Relatório Matinal
**Trigger:** Cron (diário às 08:30)

Agrega estatísticas das últimas 24 horas diretamente do PostgreSQL e envia um resumo no Telegram:
- Quantas vagas novas foram coletadas
- Quantas tiveram match alto (>80%)
- Link para abrir o dashboard

### `08_dashboard_api` + `08b_dashboard_jobs` — API do Dashboard
**Trigger:** Webhook

Dois endpoints REST que o dashboard HTML consome via `fetch()`:
- `/dashboard-api` → retorna métricas agregadas (total de vagas, matches, candidaturas)
- `/dashboard-jobs` → retorna as 15 vagas mais recentes com seus status

### `09_ats_optimizer` — Pipeline ATS Completo
**Trigger:** Webhook

O workflow mais complexo do sistema — encadeia **4 chamadas sequenciais à IA** (detalhado na seção "Como o Pipeline de IA funciona") + validação + geração de arquivos + notificação.

---

## 🖥️ Dashboard

O dashboard é uma **single-page application** em HTML/CSS/JS puro (sem frameworks) com design **dark mode premium**:

- **5 cards de métricas** com animação numérica (contagem progressiva) e gradientes
- **Tabela de vagas** com badges coloridos por status (NEW, MATCHED, REVIEW)
- **Auto-refresh** a cada 60 segundos
- **Fallback gracioso** — quando o n8n não está rodando, exibe dados alternativos em vez de quebrar
- **Design responsivo** — funciona em desktop e mobile
- **Background animado** com gradientes radiais sutis

Tecnicamente, o dashboard faz `fetch()` para os webhooks do n8n (`/dashboard-api` e `/dashboard-jobs`) e renderiza os dados dinamicamente com manipulação de DOM.

---

## 🚀 Início Rápido

### Pré-requisitos
- [Docker](https://www.docker.com/) & Docker Compose instalados
- [Google Gemini API Key](https://aistudio.google.com/apikey) (gratuita, basta uma conta Google)
- (Opcional) [Bot do Telegram](https://core.telegram.org/bots#botfather) para receber notificações no celular

### 1. Clone o repositório
```bash
git clone https://github.com/BatistaSec/seedgen-jobs.git
cd seedgen-jobs
```

### 2. Configure as variáveis de ambiente
```bash
cp .env.example .env
```

Edite o arquivo `.env` com suas credenciais:
```env
# Obrigatório — cérebro do sistema
AI_API_KEY=sua_chave_gemini_aqui

# Opcional — notificações no celular
TELEGRAM_BOT_TOKEN=seu_bot_token
TELEGRAM_CHAT_ID=seu_chat_id

# Configurações de score (ajuste conforme seu perfil)
MIN_SCORE=70    # Score mínimo para considerar uma vaga
HIGH_SCORE=85   # Score para disparo automático do ATS Optimizer
```

### 3. Personalize seu perfil (⚠️ obrigatório)

A pasta `candidate/` vem com dados de **exemplo**. Você precisa substituir com os seus dados reais para que a IA gere currículos baseados no **seu** perfil:

| Arquivo | O que editar |
|---|---|
| `candidate/profile.json` | Suas skills, formação, certificações e links |
| `candidate/resume-master.md` | Seu currículo completo em Markdown (base para a IA) |
| `candidate/projects.json` | Seus projetos com tecnologias e destaques |

> **💡 Dica:** Quanto mais detalhado e honesto for o seu perfil, melhor a IA vai adaptar o currículo para cada vaga. Não invente skills — o sistema foi projetado para trabalhar apenas com o que você realmente sabe.

### 4. Suba a infraestrutura
```bash
docker-compose up -d
```

Isso levanta dois containers:
| Container | Porta | Função |
|---|---|---|
| `seedgen_postgres` | 5432 | Banco de dados com schema pronto |
| `seedgen_n8n` | 5678 | Motor de automação |

### 5. Configure o n8n (apenas na primeira vez)
1. Acesse **http://localhost:5678** no navegador
2. Crie seu usuário de acesso local
3. Vá em **Workflows → Import** e importe os 10 arquivos JSON da pasta `n8n/workflows/`
4. Em **Credentials**, configure a conexão PostgreSQL (os dados estão no seu `.env`)
5. Em cada workflow, clique no toggle **Active** (canto superior direito) para ativar

### 6. Abra o Dashboard
Abra `dashboard/index.html` diretamente no navegador para acompanhar as vagas em tempo real.

### 7. Piloto automático
Pronto! Você pode **fechar o terminal e o navegador**. O Docker mantém tudo rodando em background. O sistema vai:
- Buscar vagas a cada 4 horas automaticamente
- Analisar com IA e calcular score
- Gerar currículo se o match for alto
- Notificar no Telegram quando tiver material pronto

Para parar temporariamente: `docker-compose stop`
Para retomar: `docker-compose start`

---

## 📁 Estrutura do Projeto

```
seedgen-jobs/
│
├── candidate/                  # 👤 Dados do candidato (⚠️ EDITE COM SEUS DADOS)
│   ├── profile.json            #    Template: substitua com suas skills, formação e links
│   ├── projects.json           #    Template: substitua com seus projetos e tecnologias
│   └── resume-master.md        #    Template: substitua com seu currículo em Markdown
│
├── dashboard/                  # 📊 Interface visual
│   └── index.html              #    SPA com dark mode, métricas animadas, tabela de vagas
│
├── database/                   # 🗄️ Persistência
│   └── init.sql                #    DDL completo: 6 tabelas com FKs, constraints, JSONB
│
├── docs/                       # 📖 Documentação técnica
│   ├── ARCHITECTURE.md         #    Fluxo de dados, decisões de design, componentes
│   └── RUNBOOK.md              #    Guia operacional: como rodar, parar, monitorar
│
├── generated/                  # 📄 Artefatos gerados pela IA (gitignored)
│   ├── resumes/                #    Currículos personalizados (MD, DOCX, PDF)
│   └── messages/               #    Mensagens de candidatura geradas
│
├── n8n/                        # ⚙️ Motor de automação
│   ├── workflows/              #    10 workflows JSON exportados
│   │   ├── 01_job_discovery    #    Coleta + normalização + dedup
│   │   ├── 02_job_analyzer     #    Análise de compatibilidade (Gemini)
│   │   ├── 03_resume_pers...   #    Geração de currículo customizado
│   │   ├── 04_message_gen...   #    Geração de mensagem de candidatura
│   │   ├── 05_notification     #    Alertas Telegram
│   │   ├── 06_application...   #    Tracker de candidaturas
│   │   ├── 07_daily_report     #    Relatório matinal automático
│   │   ├── 08_dashboard_api    #    API de métricas para o dashboard
│   │   ├── 08b_dashboard_jobs  #    API de lista de vagas
│   │   └── 09_ats_optimizer    #    Pipeline ATS completo (4 etapas de IA)
│   └── credentials/            #    Credenciais do n8n (gitignored)
│
├── scripts/                    # 🔧 Utilitários Node.js
│   ├── generate_docx.js        #    Conversor Markdown → DOCX (marked + html-docx-js)
│   ├── generate_pdf.js         #    Conversor Markdown → PDF (markdown-pdf)
│   ├── mock_sources.js         #    Dados mock para testes locais
│   └── package.json            #    Dependências dos scripts
│
├── docker-compose.yml          # 🐳 Orquestração: PostgreSQL 16 + n8n
├── .env.example                # 🔐 Template de variáveis de ambiente
├── .gitignore                  # 🚫 Protege .env, node_modules, credenciais
└── LICENSE                     # 📝 MIT
```

---

## 🛡️ Segurança

| Prática | Implementação |
|---|---|
| Gestão de segredos | Todas as credenciais em `.env` (nunca no código) |
| Git seguro | `.env`, scripts de fix e credenciais no `.gitignore` |
| Workflows seguros | Referenciam variáveis via `{{$env.VAR}}` do n8n |
| Banco de dados | Healthcheck ativo, credenciais isoladas por variável |
| n8n | Autenticação básica obrigatória (`N8N_BASIC_AUTH_ACTIVE=true`) |
| Anti-alucinação | Prompts instruem a IA a nunca inventar skills |

---

## 🛠️ Stack Tecnológica

| Camada | Tecnologia | Por quê? |
|---|---|---|
| Containerização | Docker + Docker Compose | Infraestrutura reproduzível em qualquer máquina |
| Banco de dados | PostgreSQL 16 Alpine | Robusto, suporta JSONB, constraints, ACID |
| Automação | n8n (self-hosted) | Visual, extensível, suporta cron/webhook/HTTP |
| IA Generativa | Google Gemini API | Gratuita, rápida, boa para extração e geração de texto |
| Frontend | HTML5 + CSS3 + JS vanilla | Leve, sem dependências, dark mode nativo |
| Notificações | Telegram Bot API | Instantâneo, gratuito, funciona no celular |
| Geração de docs | Marked.js + html-docx-js | Conversão Markdown → HTML → DOCX em Node.js |
| Deduplicação | SHA-256 hash | Garantia matemática de unicidade |

---

## 🔮 Roadmap (Próximas Melhorias)

- [ ] Adicionar mais fontes de vagas (LinkedIn API, Indeed, Glassdoor)
- [ ] Implementar geração real de PDF com templates visuais
- [ ] Adicionar testes automatizados nos workflows
- [ ] Criar versão web do dashboard com autenticação
- [ ] Implementar análise de tendências (skills mais pedidas por período)
- [ ] Suporte a múltiplos perfis de candidato

---

## 📝 Licença

Distribuído sob a licença MIT. Veja [LICENSE](LICENSE) para detalhes.

---

<p align="center">
  Feito com ❤️ por <a href="https://github.com/BatistaSec">João Batista</a>
</p>
