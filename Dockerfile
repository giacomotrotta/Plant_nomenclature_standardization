FROM rocker/r-ver:4.4.1

RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libgit2-dev \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

RUN R -e "install.packages('plumber', repos='https://cloud.r-project.org')"

RUN R -e "install.packages(c('TNRS','dplyr','stringr','jsonlite'), repos='https://cloud.r-project.org')"

WORKDIR /app

COPY api.R /app/api.R

EXPOSE 8000

CMD ["R", "-e", "pr <- plumber::pr('api.R'); pr$run(host='0.0.0.0', port=8000)"]
