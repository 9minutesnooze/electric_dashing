FROM ruby:2.2.3-onbuild
ENV LANG C.UTF-8
RUN apt-get update && apt-get install -y nodejs
USER root
RUN echo "America/New_York" > /etc/timezone && dpkg-reconfigure --frontend noninteractive tzdata
CMD ["dashing", "start", "-e", "production", "-p", "3030"]
