#!/bin/bash

# Stop Stream Script
# Usage: ./stop_stream.sh [signal]
# Examples:
#   ./stop_stream.sh          # Graceful stop (SIGTERM)
#   ./stop_stream.sh KILL     # Force kill (SIGKILL)
#   ./stop_stream.sh INT      # Interrupt (SIGINT)

set -e

SIGNAL=${1:-TERM}
PID_FILE="logs/ffmpeg.pid"

echo "=== FFmpeg Stream Stopper ==="
echo "Signal: SIG$SIGNAL"
echo "=========================="

# Function to stop by PID file
stop_by_pid_file() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        echo "Found PID file with PID: $pid"
        
        if kill -0 "$pid" 2>/dev/null; then
            echo "Stopping FFmpeg process $pid with SIG$SIGNAL..."
            kill -$SIGNAL "$pid"
            
            # Wait for graceful shutdown (up to 10 seconds)
            if [ "$SIGNAL" = "TERM" ] || [ "$SIGNAL" = "INT" ]; then
                local count=0
                while kill -0 "$pid" 2>/dev/null && [ $count -lt 10 ]; do
                    echo "Waiting for graceful shutdown... ($((count+1))/10)"
                    sleep 1
                    count=$((count+1))
                done
                
                # Force kill if still running
                if kill -0 "$pid" 2>/dev/null; then
                    echo "Process still running, force killing..."
                    kill -KILL "$pid" 2>/dev/null || true
                fi
            fi
            
            # Verify process is stopped
            if ! kill -0 "$pid" 2>/dev/null; then
                echo "Process $pid stopped successfully"
                rm -f "$PID_FILE"
                return 0
            else
                echo "Error: Process $pid is still running"
                return 1
            fi
        else
            echo "Process $pid is not running (stale PID file)"
            rm -f "$PID_FILE"
            return 0
        fi
    else
        echo "No PID file found at $PID_FILE"
        return 1
    fi
}

# Function to stop all FFmpeg processes
stop_all_ffmpeg() {
    echo "Searching for all FFmpeg processes..."
    local pids=$(pgrep -f "ffmpeg.*rtmp" 2>/dev/null || true)
    
    if [ -n "$pids" ]; then
        echo "Found FFmpeg RTMP processes: $pids"
        for pid in $pids; do
            echo "Stopping process $pid with SIG$SIGNAL..."
            kill -$SIGNAL "$pid" 2>/dev/null || true
        done
        
        # Wait for graceful shutdown
        if [ "$SIGNAL" = "TERM" ] || [ "$SIGNAL" = "INT" ]; then
            sleep 2
            # Force kill any remaining processes
            local remaining=$(pgrep -f "ffmpeg.*rtmp" 2>/dev/null || true)
            if [ -n "$remaining" ]; then
                echo "Force killing remaining processes: $remaining"
                for pid in $remaining; do
                    kill -KILL "$pid" 2>/dev/null || true
                done
            fi
        fi
        
        # Clean up PID file
        rm -f "$PID_FILE"
        echo "All FFmpeg processes stopped"
        return 0
    else
        echo "No FFmpeg RTMP processes found"
        return 1
    fi
}

# Function to show process status
show_status() {
    echo "=== Process Status ==="
    
    # Check PID file
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        echo "PID file exists: $pid"
        if kill -0 "$pid" 2>/dev/null; then
            echo "Process $pid is running"
            ps -p "$pid" -o pid,ppid,cmd 2>/dev/null || true
        else
            echo "Process $pid is not running (stale PID file)"
        fi
    else
        echo "No PID file found"
    fi
    
    echo
    echo "All FFmpeg RTMP processes:"
    ps aux | grep -E "ffmpeg.*rtmp" | grep -v grep || echo "No FFmpeg RTMP processes found"
}

# Main execution
case "$1" in
    "status"|"show"|"list")
        show_status
        ;;
    "all"|"ALL")
        stop_all_ffmpeg
        ;;
    *)
        # Try PID file first, then fall back to all processes
        if ! stop_by_pid_file; then
            echo "Falling back to stopping all FFmpeg processes..."
            stop_all_ffmpeg
        fi
        ;;
esac

echo "Done."