#!/bin/sh

freebsd_version="11.1"
gnome_version="3.26.2"
gnome_underscore="3_26_2"
date="`date '+%Y%m%d'`"

# == Configurations =========================================================

src="`pwd`/src"
root="`pwd`/root-debug"
cdroot="`pwd`/cdroot-debug"
image="`pwd`/out/FreeBSD-${freebsd_version}-GNOME-${gnome_version}-${date}-debug.iso"

repo="/usr/local/poudriere/data/packages/freebsd11-ports-gnome-gnome3-debug"
pkgs="`cat gnome3-debug-pkgs`"
vol="FREEBSD_GNOME_${gnome_underscore}_DEBUG"

# ===========================================================================

. "`dirname "$0"`/build.sh"
