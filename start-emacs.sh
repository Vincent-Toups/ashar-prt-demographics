#!/bin/bash

PORT_OFFSET=0

# Define the command line options using the "getopt" command
OPTIONS=o:h
LONGOPTIONS=port-offset:,help

# Parse the command line options
PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTIONS --name "$0" -- "$@")

# Check for invalid options
if [ $? -ne 0 ]; then
    exit 1
fi

# Set the command line options
eval set -- "$PARSED"

# Process the command line options
while true; do
    case "$1" in
        -o|--port-offset)
            PORT_OFFSET="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $(basename $0) [--port-offset PORT_OFFSET]"
            exit 0
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Invalid option: $1" >&2
            exit 1
            ;;
    esac
done

RSTUDIO_PORT=$(expr $PORT_OFFSET + 8787)
D3_PORT=$(expr $PORT_OFFSET + 8888)

echo $PORT_OFFSET

docker build . --build-arg linux_user_pwd="$(cat .password)" -t ashar
xhost +SI:localuser:$(whoami) 
docker run -p $D3_PORT:8888 \
       -h ashar-prt-docker-container\
       -p $RSTUDIO_PORT:8787 \
       -v $HOME/emacs-local/:/home/rstudio/emacs-local/ \
       -v $HOME/.emacs.d:/home/rstudio/.emacs.d \
       -v $HOME/.emacs-trash:/home/rstudio/.emacs-trash \
       -v $(pwd):/home/rstudio/work \
       -v $HOME/Downloads:/home/rstudio/Downloads \
       --user rstudio \
       --workdir /home/rstudio/work \
       -e DISPLAY=:0 \
       -v /tmp/.X11-unix/X0:/tmp/.X11-unix/X0 \
       -v $HOME/.Xauthority:/home/rstudio/.Xauthority \
       --cpus=6.5 \
       -it ashar \
       emacs /home/rstudio/work

echo RSTUDIO on $RSTUDIO_PORT
echo EXTRA   on $D3_PORT
