#!/usr/bin/env bash

main () {
fab=klipper
add=false
edit=false
flash=true
pull=false
  while getopts :abehm:np flag
    do
        case "${flag}" in
            a) add=true;;
            b) fab=katapult;;
            e) edit=true;;
            h) help && exit;;
            m) target_mcu=${OPTARG};;
            n) flash=false;;
            p) pull=true;;
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

  if [[ $add == true ]]; then
    echo -e "Welcome to the mcu adder utility...\nIt's a little rough around the edges, \nso for now you'll need to copy and paste ids, \nbut I'll try and present helpful information along the way..."
    read -p "Enter mcu name: " mcuname
    echo -e "Searching can0...\nDo any of these look useful?"
    ~/klippy-env/bin/python3 ~/katapult/scripts/flash_can.py -q
    read -p "Enter mcu can uuid (leave blank for serial only devices): " mcucanuuid
    echo -e "Listing serial devices..."
    ls /dev/serial/by-id/
    read -p "Enter by-id serial name (leave blank for can only devices): " mcubyid
    echo -e "Thanks buckets. Continuing to edit..."
    touch ~/printer_data/config/katchup/$fab/$mcuname-$mcucanuuid$( [[ -n $mcubyid ]] && echo -)$mcubyid.config

    edit=true
    target_mcu=$mcuname
  fi

  if [[ $flash == true ]]; then
    sudo service klipper stop
  fi
  # Then this for loop updates each mcu with a config in the ~/printer_data/config/katchup/$fab directory
  for config in ~/printer_data/config/katchup/$fab/*.config; do
    filename="${config##*/}"
    if [[ -z $target_mcu || $filename =~ ^$target_mcu ]]; then
      export kconfig="KCONFIG_CONFIG=$config"
      flashy "$config"
    fi
  done

  if [[ $flash == true ]]; then
    sudo service klipper start
  fi
  # # Uncomment to throw in a firmware restart
  # echo 🦒 Executing Firmware Restart...
  # echo FIRMWARE_RESTART > ~/printer_data/comms/klippy.serial 

  echo "✅ You're all up to date."
}

help () {
  echo "Usage: katchup.sh [options]"
  echo "Options:"
  echo "  -a  Add a new mcu (call with -b to add Katapult config)"
  echo "  -b  Flash Katapult instead of klipper (bootloader)"
  echo "  -e  Edit the .config file"
  echo "  -h  Display this help message"
  echo "  -m  Specify a target mcu to flash, requires an argument"
  echo "  -n  No flash (useful when you only want to create/edit)"
  echo "  -p  Pull. Only flashes if there have been upstream changes"
}

check_reqs () {
  has_pv=$(which pv)
  has_expect=$(which expect)
  if [[ -z $has_pv || -z $has_expect ]]; then
    echo "Missing dependencies... Attempting to install..."
    sudo apt update && sudo apt install -y pv expect
  fi
  has_pv=$(which pv)
  has_expect=$(which expect)
  if [[ -z $has_pv || -z $has_expect ]]; then
    echo "Sorry, couldn't find dependencies. Try manually installing pv and expect, make sure they're in your \$PATH, and run again."
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

  # Call make menuconfig to update the .config file.
  # Ensures it's built properly when new options are added
  if [[ $edit == true ]]; then
    make menuconfig $kconfig
  else
    expect -c '
    global spawn_out
    spawn make menuconfig $::env(kconfig)
    send -- "q"
    send -- "y"
    ' 
  fi

  if [[ $flash == true ]]; then
    echo flashing config $filename

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
  fi
} 

# Call main with all of the arguments
main "$@"; exit
