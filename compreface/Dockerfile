FROM exadel/compreface:1.2.0
ENV PGDATA=/data/database
RUN apt-get update && apt-get install jq -y && rm -rf /var/lib/apt/lists/*
# Copy root filesystem
ADD --link rootfs /
CMD ["/run.sh"]
