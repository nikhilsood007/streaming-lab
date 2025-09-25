FROM bluenviron/mediamtx:latest

# Copy your MediaMTX config
COPY config/mediamtx.yml /mediamtx.yml

# Expose all the ports we need
EXPOSE 1935 8554 8888 8889 9998

# Start MediaMTX
CMD ["/mediamtx"]
