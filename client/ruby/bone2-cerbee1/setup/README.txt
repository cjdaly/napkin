The source of the .dtbo files here is from this post:
http://www.armhf.com/index.php/beaglebone-black-serial-uart-device-tree-overlays-for-ubuntu-and-debian-wheezy-tty01-tty02-tty04-tty05-dtbo-files/

More related material here:
http://hipstercircuits.com/enable-serialuarttty-on-beaglebone-black/


BeagleBone Black system configuration steps (as root):
1) Copy the .dtbo files to /lib/firmware

2) edit /etc/rc.local and add this line:

/home/ubuntu/napkin/client/ruby/bone2-cerbee1/setup/initialize_uarts.sh

3) reboot and run command below to confirm /dev/ttyO1 and /dev/ttyO2:

dmesg | grep ttyO
