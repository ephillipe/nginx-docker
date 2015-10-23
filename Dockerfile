FROM debian:jessie

MAINTAINER Erick Almeida <ephillipe@gmail.com>

# all the apt-gets in one command & delete the cache after installing

RUN apt-get update \
    && apt-get install -y cron supervisor logrotate \
       build-essential make libpcre3-dev libssl-dev wget \
       iputils-arping libexpat1-dev unzip curl libncurses5-dev libreadline-dev \
       perl htop \
    && apt-get -q -y clean 

ENV NGINX_VERSION 1.9.5
ENV LUA_VERSION 2.0
ENV LUA_NGINX_VERSION 0.9.16

ADD nginx-${NGINX_VERSION}.tar.gz  /tmp/
ADD luajit-${LUA_VERSION}.tar.gz  /tmp/
ADD lua-nginx-module-${LUA_NGINX_VERSION}.zip  /tmp/

# Build LuaJit and tell nginx's build system where to find LuaJIT 2.0:
RUN cd /tmp/luajit-${LUA_VERSION} \
    && make \
    && make PREFIX=/opt/luajit2 install \
    && export LUAJIT_LIB=/opt/luajit2/lib/ \
    && export LUAJIT_INC=/opt/luajit2/include/luajit-${LUA_VERSION}/
    
RUN gcc --version \ 
 && echo "Descompactando Módulo LUA para o NGINX" \
 && unzip -o /tmp/lua-nginx-module-${LUA_NGINX_VERSION}.zip
 && cd /tmp/nginx-${NGINX_VERSION}/ \ 
 && echo "Iniciando compilação do NGINX" \
 && ./configure --prefix=/etc/nginx \
                --sbin-path=/usr/sbin/nginx \
                --conf-path=/etc/nginx/nginx.conf \
                --pid-path=/var/run/nginx.pid \
                --with-ipv6 \
                --with-poll_module \
                --with-http_stub_status_module \
                --with-http_geoip_module \
                --with-http_realip_module \
                --with-http_ssl_module \
                --with-http_v2_module \
                --with-http_gzip_static_module \
                --with-openssl=/tmp/openssl-1.0.2d \
                --with-ld-opt='-Wl,-rpath,/opt/luajit2/lib/' \
                --add-module=/tmp/nginx-goodies-nginx-sticky-module-ng-c78b7dd79d0d/ \
                --add-module=/tmp/echo-nginx-module-0.57/ \
                --add-module=/tmp/ngx_devel_kit-master/ \
                --add-module=/tmp/lua-nginx-module-0.9.16/ \
                --add-module=/tmp/set-misc-nginx-module-0.28/
 && echo "Configuração do NGINX concluída" \
 && make \
 && make install \
 && rm -rf /tmp/nginx* \
 && rm -rf /tmp/lua-nginx-module*

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log
RUN ln -sf /dev/stderr /var/log/nginx/error.log

VOLUME ["/var/cache/nginx"]

CMD ["nginx", "-g", "daemon off;"]
