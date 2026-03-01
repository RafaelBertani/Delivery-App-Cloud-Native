# Delivery-App-Cloud-Native

<image-card alt="Node.js" src="https://img.shields.io/badge/Node.js-20.x-green" ></image-card>
<image-card alt="Docker" src="https://img.shields.io/badge/Docker-✓-blue" ></image-card>
<image-card alt="Kubernetes" src="https://img.shields.io/badge/Kubernetes-✓-326CE5" ></image-card>
<image-card alt="PostgreSQL" src="https://img.shields.io/badge/PostgreSQL-16-blue" ></image-card>
<image-card alt="RabbitMQ" src="https://img.shields.io/badge/RabbitMQ-3-orange" ></image-card>
<image-card alt="React" src="https://img.shields.io/badge/React-%2320232a.svg?logo=react&logoColor=%2361DAFB" ></image-card>
<image-card alt="Flutter" src="https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white" ></image-card>

Microserviços • Docker Swarm + Kubernetes • PostgreSQL • RabbitMQ • React + Flutter

## Índice

- [Visão Geral da Arquitetura](#visão-geral-da-arquitetura)
- [Tecnologias Utilizadas e Decisões de Arquitetura](#tecnologias-utilizadas)
- [Estrutura de Pastas](#estrutura-de-pastas)
- [Como Rodar o Projeto](#como-rodar-o-projeto)
- [To-Do List / Próximos Passos](#to-do-list--próximos-passos--evolução-do-projeto)
- [Demonstração](#demonstração--projeto-em-execução)
- [Diagramas UML](#diagramas-uml)
- [Modelo de Dados](#modelo-de-dados-diagrama-er)

Projeto de **aplicativo de delivery cloud-native**, desenvolvido com foco em **arquitetura moderna**, **escalabilidade**, **segurança** e **boas práticas de engenharia de software**, simulando um cenário real de produção utilizado por empresas de médio e grande porte.

O sistema foi projetado utilizando **microserviços**, **comunicação assíncrona**, **containerização**, **orquestração**, **automação de infraestrutura** e **validações robustas**, cobrindo desde backend até frontend web e mobile.

---

## Visão Geral da Arquitetura

O projeto segue uma **arquitetura de microserviços desacoplados**, cada um com responsabilidade bem definida, comunicando-se de forma **assíncrona** via **mensageria**.

### Microserviços Backend
- **auth-service** → autenticação, autorização e emissão de JWT
- **restaurant-service** → gestão de restaurantes e cardápios
- **order-service** → criação e acompanhamento de pedidos

Cada serviço segue o padrão **MVC**, com:
- Controllers (camada HTTP)
- Services (regras de negócio)
- Models (acesso a dados)

---

## Tecnologias Utilizadas

### Backend
- Node.js
- JWT (JSON Web Token)
- Joi (validação de dados)
- PostgreSQL
- RabbitMQ
- Docker
- Docker Swarm
- Kubernetes

### Frontend
- React + Vite (Web)
- Flutter (Mobile)
- Bootstrap

### Infraestrutura & DevOps
- Docker Swarm Secrets
- Kubernetes Deployments e Services
- Bash Scripts para automação
- Init SQL para versionamento do banco

### Health Checks (Liveness & Readiness)
Cada serviço expõe o endpoint GET /health que valida:

- O status do processo.

- Uptime: Tempo de atividade do processo.

---

## Estrutura de Pastas

```text
backend/
 ├── auth-service/
 ├── restaurant-service/
 └── order-service/

front-apps/
 ├── web_react/
 └── mobile_flutter/

infra/
 ├── bin/
 │   ├── create-db.sh
 │   └── create-secrets.sh
 │
 ├── db/
 │   └── init.sql
 │
 ├── k8s/
 │   ├── apps/
 │   │   ├── auth-deployment.yaml
 │   │   ├── restaurant-deployment.yaml
 │   │   ├── order-deployment.yaml
 │   │   └── frontends.yaml
 │   │
 │   ├── infrastructure/
 │   │   ├── postgres-deployment.yaml
 │   │   └── rabbitmq-deployment.yaml
 │   │
 │   ├── configmap.yaml
 │   ├── ingress.yaml
 │   ├── namespace.yaml
 │   ├── secret.yaml
 │
 └── scripts/
     ├── build-images.sh
     ├── deploy.sh
     ├── cleanup.sh
     └── monitor.sh
```

## Segurança e Autenticação

- Autenticação baseada em JWT  
- Tokens stateless, facilitando escalabilidade horizontal  
- Secrets armazenados via Docker Swarm Secrets  
- Nenhuma credencial sensível versionada no código  

### Benefício empresarial:

- Escalabilidade  
- Segurança  
- Compatibilidade com múltiplos clientes (Web e Mobile)  

---

## Por que RabbitMQ e não Kafka?

A escolha do RabbitMQ foi feita considerando o escopo do projeto e o tipo de problema resolvido.

### RabbitMQ

- Ideal para eventos de negócio  
- Fácil de operar  
- Baixa latência  
- Excelente para orquestração de workflows  
- Menor custo operacional  

### Kafka

- Mais indicado para streaming de grandes volumes de dados  
- Overhead e complexidade maiores  
- Desnecessário para este cenário transacional  

### Decisão técnica

RabbitMQ atende melhor aplicações de delivery, onde confiabilidade, simplicidade e consistência são prioritárias.

---

## Por que Microserviços?

- Escalabilidade independente por domínio  
- Isolamento de falhas  
- Facilidade de manutenção  
- Evolução contínua do sistema  

Microserviços não foram escolhidos por moda, mas para demonstrar domínio arquitetural e simular ambientes reais de produção.

---

## Por que PostgreSQL (Banco Relacional)?

- Consistência ACID  
- Relacionamentos bem definidos  
- Integridade dos dados  
- Ampla adoção no mercado  

Aplicações de delivery exigem transações confiáveis, algo fundamental em bancos relacionais.

---

## Validação de Dados

- Uso do Joi para validação de dados de entrada  
- Evita dados inválidos no sistema  
- Reduz falhas em produção  
- Garante previsibilidade das APIs  

---

## Automação e DevOps

Scripts Bash automatizam:

- Criação do banco de dados  
- Criação de secrets  
- Build das imagens Docker  
- Deploy em Docker Swarm e Kubernetes  
- Monitoramento dos serviços  

### Objetivo

Reduzir erro humano e garantir reprodutibilidade do ambiente.

---

## Docker Swarm e Kubernetes

- Docker Swarm: simplicidade e secrets nativos  
- Kubernetes: padrão de mercado, escalabilidade e alta disponibilidade  

O projeto suporta ambos, demonstrando flexibilidade e entendimento de ambientes reais.

## Como Rodar o Projeto

O projeto possui **scripts Bash** para automatizar todo o ciclo de build, deploy, monitoramento e encerramento da aplicação, reduzindo erros manuais e facilitando a execução em ambientes reais.

> **Pré-requisitos**
> - Docker instalado
> - Docker Swarm inicializado (`docker swarm init`)
> - Bash (Linux / WSL / macOS)
> - Portas necessárias liberadas

---

# Passo a passo para subir o ambiente

### 1️⃣ Build das imagens Docker

Responsável por construir todas as imagens dos microserviços e frontends.

```
bash infra/scripts/build-images.sh
```

### 2️⃣ Criação dos Secrets (primeira execução)
Cria os Docker Swarm Secrets utilizados pelos serviços (credenciais, JWT secret, etc).
Bashbash infra/bin/create-secrets.sh

- ⚠️ Importante (primeira vez):

Altere as senhas genéricas fornecidas no script para valores seguros da sua máquina
Ajuste também o arquivo docker-compose.yml nas variáveis:YAMLRABBITMQ_DEFAULT_USER
RABBITMQ_DEFAULT_PASS

📌 Motivo do ajuste:
Devido a um bug ainda não resolvido envolvendo leitura de arquivos de configuração e inicialização do RabbitMQ.
(explicação detalhada do bug)

### 3️⃣ Deploy da aplicação
Realiza o deploy completo da infraestrutura e dos serviços no Docker Swarm / Kubernetes (dependendo da configuração).
```bash
bash infra/scripts/deploy.sh
```

> Esse script:

> - Sobe banco de dados
> - Sobe RabbitMQ
> - Publica microserviços
> - Publica frontends


### 4️⃣ Monitoramento (opcional)
Permite acompanhar o estado dos serviços durante e após o deploy.
```bash
bash infra/scripts/monitor.sh
```
> Útil para:

> - Verificar containers
> - Diagnosticar falhas
> - Acompanhar inicialização dos serviços


### 5️⃣ Encerrar a execução (cleanup)
Remove serviços, containers e recursos criados durante o deploy.
```bash
bash infra/scripts/cleanup.sh
```
> Recomendado para:

> - Finalizar testes
> - Limpar ambiente
> - Evitar consumo desnecessário de recursos


# To-Do List / Próximos Passos - Evolução do Projeto

Roadmap com foco em **escalabilidade**, **experiência do usuário** e **cenários reais de produção**

## Fundações & Correções Críticas

1. **Corrigir bug de inicialização do RabbitMQ**  
   - Problema atual: exige configuração manual no docker-compose.yml  
   - Meta: ler 100% das configurações via arquivos + Docker Secrets  
   - Impacto: elimina workarounds, facilita CI/CD, ambientes múltiplos 

## Prioridade Média-Alta - Segurança & Experiência do Usuário

3. **Autenticação e Recuperação de Conta**  
   - [ ] Login social (Google, Apple, Facebook?)  
   - [ ] Fluxo de recuperação de senha via e-mail  
     - Token temporário com expiração (ex: 15–30 min)  
     - Template de e-mail bonito e seguro  
   - [ ] Rate limiting no envio de e-mails de recuperação  
   - [ ] Auditoria de segurança (tabela de tokens, invalidação após uso)

4. **Sistema de Pagamentos**  
  - [ ] Integração com Stripe em modo Test (Sandbox)

## Prioridade Média – Features de Valor Percebido Alto

5. **Funcionalidades de Localização (GPS) – MVP**  
   - [ ] Mapa em tempo real no app do cliente  
     - Posição do entregador (já possui a latitude e longitude na tabela)
     - Posição estimada do restaurante → cliente  
   - [ ] Exibição de rota (polyline)  
   - [ ] Status visual do pedido (preparando, a caminho, entregue)  
   - Decisão técnica inicial:  
     - OpenStreetMap + Leaflet (grátis)  
     - ou Google Maps SDK (custo x qualidade)  

6. **Carrinho Multi-Restaurante**  
   - [ ] Permitir itens de múltiplos restaurantes no mesmo carrinho  
   - [ ] Regras de negócio a definir:  
     - Uma taxa de entrega única ou por restaurante?  
     - Checkout gera 1 pedido ou N pedidos vinculados?  
     - Como fica status e rastreamento?  

## Backlog - Melhorias & Otimizações Futuras

- Dark mode / temas no frontend  
- Internacionalização (i18n) – pelo menos pt-BR + en-US

# Demonstração - Projeto em Execução

Aqui estão algumas telas do sistema rodando:

[3–5 imagens aqui com <img> ou GitHub markdown]

# Diagramas UML

<img src="./docs/astahUML/Sequence-Diagram-Login.png" width="800" alt="Diagrama UML - Sequence">
Diagrama de sequência - login

<img src="./docs/astahUML/Sequence-Diagram-Order.png" width="800" alt="Diagrama UML - Sequence">
Diagrama de sequência - criar pedido

<img src="./docs/astahUML/Sequence-Diagram-CreateNewRestaurant.png" width="800" alt="Diagrama UML - Sequence">
Diagrama de sequência - cadastrar restaurante

<img src="./docs/astahUML/Sequence Diagram - Login.asta" width="800" alt="Diagrama UML - Deployment">
Diagrama de implementação/deploy

# Modelo de Dados (Diagrama ER)

<img src="./docs/db/ERD.png" width="700" alt="Diagrama Entidade-Relacionamento">
Principais entidades e relacionamentos implementados no PostgreSQL.
