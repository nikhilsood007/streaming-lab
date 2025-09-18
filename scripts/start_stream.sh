#!/bin/bash

# Start Stream Script
# Usage: ./start_stream.sh [duration] [stream_key] [input_source]
# Examples:
#   ./start_stream.sh 300 live/stream testsrc     # 5 minute test pattern
#   ./start_stream.sh 0 live/stream input.mp4     # Continuous from file
#   ./start_stream.sh 60 test/demo webcam         # 1 minute from webcam

set -e

# Default values
DURATION=${1:-0}          # 0 = infinite, >0 = seconds
STREAM_KEY=${2:-live/stream}
INPUT_SOURCE=${3:-testsrc}
RTMP_URL=${RTMP_URL:-rtmp://localhost:1935}
BITRATE=${BITRATE:-1000k}
FPS=${FPS:-30}
RESOLUTION=${RESOLUTION:-1280x720}

# Create logs directory
mkdir -p logs

# Function to generate test pattern
generate_test_pattern() {
    echo "Starting test pattern stream..."
    if [ "$DURATION" -eq 0 ]; then
        ffmpeg -f lavfi -i testsrc=duration=0:size=${RESOLUTION}:rate=${FPS} \
               -f lavfi -i sine=frequency=1000:duration=0 \
               -c:v libx264 -preset veryfast -b:v $BITRATE -maxrate $BITRATE -bufsize $(echo $BITRATE | sed 's/k/*2k/g' | bc) \
               -pix_fmt yuv420p -g $(($FPS * 2)) -keyint_min $FPS -sc_threshold 0 \
               -c:a aac -b:a 128k -ac 2 -ar 44100 \
               -f flv ${RTMP_URL}/${STREAM_KEY} \
               2>&1 | tee logs/stream_$(date +%Y%m%d_%H%M%S).log &
    else
        ffmpeg -f lavfi -i testsrc=duration=${DURATION}:size=${RESOLUTION}:rate=${FPS} \
               -f lavfi -i sine=frequency=1000:duration=${DURATION} \
               -c:v libx264 -preset veryfast -b:v $BITRATE -maxrate $BITRATE -bufsize $(echo $BITRATE | sed 's/k/*2k/g' | bc) \
               -pix_fmt yuv420p -g $(($FPS * 2)) -keyint_min $FPS -sc_threshold 0 \
               -c:a aac -b:a 128k -ac 2 -ar 44100 \
               -f flv ${RTMP_URL}/${STREAM_KEY} \
               2>&1 | tee logs/stream_$(date +%Y%m%d_%H%M%S).log &
    fi
}

# Function to stream from file
stream_from_file() {
    local input_file=$1
    echo "Starting stream from file: $input_file"
    
    if [ ! -f "$input_file" ]; then
        echo "Error: Input file '$input_file' not found!"
        echo "Available files in ./media/:"
        ls -la ./media/ 2>/dev/null || echo "No media directory found"
        exit 1
    fi
    
    if [ "$DURATION" -eq 0 ]; then
        ffmpeg -re -stream_loop -1 -i "$input_file" \
               -c:v libx264 -preset veryfast -b:v $BITRATE -maxrate $BITRATE -bufsize $(echo $BITRATE | sed 's/k/*2k/g' | bc) \
               -pix_fmt yuv420p -g $(($FPS * 2)) -keyint_min $FPS -sc_threshold 0 \
               -c:a aac -b:a 128k -ac 2 -ar 44100 \
               -f flv ${RTMP_URL}/${STREAM_KEY} \
               2>&1 | tee logs/stream_$(date +%Y%m%d_%H%M%S).log &
    else
        ffmpeg -re -t $DURATION -i "$input_file" \
               -c:v libx264 -preset veryfast -b:v $BITRATE -maxrate $BITRATE -bufsize $(echo $BITRATE | sed 's/k/*2k/g' | bc) \
               -pix_fmt yuv420p -g $(($FPS * 2)) -keyint_min $FPS -sc_threshold 0 \
               -c:a aac -b:a 128k -ac 2 -ar 44100 \
               -f flv ${RTMP_URL}/${STREAM_KEY} \
               2>&1 | tee logs/stream_$(date +%Y%m%d_%H%M%S).log &
    fi
}

# Function to stream from webcam (Linux/macOS)
stream_from_webcam() {
    echo "Starting webcam stream..."
    
    # Linux (v4l2)
    if command -v v4l2-ctl &> /dev/null; then
        if [ "$DURATION" -eq 0 ]; then
            ffmpeg -f v4l2 -i /dev/video0 -f alsa -i default \
                   -c:v libx264 -preset veryfast -b:v $BITRATE -maxrate $BITRATE -bufsize $(echo $BITRATE | sed 's/k/*2k/g' | bc) \
                   -pix_fmt yuv420p -s $RESOLUTION -r $FPS \
                   -c:a aac -b:a 128k -ac 2 -ar 44100 \
                   -f flv ${RTMP_URL}/${STREAM_KEY} \
                   2>&1 | tee logs/stream_$(date +%Y%m%d_%H%M%S).log &
        else
            ffmpeg -t $DURATION -f v4l2 -i /dev/video0 -f alsa -i default \
                   -c:v libx264 -preset veryfast -b:v $BITRATE -maxrate $BITRATE -bufsize $(echo $BITRATE | sed 's/k/*2k/g' | bc) \
                   -pix_fmt yuv420p -s $RESOLUTION -r $FPS \
                   -c:a aac -b:a 128k -ac 2 -ar 44100 \
                   -f flv ${RTMP_URL}/${STREAM_KEY} \
                   2>&1 | tee logs/stream_$(date +%Y%m%d_%H%M%S).log &
        fi
    # macOS (AVFoundation)
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        if [ "$DURATION" -eq 0 ]; then
            ffmpeg -f avfoundation -i "0:0" \
                   -c:v libx264 -preset veryfast -b:v $BITRATE -maxrate $BITRATE -bufsize $(echo $BITRATE | sed 's/k/*2k/g' | bc) \
                   -pix_fmt yuv420p -s $RESOLUTION -r $FPS \
                   -c:a aac -b:a 128k -ac 2 -ar 44100 \
                   -f flv ${RTMP_URL}/${STREAM_KEY} \
                   2>&1 | tee logs/stream_$(date +%Y%m%d_%H%M%S).log &
        else
            ffmpeg -t $DURATION -f avfoundation -i "0:0" \
                   -c:v libx264 -preset veryfast -b:v $BITRATE -maxrate $BITRATE -bufsize $(echo $BITRATE | sed 's/k/*2k/g' | bc) \
                   -pix_fmt yuv420p -s $RESOLUTION -r $FPS \
                   -c:a aac -b:a 128k -ac 2 -ar 44100 \
                   -f flv ${RTMP_URL}/${STREAM_KEY} \
                   2>&1 | tee logs/stream_$(date +%Y%m%d_%H%M%S).log &
        fi
    else
        echo "Webcam streaming not supported on this platform"
        echo "Falling back to test pattern..."
        generate_test_pattern
        return
    fi
}

# Main execution logic
echo "=== FFmpeg Stream Starter ==="
echo "Duration: $([[ $DURATION -eq 0 ]] && echo "Continuous" || echo "${DURATION}s")"
echo "Stream Key: $STREAM_KEY"
echo "Input Source: $INPUT_SOURCE"
echo "RTMP URL: $RTMP_URL"
echo "Bitrate: $BITRATE"
echo "Resolution: $RESOLUTION"
echo "FPS: $FPS"
echo "=========================="

case "$INPUT_SOURCE" in
    "testsrc"|"test")
        generate_test_pattern
        ;;
    "webcam"|"camera")
        stream_from_webcam
        ;;
    *.mp4|*.mkv|*.avi|*.mov)
        # Check if it's a relative path, prepend media directory
        if [[ ! "$INPUT_SOURCE" == /* ]]; then
            INPUT_SOURCE="./media/$INPUT_SOURCE"
        fi
        stream_from_file "$INPUT_SOURCE"
        ;;
    *)
        # Assume it's a file path
        stream_from_file "$INPUT_SOURCE"
        ;;
esac

# Store PID for stop script
FFMPEG_PID=$!
echo $FFMPEG_PID > logs/ffmpeg.pid
echo "FFmpeg started with PID: $FFMPEG_PID"
echo "Stream should be available at: $RTMP_URL/$STREAM_KEY"
echo "Log file: logs/stream_$(date +%Y%m%d_%H%M%S).log"
echo "To stop: ./stop_stream.sh or kill $FFMPEG_PID"

# Wait a moment to check if FFmpeg started successfully
sleep 2
if ! kill -0 $FFMPEG_PID 2>/dev/null; then
    echo "Error: FFmpeg failed to start. Check the log file for details."
    exit 1
fi

echo "Stream is running..."