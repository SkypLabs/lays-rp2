#FROM docker.io/resin/raspberrypi2-debian:jessie
FROM docker.io/debian:jessie
MAINTAINER skyper@skyplabs.net

RUN apt-get update \
	&& apt-get install -y git \
	&& apt-get install -y python3 python3-pip python3-dev python-virtualenv \
	&& apt-get install -y uwsgi uwsgi-plugin-python3 nginx \
	&& useradd -m dev

COPY config/nginx.conf /etc/nginx/nginx.conf
COPY config/sites-available/lays /etc/nginx/sites-available/
COPY config/apps-available/lays.ini /etc/uwsgi/apps-available/

RUN rm -f /etc/nginx/sites-enabled/default \
	&& ln -s /etc/nginx/sites-available/lays /etc/nginx/sites-enabled/ \
	&& ln -s /etc/uwsgi/apps-available/lays.ini /etc/uwsgi/apps-enabled/

WORKDIR /var/www/html

RUN git clone https://github.com/SkypLabs/lays-webapp.git \
	&& chown -R www-data:www-data lays-webapp

USER dev

RUN ["/bin/bash", "-c", "virtualenv /home/dev/virtualenv-lays -p python3 && source /home/dev/virtualenv-lays/bin/activate && pip install -r /var/www/html/lays-webapp/requirements.txt && deactivate"]

USER root

EXPOSE 80
CMD ["/bin/bash", "-c", "/etc/init.d/uwsgi start && /usr/sbin/nginx || /usr/sbin/nginx"]
