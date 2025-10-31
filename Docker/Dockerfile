## Build generic Syncrosim image
FROM ubuntu:24.04 AS base

## Specify time zone for mono install
ENV TZ=Canada/Eastern
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

## Install required libraries
RUN apt-get update
RUN apt-get install -y unzip mono-complete curl dos2unix

## Install syncrosim package-specific dependencies
RUN apt-get install -y \
    libgdal-dev \
    libgeos-dev \
    libproj-dev \
    libudunits2-dev \
    libsqlite3-dev \
    libssl-dev \
    libcurl4-openssl-dev \
    libxml2-dev 

## Download and install Conda
RUN curl "https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh" -o Miniconda3-latest-Linux-x86_64.sh \
    && mkdir /root/.conda \
    && bash Miniconda3-latest-Linux-x86_64.sh -b \
    && rm -f Miniconda3-latest-Linux-x86_64.sh
ENV PATH="/root/miniconda3/bin:${PATH}"

## Remove default channels to avoid anaconda terms of service updates
RUN conda config --remove channels defaults
RUN rm /root/miniconda3/.condarc

## Add conda-forge channel
RUN conda config --add channels conda-forge
RUN conda config --set channel_priority strict

## Create prioritizr conda environment from environment file
COPY src/prioritizrEnv.yml /tmp/prioritizrEnv.yml
RUN conda env create -f /tmp/prioritizrEnv.yml

## Activate the environment
ENV CONDA_DEFAULT_ENV=prioritizrEnv-3-0-0
ENV PATH="/root/miniconda3/envs/prioritizrEnv-3-0-0/bin:${PATH}"

## Install additional R packages that need source compilation
## These are installed via R because they need specific versions
RUN Rscript -e "install.packages('terra', repos='http://cran.us.r-project.org', type='source')"
RUN Rscript -e "install.packages(c('assertthat', 'slam', 'RcppArmadillo','codetools','BiocManager'), repos='http://cran.us.r-project.org', type='source')"
RUN Rscript -e "install.packages('https://cran.r-project.org/src/contrib/Archive/prioritizr/prioritizr_8.0.4.tar.gz', repos=NULL, type='source')"
RUN Rscript -e "install.packages('https://cran.r-project.org/src/contrib/symphony_0.1.1.tar.gz', repos=NULL, type='source')"
RUN Rscript -e "BiocManager::install('lpsymphony')"


## Add SyncroSim license files
COPY Docker/ModelRunService_license_file.lic /home

## Add prioritzr for testing
COPY Docker/prioritizr.ssimpkg /home
COPY Docker/spatial-formulation.ssim.ssimbak /home

## Run the app
# CMD ["node", "main.js"]
CMD ["/bin/bash"]
