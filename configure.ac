#                                               -*- Autoconf -*-
# Process this file with autoconf to produce a configure script.

AC_PREREQ([2.53])
AC_INIT([GNOME Games], [3.6.0],
  [http://bugzilla.gnome.org/enter_bug.cgi?product=gnome-games],
  [gnome-games])

AC_CONFIG_MACRO_DIR([m4])
AC_CONFIG_HEADERS([config.h])

AM_INIT_AUTOMAKE([1.11 tar-ustar no-dist-gzip dist-xz foreign])

AM_SILENT_RULES([yes])

if test -z "$enable_maintainer_mode"; then
  enable_maintainer_mode=yes
fi
AM_MAINTAINER_MODE([enable])

# First parse the list of enabled games, so we know which options
# we support and which features to check for

# This is the canonical list of all game subdirectories.
allgames="glchess glines gnect gnibbles gnobots2 gnomine gnotravex gnotski gtali iagno lightsoff gnome-mahjongg quadrapassel gnome-sudoku swell-foop"
AC_SUBST([allgames])
staginggames=""
AC_SUBST([staginggames])

gamelist=""

AC_MSG_CHECKING([which games to build])

AC_ARG_WITH([games],
  [--with-games=game1,game2,...],
  [],[with_games=all])

AC_ARG_ENABLE([games],
  [AS_HELP_STRING([--enable-games=list],[Enable the games in the comma separated list ("all" and "none" are valid)])],
  [with_games="$enableval"],[])

if test -n "$with_games"; then
  gamelist=""
  IFS="${IFS=	}"; gg_saved_ifs="$IFS"; IFS=","
  for item in $with_games; do
    case $item in
      all) gamelist="$allgames" ;;
      none) gamelist="" ;;
      *) if test -z "$gamelist"; then
           gamelist="$item"
         else
           gamelist="$gamelist $item"
         fi
         ;;
    esac
  done
  IFS="$gg_saved_ifs"
else
  gamelist="$allgames"   
fi

## This has a particularly silly name because autoconf doesn't allow 
## --disable-foo to have arguments so we have to use an --enable-fubar form.
AC_ARG_ENABLE(omitgames,
  AS_HELP_STRING([--enable-omitgames=list],
    [Don't compile games in the comma separated list. ("all" and "none" are valid)]))
if test -n "$enable_omitgames"; then
   enable_omitgames=`echo ,"${enable_omitgames}", | sed -e 's/[[	,]][[	,]]*/ /g' -e 's/,$//'`
   omittedgames=""
   gamelist=""
   for item in ${enable_omitgames}; do
     for game in ${allgames}; do
       case ${item} in
	  all) omittedgames=${allgames};;
	  none) omittedgames="";;
          ${game}) omittedgames="${game} ${omittedgames}";;
	  *) ;; 
        esac
     done
   done
   for game in ${allgames}; do
     case ${omittedgames} in
       *${game}*) ;;
       *) gamelist="${gamelist} ${game}";;
     esac
   done
elif test -z "$gamelist"; then
   # Everything on by default
   gamelist=${allgames}
fi

## This is the staging area
## These games aren't quite ready for prime-time

AC_MSG_CHECKING([whether to enable staging games])
AC_ARG_ENABLE([staging],
  [AS_HELP_STRING([--enable-staging],[whether to enable beta game support (default: disabled)])],[],[])
AC_MSG_RESULT([$enable_staging])

if test "$enable_staging" = "yes"; then
	gamelist="${gamelist} ${staginggames}"
fi

AC_MSG_RESULT([$gamelist])

AC_SUBST([gamelist])

# Feature matrix

need_vala=no
need_sqlite=no
need_opengl=no
need_glx=no
need_python=no
need_clutter=no
need_gmenu=no

for game in $gamelist; do
  case $game in
    glchess|gnomine|gnotravex|iagno|lightsoff|gnome-mahjongg|quadrapassel|swell-foop) need_vala=yes ;;
    *) ;;
  esac
  case $game in
    glchess) need_opengl=yes ;;
    *) ;;
  esac
  case $game in
    glchess) need_glx=yes ;;
    *) ;;
  esac
  case $game in
    gnome-sudoku) need_python=yes ;;
    *) ;;
  esac
  case $game in
    glchess) need_sqlite=yes ;;
    *) ;;
  esac
  case $game in
    quadrapassel|lightsoff|swell-foop|gnibbles) need_clutter=yes ;;
    *) ;;
  esac
  case $game in
    gnomine|gnotravex|iagno|lightsoff|gnome-mahjongg|quadrapassel|swell-foop) need_gmenu=yes ;;
    *) ;;
  esac
done

# Set a conditional for each game to build

for game in $allgames $staginggames; do
  eval AS_TR_SH([build_$game])=no
done
for game in $gamelist; do
  eval AS_TR_SH([build_$game])=yes
done

AM_CONDITIONAL([BUILD_GLCHESS],[test "$build_glchess" = "yes"])
AM_CONDITIONAL([BUILD_GLINES],[test "$build_glines" = "yes"])
AM_CONDITIONAL([BUILD_GNECT],[test "$build_gnect" = "yes"])
AM_CONDITIONAL([BUILD_GNIBBLES],[test "$build_gnibbles" = "yes"])
AM_CONDITIONAL([BUILD_GNOBOTS2],[test "$build_gnobots2" = "yes"])
AM_CONDITIONAL([BUILD_GNOME_SUDOKU],[test "$build_gnome_sudoku" = "yes"])
AM_CONDITIONAL([BUILD_QUADRAPASSEL],[test "$build_quadrapassel" = "yes"])
AM_CONDITIONAL([BUILD_GNOMINE],[test "$build_gnomine" = "yes"])
AM_CONDITIONAL([BUILD_GNOTRAVEX],[test "$build_gnotravex" = "yes"])
AM_CONDITIONAL([BUILD_GNOTSKI],[test "$build_gnotski" = "yes"])
AM_CONDITIONAL([BUILD_GTALI],[test "$build_gtali" = "yes"])
AM_CONDITIONAL([BUILD_IAGNO],[test "$build_iagno" = "yes"])
AM_CONDITIONAL([BUILD_LIGHTSOFF],[test "$build_lightsoff" = "yes"])
AM_CONDITIONAL([BUILD_GNOME_MAHJONGG],[test "$build_gnome_mahjongg" = "yes"])
AM_CONDITIONAL([BUILD_SWELL_FOOP],[test "$build_swell_foop" = "yes"])

# Locate various programs

PKG_PROG_PKG_CONFIG([0.15])

AC_PROG_CC
AC_PROG_CPP
AC_PROG_LN_S
AC_PROG_SED

if test "$need_vala" = "yes"; then
  AM_PROG_VALAC([0.15.1])
  AC_CHECK_LIB([m],[floor])
fi

AM_PROG_CC_C_O

LT_INIT

GNOME_COMMON_INIT
GNOME_DEBUG_CHECK
GNOME_COMPILE_WARNINGS([maximum])
GNOME_MAINTAINER_MODE_DEFINES

dnl ****************************************************************************
dnl * Python 2.4
dnl ****************************************************************************

AM_PATH_PYTHON([2.4],[have_python=yes],[have_python=no])

# ************
# Dependencies
# ************

# Check which platform to use

AC_MSG_CHECKING([for which platform to build])
AC_ARG_WITH([platform],
  [AS_HELP_STRING([--with-platform=gnome|gtk-only (default: gnome)])],
  [case "$withval" in
    gnome|gtk-only) ;;
    *) AC_MSG_ERROR([invalid argument "$withval" for --with-platform]) ;;
   esac],
  [with_platform=gnome])
AC_MSG_RESULT([$with_platform])

AM_CONDITIONAL([HAVE_GNOME],[test "$with_platform" = "gnome"])

if test "$with_platform" = "gnome"; then
  AC_DEFINE([HAVE_GNOME],[1],[Define if GNOME support is enabled])
fi

# Win32 platform

AC_CANONICAL_HOST

AC_MSG_CHECKING([for some Win32 platform])
case "$host" in
  *-*-cygwin*|*-*-mingw*)
    platform_win32=yes
    ;;
  *)
    platform_win32=no
    ;;
esac
AC_MSG_RESULT([$platform_win32])
AM_CONDITIONAL([PLATFORM_WIN32],[test "$platform_win32" = "yes"])

# ********************
# Checks for libraries
# ********************

PYGOBJECT_REQUIRED=2.28.3

GTK_REQUIRED=3.0.0
RSVG_REQUIRED=2.32.0
LIBCANBERRA_GTK_REQUIRED=0.26
GIO_REQUIRED=2.25.7
GSTREAMER_REQUIRED=0.10.11
CAIRO_REQUIRED=1.10.0

if test "$need_gmenu" = "yes"; then
  GTK_REQUIRED=3.3.11
fi

# Check for common modules

PKG_CHECK_MODULES([GMODULE],[gmodule-2.0])
AC_SUBST([GMODULE_CFLAGS])
AC_SUBST([GMODULE_LIBS])

PKG_CHECK_MODULES([GOBJECT],[gobject-2.0])
AC_SUBST([GOBJECT_CFLAGS])
AC_SUBST([GOBJECT_LIBS])

PKG_CHECK_MODULES([GTK],[gtk+-3.0 >= $GTK_REQUIRED])
AC_SUBST([GTK_CFLAGS])
AC_SUBST([GTK_LIBS])

PKG_CHECK_MODULES([RSVG],[
  librsvg-2.0 >= $RSVG_REQUIRED
  cairo >= $CAIRO_REQUIRED])
AC_SUBST([RSVG_CFLAGS])
AC_SUBST([RSVG_LIBS])

# GDBus

PKG_CHECK_MODULES([GIO],[gio-2.0 >= $GIO_REQUIRED])

# GSettings

m4_ifdef([GLIB_GSETTINGS],[GLIB_GSETTINGS([],[:])])

# Check for SQLite

have_sqlite=no
if test "$need_sqlite" = "yes"; then
  have_sqlite=yes

  # Errors out if sqlite is not found
  PKG_CHECK_MODULES([SQLITE],[sqlite3])

  AC_SUBST([SQLITE_CFLAGS])
  AC_SUBST([SQLITE_LIBS])

  AC_DEFINE([HAVE_SQLITE],[1],[Refine if sqlite is available])
fi

AM_CONDITIONAL([HAVE_SQLITE],[test "$have_sqlite" = "yes"])

# Check for OpenGL

have_opengl=no
if test "$need_opengl" = "yes"; then
  have_opengl=yes

  # Errors out if OpenGL is not found
  PKG_CHECK_MODULES([OPENGL],[
    gl glu])

  AC_SUBST([OPENGL_CFLAGS])
  AC_SUBST([OPENGL_LIBS])

  AC_DEFINE([HAVE_OPENGL],[1],[Define if OpenGL is available])
fi

AM_CONDITIONAL([HAVE_OPENGL],[test "$have_opengl" = "yes"])

# Check for GLX

have_glx=no
if test "$need_glx" = "yes"; then
  have_glx=yes

  # Errors out if GLX is not found
  PKG_CHECK_MODULES([GLX],[
    gl x11])

  AC_SUBST([GLX_CFLAGS])
  AC_SUBST([GLX_LIBS])

  AC_DEFINE([HAVE_GLX],[1],[Define if GLX is available])
fi

AM_CONDITIONAL([HAVE_GLX],[test "$have_glx" = "yes"])

# Check for Clutter

if test "$need_clutter" = "yes"; then
  CLUTTER_REQUIRED=1.0.0

  PKG_CHECK_MODULES([CLUTTER],[clutter-1.0 >= $CLUTTER_REQUIRED])
  AC_SUBST([CLUTTER_CFLAGS])
  AC_SUBST([CLUTTER_LIBS])

  CLUTTER_GTK_REQUIRED=0.91.6

  PKG_CHECK_MODULES([CLUTTER_GTK],[clutter-gtk-1.0 >= $CLUTTER_GTK_REQUIRED])
  AC_SUBST([CLUTTER_GTK_CFLAGS])
  AC_SUBST([CLUTTER_GTK_LIBS])
fi

AM_CONDITIONAL([HAVE_CLUTTER],[test "$need_clutter" = "yes"])

# Check for PyGObject

# This is madness because the interface didn't change from 2.0 to 3.0
if test "$have_python" = "yes"; then
  PKG_CHECK_MODULES([PYGOBJECT],[
    pygobject-3.0 >= $PYGOBJECT_REQUIRED],
    [have_pygtk=yes],[PKG_CHECK_MODULES([PYGOBJECT],[
      pygobject-2.0 >= $PYGOBJECT_REQUIRED],
      [have_pygtk=yes],[have_pygtk=no])
    ])
fi

enable_python=no
if test "$have_python" = "yes" -a "$have_pygtk" = "yes"; then
  enable_python=yes
fi

if test "$enable_python" = "no" -a "$need_python" = "yes"; then
  AC_MSG_ERROR([Some games need python, but pygobject packages were not found.])
fi

AM_CONDITIONAL([HAVE_PYTHON],[test "$enable_python" = "yes"])

# libcanberra

PKG_CHECK_MODULES([CANBERRA_GTK],[libcanberra-gtk3 >= $LIBCANBERRA_GTK_REQUIRED],[],
    [AC_MSG_ERROR([Sound support was requested, but libcanberra-gtk not found.])])

# ********

AM_CFLAGS="$AM_CFLAGS $WARN_CFLAGS"

# ****
# i18n
# ****

GETTEXT_PACKAGE=gnome-games
AC_SUBST(GETTEXT_PACKAGE)
AC_DEFINE_UNQUOTED(GETTEXT_PACKAGE,"$GETTEXT_PACKAGE", [The gettext package name])
AM_GLIB_GNU_GETTEXT

IT_PROG_INTLTOOL([0.35.0])

# *************
# Documentation
# *************

YELP_HELP_INIT

# *************
# setgid checks
# *************

AC_ARG_ENABLE([setgid],
  [AS_HELP_STRING([--disable-setgid],
    [Disable the use of setgid binaries])],
  [case "${enableval}" in
    yes) setgid=true ;;
    no)  setgid=false ;;
    *) AC_MSG_ERROR([bad value ${enableval} for --disable-setgid]) ;;
   esac],
  [if test "$platform_win32" = "yes"; then
     enable_setgid=no
     setgid=false
   else
     enable_setgid=yes
     setgid=true
   fi])

scoredir='${localstatedir}/games'
scores_group=games
scores_user=games

if test "$enable_setgid" = "yes"; then
  AC_DEFINE([ENABLE_SETGID],[1],[Define if use of setgid binaries is enabled])

  AC_ARG_WITH(scores-group,
    AS_HELP_STRING([--with-scores-group=group],
      [Group for the high score tables and binaries]),
    scores_group="$withval",scores_group="games")
  AC_ARG_WITH(scores-user,
    AS_HELP_STRING([--with-scores-user=user],
      [User for the high score tables]),
    scores_user="$withval",scores_user="games")
fi

AM_CONDITIONAL([ENABLE_SETGID],[test "$enable_setgid" = "yes"])

AC_SUBST(setgid)
AC_SUBST(scores_group)
AC_SUBST(scores_user)
AC_SUBST(scoredir)

##############################################

AC_SUBST([AM_CPPFLAGS])
AC_SUBST([AM_CFLAGS])
AC_SUBST([AM_LDFLAGS])

##############################################
##############################################

AC_CONFIG_FILES([
Makefile
po/Makefile.in
gnect/Makefile
gnect/src/Makefile
gnect/data/Makefile
gnect/data/icons/Makefile
gnect/data/gnect.desktop.in
gnect/help/Makefile
gnomine/Makefile
gnomine/data/Makefile
gnomine/data/icons/Makefile
gnomine/data/gnomine.desktop.in
gnomine/help/Makefile
gnomine/src/Makefile
swell-foop/Makefile
swell-foop/data/Makefile
swell-foop/data/icons/Makefile
swell-foop/data/themes/Makefile
swell-foop/data/themes/colors/Makefile
swell-foop/data/themes/shapesandcolors/Makefile
swell-foop/data/swell-foop.desktop.in
swell-foop/help/Makefile
swell-foop/src/Makefile
gnome-mahjongg/Makefile
gnome-mahjongg/data/Makefile
gnome-mahjongg/data/icons/Makefile
gnome-mahjongg/data/gnome-mahjongg.desktop.in
gnome-mahjongg/help/Makefile
gnome-mahjongg/src/Makefile
gtali/Makefile
gtali/data/Makefile
gtali/data/icons/Makefile
gtali/data/gtali.desktop.in
gtali/src/Makefile
gtali/help/Makefile
iagno/Makefile
iagno/data/Makefile
iagno/data/icons/Makefile
iagno/data/iagno.desktop.in
iagno/help/Makefile
iagno/src/Makefile
gnotravex/Makefile
gnotravex/data/Makefile
gnotravex/data/icons/Makefile
gnotravex/data/gnotravex.desktop.in
gnotravex/src/Makefile
gnotravex/help/Makefile
gnotski/Makefile
gnotski/data/Makefile
gnotski/data/icons/Makefile
gnotski/data/gnotski.desktop.in
gnotski/src/Makefile
gnotski/help/Makefile
glines/Makefile
glines/data/Makefile
glines/data/icons/Makefile
glines/data/glines.desktop.in
glines/src/Makefile
glines/help/Makefile
lightsoff/Makefile
lightsoff/src/Makefile
lightsoff/data/Makefile
lightsoff/data/lightsoff.desktop.in
lightsoff/help/Makefile
quadrapassel/Makefile
quadrapassel/data/Makefile
quadrapassel/data/icons/Makefile
quadrapassel/data/quadrapassel.desktop.in
quadrapassel/help/Makefile
quadrapassel/src/Makefile
gnobots2/Makefile
gnobots2/data/Makefile
gnobots2/data/icons/Makefile
gnobots2/data/gnobots2.desktop.in
gnobots2/help/Makefile
gnobots2/src/Makefile
gnibbles/Makefile
gnibbles/data/Makefile
gnibbles/data/icons/Makefile
gnibbles/data/levels/Makefile
gnibbles/data/pix/Makefile
gnibbles/data/gnibbles.desktop.in
gnibbles/help/Makefile
gnibbles/src/Makefile
glchess/Makefile
glchess/data/Makefile
glchess/data/icons/Makefile
glchess/data/pieces/Makefile
glchess/data/pieces/3d/Makefile
glchess/data/pieces/fancy/Makefile
glchess/data/pieces/simple/Makefile
glchess/data/textures/Makefile
glchess/data/glchess.desktop.in
glchess/help/Makefile
glchess/src/Makefile
gnome-sudoku/Makefile
gnome-sudoku/src/Makefile
gnome-sudoku/src/lib/Makefile
gnome-sudoku/src/lib/defs.py
gnome-sudoku/src/lib/gtk_goodies/Makefile
gnome-sudoku/data/Makefile
gnome-sudoku/data/icons/Makefile
gnome-sudoku/data/gnome-sudoku.desktop.in
gnome-sudoku/help/Makefile
])
AC_OUTPUT

echo "
Configuration:

    Source code location:  ${srcdir}
    Compiler:              ${CC}
    Platform:              ${with_platform}"

echo "
    Games to be compiled:  ${gamelist}

    Using SQLite:          ${have_sqlite}
    Use setgid binaries:   ${enable_setgid}
    Scores user:           ${scores_user}
    Scores & setgid group: ${scores_group}
    Introspection data:    ${enable_introspection}
"

if grep "$scores_group:" /etc/group > /dev/null; then
:;
else
echo
echo "Warning: The $scores_group group does not exist. Installation will"
echo "         succeed, but high score logging will not work. To specify a"
echo "         different group use the --with-scores-group option."
echo
fi

