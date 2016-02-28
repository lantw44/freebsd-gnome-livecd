#!/bin/sh

# == Configurations =========================================================

root="/usr/local/tmp/livecd/root-debug"
cdroot="/usr/local/tmp/livecd/cdroot-debug"
image="/usr/local/tmp/livecd/out/FreeBSD-10.1-GNOME-3.15-`date '+%Y%m%d'`-debug.iso"

repo="/usr/local/poudriere/data/packages/freebsd10-ports-gnome-gnome3-debug"
pkgs="`cat gnome3-debug-pkgs`"

# ===========================================================================

. "`dirname "$0"`/build.sh"
