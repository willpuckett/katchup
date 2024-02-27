#!/usr/bin/env bash

main () {
fab=klipper
pull=true
  while getopts :bhm:n flag
    do
        case "${flag}" in
            b) fab=katapult;;
            h) help && exit;;
            m) target_mcu=${OPTARG};;
            n) pull=false;;
            :) echo "Option '$OPTARG' missing a required argument." && help && exit 1;;
            \?) echo -e "\nInvalid option $OPTARG\n" && help && exit 1;;
        esac
    done


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
    filename="${config##*/}"
    if [[ -z $target_mcu || $filename =~ ^$target_mcu ]]; then
      export kconfig="KCONFIG_CONFIG=$config"
      echo flashing config $filename
      flashy "$config"
    fi
  done
  sudo service klipper start

  # # Uncomment to throw in a firmware restart
  # echo 🦒 Executing Firmware Restart...
  # echo FIRMWARE_RESTART > ~/printer_data/comms/klippy.serial 

  echo "✅ You're all up to date."
}

help () {
  echo "Usage: katchup.sh [options]"
  echo "Options:"
  echo "  -b  Flash katapult instead of klipper (bootloader)"
  echo "  -h  Display this help message"
  echo "  -m  Specify a target mcu to flash, requires an argument"
  echo "  -n  Skip the pull step (no pull)"
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
  cd ~/$fab
  make clean $kconfig

  # Call make menuconfig to update the .config file
  expect -c '
  global spawn_out
  spawn make menuconfig $::env(kconfig)
  send -- "q"
  send -- "y"
  ' 

  # build the config
  cores=$(grep -c ^processor /proc/cpuinfo)
  make -j $cores $kconfig |  pv --line-mode --size 55 --eta --progress > /dev/null
  echo -e "finished building!\nflashing $mcu..."

  # First check to see if it's a host process, and if it is, flash it
  if [[ $mcu == host ]]; then
    make flash $kconfig
    return
  fi
  
  # Put canbus bridge devices in flash mode...
  if [[ -n "$usb" ]] && [[ -n "$can" ]]; then 
	  ~/klippy-env/bin/python3 ~/katapult/scripts/flashtool.py -r -u "$can" 2> /dev/null
	  sleep 5
  fi
  
  # Flash
  ~/klippy-env/bin/python3 ~/katapult/scripts/flashtool.py $( [[ -n "$usb" ]] \
      && echo "-d /dev/serial/by-id/$usb" || echo "-u $can" ) \
      $( [[ "$fab" == katapult ]] && echo "-f out/deployer.bin")
  sleep 1
} 

# Call main with all of the arguments
main "$@"; exit
