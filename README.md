# stm32_makefile_template
This is Makefile template environment that can be used for development on STM32 platforms

I wanted to put everything in one place so that I, or anyone else, can start to develop on this platform in shortest amount of time.
I didn't want to sacrifice Makefile modularity in the process and put everything in one big Makefile-rule-them-all.
First version of enviroment was done by Martin Glunz (http://wunderkis.de/stm32cube/index.html)

Currently enviroment uses old STM32F4xx standard peripherals library (STSW-STM32065). It can use Cube HAL also but I needed back-compability.

# Development on STM32F4 with Linux

This tutorial is going to show how to setup OpenSource toolchain on Ubuntu for cross-compiling applications.

This tutorial was tested on Ubuntu 14.04 but it should work on any *nix...

## Installing toolchain

Before actual toolchain installation we need to sort out some dependecies. Issue following:
```
sudo apt-get install build-essential git flex bison libgmp3-dev libmpfr-dev libncurses5-dev libmpc-dev autoconf texinfo libtool libftdi-dev libusb-1.0-0-dev zlib1g zlib1g-dev python-yaml
```

Then remove any gcc-arm-non-eabi that you may have on your machine (there is some conflict on 14.04...):
```
sudo apt-get remove binutils-arm-none-eabi gcc-arm-none-eabi
```

Add repository and install the gcc for ARM:
```
sudo add-apt-repository ppa:terry.guo/gcc-arm-embedded
sudo apt-get update
sudo apt-get install gcc-arm-none-eabi=4.9.3.2014q4-0trusty12
```

**4.9.3.2014q4-0trusty12 was latest version on 2015/01/12. There may be newer version since this document was written...**

## Allow mere mortals to use USB
For this you will need `sudo` or `root` privileges.

Firstly connect your debugger (in my case it was STM32F429 Discovery board but STLink should be same everywhere) and issue `dmesg` command into terminal. You should get output similar to this:
```
[ 1842.873954] usb 3-2: new full-speed USB device number 3 using xhci_hcd
[ 1842.891746] usb 3-2: New USB device found, idVendor=0483, idProduct=3748
[ 1842.891753] usb 3-2: New USB device strings: Mfr=1, Product=2, SerialNumber=3
[ 1842.891757] usb 3-2: Product: STM32 STLink
[ 1842.891760] usb 3-2: Manufacturer: STMicroelectronics
[ 1842.891763] usb 3-2: SerialNumber: P\xffffffc3\xffffffbf\xffffffbfn\x06PxRSU9\x10\xffffffc2\xffffff87\xffffff87
```

We are interested in a line where `idVendor` and `idProduct` are mentioned. Use those values and create new udev rule `/etc/udev/rules.d/99-stlink-v2.rules` using your favorite editor. Rule should contain following:
```
SUBSYSTEM=="usb", ATTR{idVendor}=="0483", ATTR{idProduct}=="3748", MODE="0666"
```

Change `idVendor` and `idProduct` if you have different values. These should be correct for STLink/V2.

This will allow you to use stlink as a normal user. To apply changes immmediateley without restart issue:

```
sudo service udev restart
```

## Building and installing Debugger

There are two flavors that were tested, OpenOCD and Texane STLINK. OpenOCD is good if you will install Eclipse and use GUI and both are great for development in terminal. Texane is great if you're using STM32 Discovery board and not external programmator. 

### Texane STLINK
This software talks to the STLINK interface only and it supports STLINKv1 and STLINKv2. It should work on most development kits. More on [[https://github.com/texane/stlink/|link]].

Retrive a copy of the software with:
```
git clone https://github.com/texane/stlink.git
```

By following README build the code. It should produce st-util and st-flash utilities. They **will not** be installed on your `PATH`. Either include them in your local `PATH` or transfer them to `/usr/bin`. I suggest you create your `/home/$USER/bin` and extend your `PATH` variable. Google it or ask me how to do it...
Build it with:

```
./autogen.sh
./configure
make
```

Test it with executing `./st-util` command. You should get something like:
```
2015-09-28T11:40:38 INFO src/stlink-common.c: Loading device parameters....
2015-09-28T11:40:38 INFO src/stlink-common.c: Device connected is: F4 device, id 0x10016413
2015-09-28T11:40:38 INFO src/stlink-common.c: SRAM size: 0x30000 bytes (192 KiB), Flash: 0x100000 bytes (1024 KiB) in pages of 16384 bytes
2015-09-28T11:40:38 INFO gdbserver/gdb-server.c: Chip ID is 00000413, Core ID is  2ba01477.
2015-09-28T11:40:38 INFO gdbserver/gdb-server.c: Target voltage is 2899 mV.
2015-09-28T11:40:38 INFO gdbserver/gdb-server.c: Listening at *:4242...
```

### OpenOCD
OpenOCD is used universally for programming and debugging.

Clone the source to your build directory:
```
git clone git://openocd.git.sourceforge.net/gitroot/openocd/openocd
```

Configure it:

```
cd openocd
./bootstrap
./configure --enable-maintainer-mode --disable-option-checking --disable-werror --prefix=${PREFIX} --enable-dummy --enable-usb_blaster_libftdi --enable-ep93xx --enable-at91rm9200 --enable-presto_libftdi --enable-usbprog --enable-jlink --enable-vsllink --enable-rlink --enable-stlink --enable-arm-jtag-ew
```

Build it:

```
make -j 4
```

**`-j 4` option is for multithread build. If unsure just issue `make`**

And lastly install it:

```
sudo make install
```

You can test connection by issuing:
```
openocd -f /usr/share/openocd/scripts/board/stm32f429discovery.cfg
```

You should get something like this:

```
Open On-Chip Debugger 0.9.0-dev-00223-g1567cae (2015-01-12-17:01)
Licensed under GNU GPL v2
For bug reports, read
	http://openocd.sourceforge.net/doc/doxygen/bugs.html
Info : The selected transport took over low-level target control. The results might differ compared to plain JTAG/SWD
adapter speed: 2000 kHz
adapter_nsrst_delay: 100
srst_only separate srst_nogate srst_open_drain connect_deassert_srst
Info : clock speed 2000 kHz
Info : STLINK v2 JTAG v17 API v2 SWIM v0 VID 0x0483 PID 0x3748
Info : using stlink api v2
Info : Target voltage: 2.871303
Info : stm32f4x.cpu: hardware has 6 breakpoints, 4 watchpoints
```

Kill the program with `<CTRL>+C`.
```
I'm using ''stm32f429discovery'' board here. If you're using some different board find its config in ''/usr/share/openocd/scripts/board/'' or write your own ;-)
```

## Sources
- [http://pulkomandy.tk/_/_Electronique/_Discovering%20the%20STM32F3%20Discovery]
- [http://vedder.se/2012/07/get-started-with-stm32f4-on-ubuntu-linux/]
- [http://vedder.se/2012/12/debugging-the-stm32f4-using-openocd-gdb-and-eclipse/]
- [http://www.triplespark.net/elec/pdev/arm/stm32.html]
- [http://wunderkis.de/stm32cube/index.html]
- [http://www.wolinlabs.com/blog/linux.stm32.discovery.gcc.html]
- [https://liviube.wordpress.com/2013/04/22/blink-for-stm32f4-discovery-board-on-linux-with-makefile/]
- [http://jeremyherbert.net/get/stm32f4_getting_started]
- [https://github.com/texane/stlink/]

