#!/bin/bash

# activate python venv
. /home/malisha/.config/i3status/venv/bin/activate

bg_bar_color="#282A36"


common() {
  echo -n "\"border\": \"$bg_bar_color\","
  echo -n "\"separator\":false,"
  echo -n "\"separator_block_width\":0,"
  echo -n "\"border_top\":2,"
  echo -n "\"border_bottom\":2,"
  echo -n "\"border_left\":0,"
  echo -n "\"border_right\":0"
}

volume() {
  local bg="#673AB7"
  vol=$(pamixer --get-volume)
  echo -n ",{"
  echo -n "\"name\":\"id_volume\","
  if [ $vol -le 0 ]; then
    echo -n "\"full_text\":\" 🔇${vol}% \","
  else
    echo -n "\"full_text\":\"  ${vol}% \","
  fi
  echo -n "\"background\":\"$bg\""
  echo -n "}"
  #separator $bg_bar_color $bg
}

battery1() {
  if [ -f /sys/class/power_supply/BAT1/uevent ]; then
    local bg="#D69E2E"
    prct=$(cat /sys/class/power_supply/BAT1/uevent | grep "POWER_SUPPLY_CAPACITY=" | cut -d'=' -f2)
    charging=$(cat /sys/class/power_supply/BAT1/uevent | grep "POWER_SUPPLY_STATUS" | cut -d'=' -f2) # POWER_SUPPLY_STATUS=Discharging|Charging
    icon="  "
    if [ "$charging" == "Charging" ]; then
      icon="  "
    fi
    echo -n ",{"
    echo -n "\"name\":\"battery0\","
    echo -n "\"full_text\":\" ${icon} ${prct}% \","
    echo -n "\"color\":\"#000000\","
    echo -n "\"background\":\"$bg\""
    echo -n "}"
  fi
}

mydate() {
  local bg="#E0E0E0"
  echo -n ",{"
  echo -n "\"name\":\"id_time\","
  echo -n "\"full_text\":\"  $(date "+%a %d/%m %H:%M") \","
  echo -n "\"color\":\"#000000\","
  echo -n "\"background\":\"$bg\""
  echo -n "}"
}


myip_local() {
  local bg="#2E7D32" # vert
  echo -n ",{"
  echo -n "\"name\":\"ip_local\","
  echo -n "\"full_text\":\"  $(ip route get 1 | sed -n 's/.*src \([0-9.]\+\).*/\1/p') \","
  echo -n "\"background\":\"$bg\""
  echo -n "}"
}


myip_public() {
  local bg="#1976D2"
  echo -n ",{"
  echo -n "\"name\":\"ip_public\","
  echo -n "\"full_text\":\" $(/home/malisha/.config/i3status/ip.py) \","
  echo -n "\"background\":\"$bg\""
  echo -n "}"
}


logout() {
  echo -n ",{"
  echo -n "\"name\":\"id_logout\","
  echo -n "\"full_text\":\"  \""
  echo -n "}"
}

brightness() {
  local bg="#673AB7"
  echo -n ",{"
  echo -n "\"name\":\"ip_brightness\","
  echo -n "\"full_text\":\" 🔆$(($(brightnessctl get)*100/$(brightnessctl max)))% \","
  echo -n "\"background\":\"$bg\""
  echo -n "}"
}

echo '{ "version": 1, "click_events":true }'
echo '['
echo '[]'

# launched in a background process
(while :;
do
  echo -n ",["
  echo -n "{\"name\":\"id_cpu\",\"background\":\"#283593\",\"full_text\":\"CPU - $(/home/malisha/.config/i3status/cpu.py)%\"},"
  echo -n "{\"name\":\"id_ram\",\"background\":\"#3949AB\",\"full_text\":\"RAM - $(/home/malisha/.config/i3status/memory.py)%\"},"
  echo -n "{\"name\":\"id_disk_usage\",\"background\":\"#3949AB\",\"full_text\":\" $(/home/malisha/.config/i3status/memory.py)%\"}"
  mydate
  myip_local
  myip_public
  battery1
  volume
  brightness
  logout
  echo "]"
  sleep 0.3
done) &

# Listening for STDIN events
while read line;
do
  # echo $line > /tmp/tmp.txt
  # on click, we get from STDIN :
  # {"name":"id_time","button":1,"modifiers":["Mod2"],"x":2982,"y":9,"relative_x":67,"relative_y":9,"width":95,"height":22}

  # DATE click
  if [[ $line == *"name"*"id_time"* ]]; then
    alacritty -e /home/malisha/.config/i3status/click_time.sh &

  # CPU click
  elif [[ $line == *"name"*"id_cpu"* ]]; then
    alacritty -e htop &

  # VOLUME
  elif [[ $line == *"name"*"id_volume"* ]]; then
    alacritty -e alsamixer &

  # LOGOUT
  elif [[ $line == *"name"*"id_logout"* ]]; then
    i3-nagbar -t warning -m 'Log out ?' -b 'yes' 'i3-msg exit' > /dev/null &

  fi
done
