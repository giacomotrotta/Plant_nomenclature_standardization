FROM rocker/r-ver:4.4.1

# Installa i pacchetti necessari
RUN R -e "install.packages(c('plumber','TNRS','dplyr','stringr','jsonlite'), repos='https://cloud.r-project.org')"

# Imposta la cartella di lavoro
WORKDIR /app

# Copia l'API dentro il container
COPY api.R /app/api.R

# Espone la porta usata da plumber
EXPOSE 8000

# Comando di avvio: lancia l'API plumber
CMD ["R", "-e", "pr <- plumber::pr('api.R'); pr$run(host='0.0.0.0', port=8000)"]
