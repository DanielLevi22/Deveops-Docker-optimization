# Etapa de build: Usa a imagem leve node:current-alpine como base e nomeia essa etapa como "build"
# A otimização aqui vem do uso de multi-stage build, separando construção de execução
FROM node:20 AS build 
# Define o diretório de trabalho no contêiner para organizar os arquivos
WORKDIR /usr/src/app

# Copia apenas package.json e yarn.lock primeiro, aproveitando o cache do Docker
# Isso otimiza o processo, pois as dependências só são reinstaladas se esses arquivos mudarem
COPY package.json yarn.lock ./

# Instala todas as dependências (desenvolvimento e produção) necessárias para construir a aplicação

RUN yarn 

# Copia todo o código fonte para o contêiner
COPY . .

# Executa o comando de build (geralmente cria a pasta dist com a aplicação compilada)
# Essa etapa transforma o código em uma versão otimizada para produção
RUN yarn run build

# Reinstala apenas as dependências de produção, excluindo as de desenvolvimento
# --frozen-lockfile garante consistência e yarn cache clean reduz o tamanho da imagem
RUN yarn install --production --frozen-lockfile && yarn cache clean

# Etapa de produção: Usa uma nova imagem limpa node:current-alpine
# A otimização do multi-stage build entra aqui: só o necessário é levado para produção
FROM node:current-alpine 

# Define novamente o diretório de trabalho para a etapa de produção
WORKDIR /usr/src/app

COPY --from=build /usr/src/app/package.json ./

# Copia apenas os artefatos gerados (pasta dist) da etapa de build
# Isso mantém a imagem final leve, sem o código fonte ou ferramentas de build
COPY --from=build /usr/src/app/dist ./dist

# Copia apenas as dependências de produção da etapa de build
# Exclui dependências de desenvolvimento, otimizando tamanho e segurança
COPY --from=build /usr/src/app/node_modules ./node_modules

# Expõe a porta 3000 para acesso externo à aplicação
EXPOSE 3000

# Define o comando para iniciar a aplicação em modo produção
# O script "start" no package.json provavelmente roda a versão otimizada
CMD [ "yarn", "run", "start:prod" ]