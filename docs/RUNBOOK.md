# 🚀 Guia Prático: Piloto Automático (Seedgen-Jobs)

Este guia mostra como deixar o seu caçador de vagas rodando **100% no automático** (background). Você pode minimizar tudo, jogar, trabalhar, ou até sair de casa, e o sistema continuará buscando e adaptando currículos silenciosamente.

---

## Passo 1: Garantir que o Motor está ligado (Docker)
Como você usou o comando `docker-compose up -d`, os containers do Banco de Dados e do n8n já estão rodando em "modo daemon" (background). 
*   **Você pode fechar o terminal.** Isso mesmo, pode fechar a janela preta do prompt. O Docker Desktop vai manter os serviços ligados nos bastidores.
*   Se o seu PC reiniciar, basta abrir o terminal na pasta do projeto e rodar `docker-compose up -d` novamente.

## Passo 2: Configurar o n8n (Apenas a 1ª vez)
1.  Abra o navegador e acesse: **[http://localhost:5678](http://localhost:5678)**
2.  Crie seu usuário de acesso local (é apenas para você).
3.  No menu lateral esquerdo, vá em **Workflows**.
4.  Clique no botão de engrenagem ou "Import" no canto superior direito e importe os arquivos JSON que estão na sua pasta `n8n/workflows/` (importar o *01_job_discovery*, o *09_ats_optimizer*, o *07_daily_report*, etc).
5.  Em **Credentials** (no menu lateral), garanta que você criou as credenciais da **API do Gemini** e do **Telegram** (se houver nós que peçam credencial, o n8n vai te avisar com um triângulo amarelo).

## Passo 3: Ligar a Automação (O Botão Mágico)
Dentro de cada workflow importado, no canto superior direito existe uma **chave seletora (Toggle)** escrito `Active`.
*   Mude a chave de **Inativo (Cinza)** para **Ativo (Verde)**.
*   Faça isso principalmente nos workflows que começam com **Cron Trigger** (Agendadores) ou **Webhook**.

## Passo 4: Vida Normal
**Pronto! É só isso.**
Você pode fechar o navegador (`localhost:5678`). 

### O que vai acontecer agora?
1. O cron configurado no n8n (por exemplo, a cada X horas) vai "acordar" sozinho.
2. Ele vai bater nas fontes de vagas e achar novas oportunidades.
3. Se o Match for bom (>70), o *09_ats_optimizer* vai disparar silenciosamente.
4. A IA do Gemini será chamada por trás dos panos. Ela vai analisar a vaga, cruzar com o seu perfil, e gerar o currículo (MD, DOCX e PDF).
5. O seu celular (Telegram) vai apitar com a notificação: *"Currículo pronto para a vaga X"*.
6. Você pode estar no meio de um jogo ou no supermercado. O trabalho manual de estruturar currículo e ler a vaga já foi feito!

### Dica de Ouro
Quer desligar o robô temporariamente (para economizar recursos ou parar de receber vagas)?
Basta abrir o terminal e digitar:
`docker-compose stop`

Para voltar:
`docker-compose start`
