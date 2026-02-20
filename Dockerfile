FROM rocker/verse:4.5.1

USER root

RUN apt-get update -y && apt-get install -y \
  gdal-bin \
  libgdal-dev \
  libgeos-dev \
  libproj-dev \
  libudunits2-dev \
  libcurl4-openssl-dev \
  libssl-dev \
  libxml2-dev \
  libicu-dev \
  libpng-dev \
  libsqlite3-dev \
  make pandoc zlib1g-dev \
  && rm -rf /var/lib/apt/lists/*

RUN R -e "install.packages(c('remotes','renv'), repos='https://cloud.r-project.org')"

WORKDIR /app
COPY . /app

RUN R -e "renv::restore(prompt = FALSE)"
RUN R -e "remotes::install_local('.', upgrade='never')"

EXPOSE 80
CMD R -e "options(shiny.port=80, shiny.host='0.0.0.0'); library(FloraExam); FloraExam::run_app()"
