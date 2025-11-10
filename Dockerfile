FROM rocker/r-ver:4.4.1

RUN install.packages(c(
    "plumber",
    "TNRS",
    "dplyr",
    "stringr",
    "jsonlite"
))

WORKDIR /app
COPY api.R /app/api.R

EXPOSE 8000

CMD ["R", "-e", "pr <- plumber::pr('api.R'); pr$run(host='0.0.0.0', port=8000)"]
