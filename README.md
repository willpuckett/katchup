# 🍅 Katchup
 
Katchup is a small script to simplify updating klipper firmware. It's a very simple script and should hopefully be able to build and flash [katapult](https://github.com/arksine/katapult) as well soon.


It looks for `.config` files in the `~/printer_data/config/katchup/klipper` directory, then builds Klipper and flashes the appropriate mcu.

To add an mcu to katchup,

1. `cd ~/klipper && make clean`
2. `make menuconfig`, select the appropriate options for your mcu, and quit
3. `cp ./.config ~printer_data/config/katchup/klipper/{mcu}-{canID}-{usbID}.config`

You may omit any of the mcu/canID/usbID fields, just not all of them! If you are flashing a `host process`, it must be named `host.config`. Other mcus may have a canID and/or a usbID (`ebb42-663e1edfe87f.config` or `pico-0e49609cf3bd-usb-katapult_rp2040_45503571290B7B88-if00.config`). If they have both, it indicates the mcu is functioning as a canbus bridge, and will be knocked off the CAN network and flashed via USB. For usb only devices, the config needs a double `-`, eg, `pico--usb-katapult_rp2040_45503571290B7B88-if00.config`. You may omit the usbID from CAN only devices. As long as the mcu isn't a host process, it doesn't matter what you call the mcu, it's just to make it easy to identify.

Run `~/katchup/katchup.sh`. Katchup checks to see if there are any changes to the klipper repo before flashing, so it's adviseable to *not* pull changes to klipper in another fashion. Should you find that you already have, you may invoke `ketchup.sh` with the `-n` flag (for "no-pull").

In preparation for adding katapult updates, `katchup.sh` now requires either `-a` ("application") or `-b` ("bootloader"). 

`ketchup.sh` can also flash a single mcu via the `-m {mcu}` flag. It's a really sloppy job on matching the mcu name, and if it appears anywhere in the path of the config file, it will match! Be warned!

I never knew there wasn't a standard katchup emoji until now.
