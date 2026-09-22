# runtime = imagen final (prod). stamp = etapa que “construye” ficheros.
FROM alpine:3.20 AS stamp
WORKDIR /src
COPY site/ .
RUN echo "construido en el build" > build-info.txt

FROM nginx:1.27-alpine AS runtime
COPY --from=stamp /src /usr/share/nginx/html
