FROM nginx:1.27.2-alpine

COPY build/dist/awefull-pizza-shop/browser /usr/share/nginx/html
COPY build/nginx.conf /etc/nginx/nginx.conf
COPY build/app1.tiweb.tp.ubik.academy.crt /etc/nginx/app1.tiweb.tp.ubik.academy.crt
COPY build/app1.tiweb.tp.ubik.academy.key /etc/nginx/app1.tiweb.tp.ubik.academy.key
