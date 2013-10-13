dnl Process this file with autoconf to produce a configure script.
dnl Created by Anjuta application wizard.

AC_INIT(mirai-chan, 0.1)

AC_CONFIG_HEADERS([config.h])

AM_INIT_AUTOMAKE([1.11])

AM_SILENT_RULES([yes])

AC_PROG_CC





dnl Check for vala
AM_PROG_VALAC([0.16.0])


PKG_CHECK_MODULES(MIRAI_CHAN, [gio-2.0])


AC_OUTPUT([
Makefile
src/Makefile
])
