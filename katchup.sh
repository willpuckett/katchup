#!/bin/bash

main () {
  pull=true
  while getopts m:n flag
  do
      case "${flag}" in
          m) target_mcu=${OPTARG};;
          n) pull=false;;
          # ) fullname=${OPTARG};;
      esac
  done
  # Make sure pv is installed (for progress bars)
  check_pv 

  echo "Let's katchup $1..."

  # Call the functions. Pull checks for available updates and exits if there are none...
    if [[ $pull == true ]]; then
      echo Pulling!
      pull $1
  fi

  sudo service klipper stop
  # Then this for loop updates eckh mcu with a config in the ~/kup directory
  for config in ~/printer_data/config/katchup/$1/*.config; do
    echo config $config target_mcu $target_mcu mcu $mcu
    if [[ -z $mcu || $config =~ $target_mcu ]]; then
      echo $config
      flashy $1 "$config"
    fi
  done
  sudo service klipper start && sleep 5

  # And finally a firmware restart because why not
  echo 🦒 Executing Firmware Restart...
  echo FIRMWARE_RESTART > ~/printer_data/comms/klippy.serial 
  echo "✅ You're all up to date. "
}


check_pv () {
  has_pv=$(which pv)
  if [[ -z $has_pv ]]; then
    echo "Can't find pv... Attempting to install..."
    sudo apt update && sudo apt install -y pv
  fi
  has_pv=$(which pv)
  if [[ -z $has_pv ]]; then
    echo Sorry, couldn\'t install pv. Try manually installing it and run again.
    exit
  fi

}

# Bring your remote refs up to date (git remote update). Then, git status -uno will tell you whether the branch you are tracking is ahead, behind or has diverged. If it says nothing, the local and remote are the same. 
pull () {
  cd ~/$1
  git remote update > /dev/null
  behind=$(git status -uno | grep behind)

  if [[ -z "$behind" ]]; then
    echo "All ready up to date! Exiting..."
    exit
  elif [[ -n "$behind" ]]; then
    git pull
  fi
}

# flashy ~/katchup/mcu-canID-usbID.config
# for usb only devices, omit canID but use double --
# ie ~/katchup/mcu--usbID.config
flashy () {
  config="${2##*/}"
  IFS=- read mcu can usb <<< "${config%.config}"

  echo -e "\nBuilding for $mcu..."
  
  # Clean up from last go 'round, and copy in the .config file
  cd ~/$1
  make clean
  cp "$2" ~/$1/.config
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

while getopts ba flag
  do
      case "${flag}" in
          b) fab=katapult;;
          a) fab=klipper;;
          # ) fullname=${OPTARG};;
      esac
  done

if [[ -z $fab ]]; then
  echo -e "Please specify a firmware to katchup. \nie: katchup.sh -b for katapult (bootloader) \nor katchup.sh -a for klipper (application)"
  exit
fi

main $fab "$@"; exit
# echo $fab
