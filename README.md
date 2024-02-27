# 🍅[^1] Katchup
 
Katchup is a small script to simplify updating [klipper](https://github.com/klipper3d/klipper) firmware via the [katapult](https://github.com/arksine/katapult) bootloader, which it can update as well. It's a very simple script. It looks for `.config` files in the `~/printer_data/config/katchup/klipper||katapult` directory, then builds Klipper (or Katapult) and flashes the appropriate mcu.

## Usage

```
❯ ./katchup.sh -h
Usage: katchup.sh [options]
Options:
  -a  Add a new mcu (call with -b to add Katapult config)
  -b  Flash Katapult instead of Klipper (bootloader)
  -e  Edit the .config file
  -h  Display this help message
  -m  Specify a target mcu to flash, requires an argument
  -n  No flash (useful when you only want to create/edit)
  -p  Pull. Only flashes if there have been upstream changes
```

Run `~/katchup/katchup.sh`. Katchup checks to see if there are any changes to the klipper repo before flashing, so it's adviseable to *not* pull changes to klipper in another fashion. Should you find that you already have, you may invoke `katchup.sh` with the `-n` flag (for "no-pull").

`katchup.sh` can also flash a single mcu via the `-m {mcu}` flag. For the file `ebb42-663e1edfe87f.config`, you could type `katchup.sh -m ebb42`. Full names are NOT required: `katchup.sh -am ebb` would match and flash all `.config`s starting with `ebb`.

## Configuration

To add an mcu to katchup...

1. `~/katchup/katchup.sh -a` (you can add -n if you don't want to flash the new mcu right away)
2. The wizard will walk you through entering the canuuid and/or usb serial by-id name

Alternatively, 

1. `cd ~/klipper && make clean`
2. `make menuconfig`, select the appropriate options for your mcu, and quit
3. `cp .config ~/printer_data/config/katchup/klipper/{mcu}-{canID}-{usbID}.config`

The canID or usbID field may be omitted, just not both! If flashing a `host process`, it must be named `host.config`. Other mcus may have a canID and/or a usbID (`ebb42-663e1edfe87f.config` or `pico-0e49609cf3bd-usb-katapult_rp2040_45503571290B7B88-if00.config`). If they have both, it indicates the mcu is functioning as a canbus bridge, and will be knocked off the CAN network and flashed via USB. For usb only devices, the config needs a double `-`, eg, `pico--usb-katapult_rp2040_45503571290B7B88-if00.config`. The usbID must be omitted from CAN only devices. As long as the mcu isn't a host process, it doesn't matter what you call the mcu, it's just to make it easy to identify.

## Flashing Katapult

Katchup may be configured for katapult by substituting `katapult` for `klipper` in the above steps. Katapult `.config`s **MUST** be configured to bulid the deployer. Invoke `katchup.sh` with the `-b` option to flash katapult.


[^1]: I never knew there wasn't a standard katchup emoji until now.
