docker run -p 8999:8888 -v $(pwd):/home/rstudio/work --workdir /home/rstudio/work -d -t ashar make visualization
chromium-browser http://locahost:8888/demo-ae-vis.html
