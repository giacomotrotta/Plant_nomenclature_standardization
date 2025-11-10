FROM rocker/r-ver:4.4.1

# 1) Librerie di sistema necessarie per compilare pacchetti R (curl, ssl, xml, ecc.)
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libgit2-dev \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# 2) Installa plumber per primo (fondamentale)
RUN R -e "install.packages('plumber', repos='https://cloud.r-project.org')"

# 3) Installa gli altri pacchetti necessari
RUN R -e \"install.packages(c('TNRS','dplyr','stringr','jsonlite'), repos='https://cloud.r-project.org')\"

# 4) Cartella di lavoro
WORKDIR /app

# 5) Copia api.R nel container
COPY api.R /app/api.R

# 6) Espone la porta usata da plumber
EXPOSE 8000

# 7) Comando di avvio: lancia l'API
CMD [\"R\", \"-e\", \"pr <- plumber::pr('api.R'); pr$run(host='0.0.0.0', port=8000)\"]

