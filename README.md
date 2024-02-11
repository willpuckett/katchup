# 🍅 Katchup
 
Katchup is a small script to simplify updating klipper firmware. It's a very simple script and should hopefully be able to build and flash [katapult](https://github.com/arksine/katapult) as well soon.


It looks for `.config` files in its directory, then builds Klipper and flashes the appropriate mcu.

To add an mcu to katchup,

1. `cd ~/klipper && make clean`
2. `make menuconfig`, select the appropriate options for your mcu, and quit
3. `cp ./.config ~/katchup/{mcu}-{canID}-{usbID}.config`

You may omit any of the mcu/canID/usbID fields, just not all of them! If you are flashing a `host process`, it must be named `host.config`. Other mcus may have a canID and/or a usbID (`ebb42-663e1edfe87f.config` or `pico-0e49609cf3bd-usb-katapult_rp2040_45503571290B7B88-if00.config`). If they have both, it indicates the mcu is functioning as a canbus bridge, and will be knocked off the CAN network and flashed via USB. For usb only devices, the config needs a double `-`, eg, `pico--usb-katapult_rp2040_45503571290B7B88-if00.config`. You may omit the usbID from CAN only devices. As long as the mcu isn't a host process, it doesn't matter what you call the mcu, it's just to make it easy to identify.

Run `~/katchup/katchup`. Katchup checks to see if there are any changes to the klipper repo before flashing, so it's adviseable to *not* pull changes to klipper in another fashion. Should you find that you already have, you may comment out the `pull` call on line6 of katchup.

I never knew there wasn't a standard katchup emoji until now.
