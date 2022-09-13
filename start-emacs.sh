#!/bin/bash

export PORT_OFFSET=$1
if [ -z $PORT_OFFSET ];
then
   export PORT_OFFSET=0
fi;

export RSTUDIO_PORT=$(expr $PORT_OFFSET + 8787)
export D3_PORT=$(expr $PORT_OFFSET + 8888)

echo $PORT_OFFSET
   
docker build . --build-arg linux_user_pwd="$(cat .password)" -t ashar
xhost +SI:localuser:$(whoami) 
docker run -p $D3_PORT:8888 \
       -p $RSTUDIO_PORT:8787 \
       -v /home/toups/.emacs.d:/home/rstudio/.emacs.d \
       -v /home/toups/.emacs-trash:/home/rstudio/.emacs-trash \
       -v $(pwd):/home/rstudio/work \
       --user rstudio \
       --workdir /home/rstudio/work\
       -e DISPLAY=:0\
       -v /tmp/.X11-unix/X0:/tmp/.X11-unix/X0\
       -v $HOME/.Xauthority:/home/rstudio/.Xauthority\
       --cpus=6.5\
       -it ashar\
       emacs /home/rstudio/work

echo RSTUDIO on $RSTUDIO_PORT
echo EXTRA   on $D3_PORT

