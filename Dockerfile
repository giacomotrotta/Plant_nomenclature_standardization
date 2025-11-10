FROM rocker/plumber:latest

# Librerie di sistema aggiuntive se servono per i pacchetti
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

# Installa i pacchetti R necessari oltre a plumber (già presente)
RUN R -e "install.packages(c('TNRS','dplyr','stringr','jsonlite'), repos='https://cloud.r-project.org')"

WORKDIR /app

COPY api.R /app/api.R

EXPOSE 8000

CMD ["R", "-e", "pr <- plumber::pr('api.R'); pr$run(host='0.0.0.0', port=8000)"]
