#!/bin/bash

clear

# === Configuration ===
APP_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )" # Get script's directory
FRONTEND_DIR="$APP_DIR/frontend"
BACKEND_DIR="$APP_DIR/backend"
FRONTEND_PID_FILE="$APP_DIR/.frontend.pid"
BACKEND_PID_FILE="$APP_DIR/.backend.pid"
FRONTEND_LOG_FILE="$APP_DIR/frontend.log"
BACKEND_LOG_FILE="$APP_DIR/backend.log"
FRONTEND_START_CMD="npm start" # Or yarn start
BACKEND_START_CMD="npm start"  # Or yarn start / node src/index.js

# === Helper Functions ===

# Function to check if a process is running based on PID file
is_running() {
    local pid_file=$1
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if ps -p $pid > /dev/null 2>&1; then
            return 0 # Process is running
        else
            # Process not running, but PID file exists (stale)
            echo "Warning: Stale PID file found: $pid_file"
            rm -f "$pid_file"
            return 1 # Process is not running
        fi
    else
        return 1 # Process is not running (no PID file)
    fi
}

# Function to start the backend
start_backend() {
    if is_running "$BACKEND_PID_FILE"; then
        echo "Backend is already running (PID $(cat $BACKEND_PID_FILE))."
        return 0
    fi

    echo "Starting Backend..."
    cd "$BACKEND_DIR" || { echo "Error: Could not cd into $BACKEND_DIR"; exit 1; }

    # Check for node_modules
    if [ ! -d "node_modules" ]; then
       echo "Warning: node_modules not found in $BACKEND_DIR. Running 'npm install'..."
       npm install || { echo "Error: npm install failed for backend."; exit 1; }
    fi

    # Start backend in the background using nohup, redirect output, and save PID
    nohup $BACKEND_START_CMD > "$BACKEND_LOG_FILE" 2>&1 &
    local pid=$!
    echo $pid > "$BACKEND_PID_FILE"
    cd "$APP_DIR" || exit 1 # Go back to the main app directory

    # Small delay to check if it started successfully (optional but good)
    sleep 2
    if is_running "$BACKEND_PID_FILE"; then
        echo "Backend started successfully (PID $pid). Logs: $BACKEND_LOG_FILE"
    else
        echo "Error: Backend failed to start. Check logs: $BACKEND_LOG_FILE"
        rm -f "$BACKEND_PID_FILE" # Clean up pid file if start failed
        return 1
    fi
    return 0
}

# Function to start the frontend
start_frontend() {
    if is_running "$FRONTEND_PID_FILE"; then
        echo "Frontend is already running (PID $(cat $FRONTEND_PID_FILE))."
        return 0
    fi

    echo "Starting Frontend..."
    cd "$FRONTEND_DIR" || { echo "Error: Could not cd into $FRONTEND_DIR"; exit 1; }

    # Check for node_modules
    if [ ! -d "node_modules" ]; then
       echo "Warning: node_modules not found in $FRONTEND_DIR. Running 'npm install'..."
       npm install || { echo "Error: npm install failed for frontend."; exit 1; }
    fi

    # Start frontend in the background using nohup, redirect output, and save PID
    nohup $FRONTEND_START_CMD > "$FRONTEND_LOG_FILE" 2>&1 &
    local pid=$!
    echo $pid > "$FRONTEND_PID_FILE"
    cd "$APP_DIR" || exit 1 # Go back to the main app directory

    # Small delay to check if it started successfully
    sleep 3 # React dev server can take a bit longer
    if is_running "$FRONTEND_PID_FILE"; then
        echo "Frontend started successfully (PID $pid). Logs: $FRONTEND_LOG_FILE"
    else
        echo "Error: Frontend failed to start. Check logs: $FRONTEND_LOG_FILE"
        rm -f "$FRONTEND_PID_FILE" # Clean up pid file if start failed
        return 1
    fi
    return 0
}

# Function to stop the backend
stop_backend() {
    echo "Stopping Backend..."
    if [ -f "$BACKEND_PID_FILE" ]; then
        local pid=$(cat "$BACKEND_PID_FILE")
        if ps -p $pid > /dev/null 2>&1; then
            # Attempt graceful shutdown first (SIGTERM)
            kill $pid
            # Wait a bit for graceful shutdown
            sleep 2
            # Check if it's still running
            if ps -p $pid > /dev/null 2>&1; then
                echo "Backend (PID $pid) did not stop gracefully, sending SIGKILL..."
                kill -9 $pid
                sleep 1
            fi
             # Final check
            if ps -p $pid > /dev/null 2>&1; then
                 echo "Error: Could not stop backend (PID $pid)."
                 return 1
            else
                 echo "Backend stopped."
                 rm -f "$BACKEND_PID_FILE"
                 return 0
            fi
        else
            echo "Backend process (PID $pid) not found, removing stale PID file."
            rm -f "$BACKEND_PID_FILE"
            return 0
        fi
    else
        echo "Backend is not running (no PID file found)."
        return 0
    fi
}

# Function to stop the frontend
# Note: React development server (react-scripts start) often spawns child processes.
# Killing the parent PID might not always kill the children (like the browser opening).
# A more robust solution might involve pkill based on the command or port, but this is simpler.
stop_frontend() {
    echo "Stopping Frontend..."
    if [ -f "$FRONTEND_PID_FILE" ]; then
        local pid=$(cat "$FRONTEND_PID_FILE")
        if ps -p $pid > /dev/null 2>&1; then
            # Kill the process group to try and catch child processes (use negative PID)
            # Use SIGTERM first
            kill -- -$pid 2>/dev/null || kill $pid # Try killing group, fallback to single process
            sleep 2
            # Check if it's still running
            if ps -p $pid > /dev/null 2>&1; then
                echo "Frontend (PID $pid) did not stop gracefully, sending SIGKILL..."
                kill -9 -- -$pid 2>/dev/null || kill -9 $pid # Try killing group, fallback to single process
                sleep 1
            fi
            # Final check
            if ps -p $pid > /dev/null 2>&1; then
                 echo "Error: Could not stop frontend (PID $pid)."
                 return 1
            else
                 echo "Frontend stopped."
                 rm -f "$FRONTEND_PID_FILE"
                 return 0
            fi
        else
            echo "Frontend process (PID $pid) not found, removing stale PID file."
            rm -f "$FRONTEND_PID_FILE"
            return 0
        fi
    else
        echo "Frontend is not running (no PID file found)."
        return 0
    fi
}

# === Main Script Logic ===

ACTION=$1

case "$ACTION" in
    start)
        echo "=== Starting Application ==="
        start_backend
        backend_status=$?
        start_frontend
        frontend_status=$?
        echo "============================"
        # Exit with error if any part failed to start
        if [ $backend_status -ne 0 ] || [ $frontend_status -ne 0 ]; then
            exit 1
        fi
        ;;
    stop)
        echo "=== Stopping Application ==="
        stop_frontend # Stop frontend first (might depend on backend)
        stop_backend
        echo "============================"
        ;;
    restart)
        echo "=== Restarting Application ==="
        stop_frontend
        stop_backend
        echo "--- Waiting briefly before restart ---"
        sleep 2
        start_backend
        backend_status=$?
        start_frontend
        frontend_status=$?
        echo "=============================="
        # Exit with error if any part failed to start
        if [ $backend_status -ne 0 ] || [ $frontend_status -ne 0 ]; then
            exit 1
        fi
        ;;
    status)
        echo "=== Application Status ==="
        if is_running "$BACKEND_PID_FILE"; then
            echo "Backend: Running (PID $(cat $BACKEND_PID_FILE))"
        else
            echo "Backend: Stopped"
        fi
        if is_running "$FRONTEND_PID_FILE"; then
            echo "Frontend: Running (PID $(cat $FRONTEND_PID_FILE))"
        else
            echo "Frontend: Stopped"
        fi
        echo "========================"
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac

exit 0