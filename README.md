# 🍅[^1] Katchup
 
Katchup is a small script to simplify updating [klipper](https://github.com/klipper3d/klipper) firmware via the [katapult](https://github.com/arksine/katapult) bootloader, which it can update as well. It's a very simple script. It looks for `.config` files in the `~/printer_data/config/katchup/klipper||katapult` directory, then builds Klipper (or Katapult) and flashes the appropriate mcu.

## Usage

```
❯ ./katchup.sh -h
Usage: katchup.sh [options]
Options:
  -a  (Add) Add a new mcu (call with -b to add Katapult config)
  -b  (Bootloader) Katapult mode. Flash/add/edit Katapult instead of Klipper
  -e  (Edit) Edit the .config file
  -h  (Help) Display this help message
  -m  (MCU) Specify a target mcu to flash, requires an argument
  -n  (No flash) Useful when you only want to create/edit
  -p  (Pull) Only flashes if there have been upstream changes
```

Run `~/katchup/katchup.sh` to flash all configured mcus with the version of Klipper at `~/klipper`. Katchup can check for upstream changes as well. Run `katchup -p` to pull from upstream and only flash if there are new commits relative to your working version.

`katchup.sh` can also flash a single mcu via the `-m {mcu}` flag. For the file `ebb42-663e1edfe87f.config`, you could type `katchup.sh -m ebb42`. Full names are NOT required: `katchup.sh -am ebb` would match and flash all `.config`s *starting* with `ebb`.

## Configuration

To add an mcu to katchup...

1. `~/katchup/katchup.sh -a` (you can add -n if you don't want to flash the new mcu right away)
2. The wizard will walk you through entering the canuuid and/or usb serial by-id name
3. **CAUTION** Do not run the wizard while printing. It will issue a can bootloader command to present you with uuids and may attempt to put a bridge device in flash mode to assist you in finding the usbid, actions which could potentially interrupt a running print.

Alternatively, 

1. `cd ~/klipper && make clean`
2. `make menuconfig`, select the appropriate options for your mcu, and quit
3. `cp .config ~/printer_data/config/katchup/klipper/{mcu}-{canID}-{usbID}.config`

The canID or usbID field may be omitted, just not both! ...Unless if flashing a `host process`, it must be named `host.config`. Other mcus may have a canID and/or a usbID (`ebb42-663e1edfe87f.config` or `pico-0e49609cf3bd-usb-katapult_rp2040_45503571290B7B88-if00.config`). If they have both, it indicates the mcu is functioning as a canbus bridge, and will be knocked off the CAN network and flashed via USB. For usb only devices, the config needs a double `-`, eg, `pico--usb-katapult_rp2040_45503571290B7B88-if00.config`. The usbID must be omitted from CAN only devices. As long as the mcu isn't a host process, it doesn't matter what you call the mcu, it's just to make it easy to identify.

## Flashing Katapult

Katchup can flash katapult as well. To add a new mcu to the katapult config process, run `~/katchup/katchup.sh -ab`. All options may be paired with `-b` for bootloader/katapult mode. You'll probably need to flash katapult by other means the first time, but you can still use the add wizard to set it up and then just flash `~/katapult/out/katapult.bin` via dfu/cube/openocd whatever your preferred method, or use the deployer.bin for an sdcard flash.

Katapult `.config`s **MUST** be configured to bulid the deployer. Invoke `katchup.sh` with the `-b` option to flash katapult.


[^1]: I never knew there wasn't a standard katchup emoji until now.
