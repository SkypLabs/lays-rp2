#FROM docker.io/resin/raspberrypi2-debian:jessie
FROM docker.io/debian:jessie
MAINTAINER skyper@skyplabs.net

EXPOSE 80

RUN apt-get update \
	&& apt-get install -y git \
	&& apt-get install -y python3 python3-pip python3-dev python-virtualenv \
	&& apt-get install -y uwsgi uwsgi-plugin-python3 nginx \
	&& apt-get install -y npm \
	&& npm install -g bower \
	&& useradd -m dev

COPY config/nginx.conf /etc/nginx/nginx.conf
COPY config/sites-available/lays /etc/nginx/sites-available/
COPY config/apps-available/lays.ini /etc/uwsgi/apps-available/

RUN rm -f /etc/nginx/sites-enabled/default \
	&& ln -s /etc/nginx/sites-available/lays /etc/nginx/sites-enabled/ \
	&& ln -s /etc/uwsgi/apps-available/lays.ini /etc/uwsgi/apps-enabled/ \
	&& ln -s $(which nodejs) /usr/local/bin/node

RUN git clone https://github.com/SkypLabs/lays-webapp.git /var/www/html/lays-webapp \
	&& chown -R www-data:www-data /var/www/html/lays-webapp

WORKDIR /var/www/html/lays-webapp
RUN git checkout -b bower origin/bower
RUN bower install --allow-root
USER dev
RUN ["/bin/bash", "-c", "virtualenv /home/dev/virtualenv-lays -p python3 && source /home/dev/virtualenv-lays/bin/activate && pip install -r /var/www/html/lays-webapp/requirements.txt && deactivate"]

USER root
CMD ["/bin/bash", "-c", "/etc/init.d/uwsgi start && /usr/sbin/nginx || /usr/sbin/nginx"]
