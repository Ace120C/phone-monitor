#!/bin/bash 

LOGFILE="android_perf_log_$(date +%Y%m%d_%H%M%S).json"
echo "[" > "$LOGFILE"

# Function to get CPU load
get_cpu_load() { 
  adb shell dumpsys cpuinfo | grep -oP "TOTAL:\s*\K[0-9.]+"
}

PACKAGE_NAME="com.kurogame.wutheringwaves.global"
PREV_FRAMES=0

# Initialize previous frames count from SurfaceFlinger
init_prev_frames() {
  local current_frames=$(adb shell dumpsys SurfaceFlinger | grep -A 10 "Display" | grep "Frame" | awk '{print $3}')
  [[ "$current_frames" =~ ^[0-9]+$ ]] && PREV_FRAMES=$current_frames
}
init_prev_frames

# Function to get battery temperature
get_battery_temp() { 
  adb shell dumpsys battery | grep "temperature" | awk '{print $2 / 10}'
}

COUNT=0
echo "Logging performance metrics in JSON format. Press Ctrl + C to stop."
while true; do 
  TIMESTAMP=$(date +'%Y-%m-%d %H:%M:%S') 
  CPU_LOAD=$(get_cpu_load) 
  BATTERY_TEMP=$(get_battery_temp) 

  # Build JSON entry
  JSON_ENTRY="{\"time\": \"$TIMESTAMP\", 
  \"cpu_load\": $CPU_LOAD, 
  \"battery_temp\": $BATTERY_TEMP}" 

  # Add comma between entries (except for the first one)
  if [ $COUNT -ne 0 ]; then 
    echo "," >> "$LOGFILE" 
  fi 

  # Append the JSON entry to the log file
  echo "$JSON_ENTRY" >> "$LOGFILE" 

  # Output the current stats to the console
  echo "[$TIMESTAMP] CPU: ${CPU_LOAD}% | Battery Temp: ${BATTERY_TEMP}°C" 

  # Increment the count
  COUNT=$((COUNT+1)) 
  sleep 1
done

# Close the JSON array when the script is stopped
trap "echo ']' >> $LOGFILE; exit" SIGINT
