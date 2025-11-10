FROM rocker/r-ver:4.4.1

# Installa le librerie di sistema necessarie
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

# Installa i pacchetti R
RUN R -e "install.packages(c('plumber','TNRS','dplyr','stringr','jsonlite'), repos='https://cloud.r-project.org')"

# Imposta la cartella di lavoro
WORKDIR /app

# Copia il file dell'API
COPY api.R /app/api.R

# Espone la porta usata da plumber
EXPOSE 8000

# Comando di avvio
CMD ["R", "-e", "pr <- plumber::pr('api.R'); pr$run(host='0.0.0.0', port=8000)"]
