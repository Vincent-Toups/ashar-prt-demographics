FROM rocker/verse
ARG linux_user_pwd
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN apt update \
    && apt install -y software-properties-common \
    && add-apt-repository ppa:kelleyk/emacs \
    && DEBIAN_FRONTEND=noninteractive apt update \
    && DEBIAN_FRONTEND=noninteractive apt install -y emacs28 python3-pip sqlite3 lighttpd x11-apps \
    && echo "rstudio:$linux_user_pwd" | chpasswd
RUN pip3 install beautifulsoup4 theano tensorflow keras scikit-learn pandas numpy pandasql dfply plotnine matplotlib seaborn hy jupyter jupyterlab bokeh jupyter_bokeh
RUN Rscript --no-restore --no-save -e "install.packages(c('reticulate', 'GGally', 'gbm', 'r2d3', 'plumber', 'verification', 'svglite','gtools','infotheo'))"
RUN Rscript --no-restore --no-save -e "remotes::install_github('eddelbuettel/rcppcorels')"
RUN Rscript --no-restore --no-save -e "tinytex::tlmgr_install(c(\"wrapfig\",\"ec\",\"ulem\",\"amsmath\",\"capt-of\"))"
RUN Rscript --no-restore --no-save -e "tinytex::tlmgr_install(c(\"hyperref\",\"iftex\",\"pdftexcmds\",\"infwarerr\"))"
RUN Rscript --no-restore --no-save -e "tinytex::tlmgr_install(c(\"kvoptions\",\"epstopdf\",\"epstopdf-pkg\"))"
RUN Rscript --no-restore --no-save -e "tinytex::tlmgr_install(c(\"hanging\",\"grfext\"))"
RUN Rscript --no-restore --no-save -e "tinytex::tlmgr_install(c(\"etoolbox\",\"xcolor\",\"geometry\"))"
RUN pip3 install jupyter jupyterlab bokeh jupyter_bokeh
RUN Rscript --no-restore --no-save -e "install.packages(c(\"plumber\"))"
RUN Rscript --no-restore --no-save -e "install.packages(c(\"verification\"))"
