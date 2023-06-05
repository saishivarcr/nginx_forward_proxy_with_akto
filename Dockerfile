FROM ubuntu:22.04

WORKDIR /app

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y libfontconfig1 libpcre3 libpcre3-dev git dpkg-dev libpng-dev libssl-dev libxml2 libxslt-dev librdkafka-dev curl gnupg2 ca-certificates lsb-release ubuntu-keyring

RUN curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor \
    | tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null
RUN echo "deb-src [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] \
    http://nginx.org/packages/ubuntu `lsb_release -cs` nginx" \
    | tee /etc/apt/sources.list.d/nginx.list

RUN apt-get update && \
    apt-get source nginx && \
    git clone https://github.com/nginx/njs ngx_http_js_module && \
    git clone https://github.com/chobits/ngx_http_proxy_connect_module && \
    git clone https://github.com/kaltura/nginx-kafka-log-module.git && \
    cd /app/nginx-* && \
    patch -p1 < ../ngx_http_proxy_connect_module/patch/proxy_connect_rewrite_102101.patch && \
    cd /app/nginx-* && \
    ./configure --add-dynamic-module=/app/ngx_http_js_module/nginx --add-dynamic-module=/app/nginx-kafka-log-module --add-module=/app/ngx_http_proxy_connect_module --with-http_ssl_module \
      --with-http_stub_status_module --with-http_realip_module --with-threads && \
    make && \
    make install && \
    cp objs/nginx /usr/local/nginx/sbin/nginx

ADD https://raw.githubusercontent.com/akto-api-security/nginx-middleware/master/api_log.js /usr/local/nginx/njs/api_log.js

COPY nginx.conf /usr/local/nginx/conf/nginx.conf

EXPOSE 8888

CMD ["/usr/local/nginx/sbin/nginx"]
