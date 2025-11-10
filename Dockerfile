FROM rocker/r-ver:4.4.1

# 1) Librerie di sistema necessarie
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libgit2-dev \
    build-essential \
    libsodium-dev \
    && rm -rf /var/lib/apt/lists/*

# 2) Installa sodium (dipendenza necessaria per plumber)
RUN R -e "install.packages('sodium', repos='https://cloud.r-project.org')"

# 3) Installa plumber e gli altri pacchetti
RUN R -e "install.packages(c('plumber','TNRS','dplyr','stringr','jsonlite'), repos='https://cloud.r-project.org')"

# 4) Cartella di lavoro
WORKDIR /app

# 5) Copia l'API
COPY api.R /app/api.R

# 6) Espone la porta usata da plumber
EXPOSE 8000

# 7) Comando di avvio
CMD ["R", "-e", "pr <- plumber::pr('api.R'); pr$run(host='0.0.0.0', port=8000)"]
