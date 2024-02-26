#!/bin/bash

main () {
  # Make sure pv is installed (for progress bars)
  check_reqs

  echo "Katching up $fab..."

  # Pull checks for available updates and exits if there are none...
    if [[ $pull == true ]]; then
      echo Pulling!
      pull
  fi

  sudo service klipper stop
  # Then this for loop updates each mcu with a config in the ~/printer_data/config/katchup/$fab directory
  for config in ~/printer_data/config/katchup/$fab/*.config; do
    export filename="${config##*/}"
    # echo $filename
    if [[ -z $target_mcu || $filename =~ ^$target_mcu- ]]; then
      echo flashing config $filename
      flashy "$config"
    fi
  done
  sudo service klipper start && sleep 5

  # # Uncomment to throw in a firmware restart
  # echo 🦒 Executing Firmware Restart...
  # echo FIRMWARE_RESTART > ~/printer_data/comms/klippy.serial 

  echo "✅ You're all up to date."
}

check_reqs () {
  has_pv=$(which pv)
  has_expect=$(which expect)
  if [[ -z $has_pv ]]; then
    echo "Can't find pv... Attempting to install..."
    sudo apt update && sudo apt install -y pv
  fi
  if [[ -z $has_expect ]]; then
    echo "Can't find expect... Attempting to install..."
    sudo apt update && sudo apt install -y expect
  fi
  has_pv=$(which pv)
  if [[ -z $has_pv ]]; then
    echo Sorry, couldn\'t install pv. Try manually installing it and run again.
    exit
  fi
  has_expect=$(which expect)
  if [[ -z $has_expect ]]; then
    echo Sorry, couldn\'t install expect. Try manually installing it and run again.
    exit
  fi
}

# Bring your remote refs up to date (git remote update). Then, git status -uno will tell you whether the branch you are tracking is ahead, behind or has diverged. If it says nothing, the local and remote are the same. 
pull () {
  cd ~/$fab
  git remote update > /dev/null
  behind=$(git status -uno | grep behind)

  if [[ -z "$behind" ]]; then
    echo "All ready up to date! Exiting..."
    exit
  elif [[ -n "$behind" ]]; then
    git pull
  fi
}

# flashy ~/printer_data/config/katchup/$fab/mcu-canID-usbID.config
# for usb only devices, omit canID but use double --
# ie ~/printer_data/config/katchup/$fab/mcu--usbID.config
flashy () {
  IFS=- read mcu can usb <<< "${filename%.config}"

  echo -e "\nBuilding for $mcu..."
  
  # Clean up from last go 'round, and copy in the .config file
  cd ~/$fab
  make clean
  cp "$1" ~/$fab/.config

  # Call make menuconfig to update the .config file
  expect -c '
  global spawn_out
  # set timeout -1
  spawn make menuconfig
  # match_max 100000
  send -- "q"
  # expect "Quit"
  send -- "y"
  ' 
  # clear
  cp ~/$fab/.config "$1"

  # build the config
  make -j4 |  pv --line-mode --size 55 --eta --progress > /dev/null
  echo -e "finished building!\nflashing $mcu..."

  # First check to see if it's a host process, and if it is, flash it
  if [[ $mcu == host ]]; then
    make flash
    return
  fi
  
  # Put canbus bridge devices in flash mode...
  if [[ -n "$usb" ]] && [[ -n "$can" ]]; then 
	  ~/klippy-env/bin/python3 ~/katapult/scripts/flashtool.py -r -u "$can" 2> /dev/null
	  sleep 5
  fi
  
  # Flash
  ~/klippy-env/bin/python3 ~/katapult/scripts/flashtool.py $( [[ -n "$usb" ]] \
      && echo "-d /dev/serial/by-id/$usb" || echo "-u $can" ) 
  sleep 5
} 

export pull=true
while getopts bam:n flag
  do
      case "${flag}" in
          b) export fab=katapult;;
          a) export fab=klipper;;
          m) export target_mcu=${OPTARG};;
          n) pull=false;;
          # ) fullname=${OPTARG};;
      esac
  done


if [[ -z $fab ]]; then
  echo -e "Please specify a firmware to katchup. \nie: katchup.sh -b for katapult (bootloader) \nor katchup.sh -a for klipper (application)"
  exit
fi

main; exit
