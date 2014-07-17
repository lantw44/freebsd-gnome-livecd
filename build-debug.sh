#!/bin/sh

# == Configurations =========================================================

root="/home/lantw44/livecd/root-debug"
cdroot="/home/lantw44/livecd/cdroot-debug"
image="/home/lantw44/livecd/out/FreeBSD-10.0-GNOME-3.12.2-`date '+%Y%m%d'`-debug.iso"

repo="/usr/local/poudriere/data/packages/freebsd10-marcuscom-gnome3-debug"
pkgs="`cat /home/lantw44/livecd/gnome3-debug-pkgs`"

# ===========================================================================

. "`dirname "$0"`/build.sh"
