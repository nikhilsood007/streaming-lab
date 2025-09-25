FROM bluenviron/mediamtx:latest

# MediaMTX will use built-in configuration

# Expose ports
EXPOSE 1935 8554 8888 8889 9998

# Start MediaMTX with default config
CMD ["/mediamtx"]
