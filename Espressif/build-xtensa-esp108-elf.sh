#!/bin/bash
# Author: Fabien Poussin
# Last edit: 20/11/2014
#
# Modified: Mikhail Grigorev
# Last edit: 25/12/2015
#
# You will need the following mingw32/64 or equivalent linux packages to build it:
# msys gcc msys-coreutils msys-wget msys-autoconf msys-automake msys-mktemp
#
# Use mingw-get to install these.
# run this script from msys's or any unix console.

JOBS=-j1

TARGET=xtensa-esp108-elf

XTTC=$PWD/$TARGET
XTBP=$PWD/build
XTDLP=$PWD/dl

MINGW_PATH=c:/mingw
PATH=$XTTC/bin:$PATH

GMP="gmp-6.0.0a"
MPFR="mpfr-3.1.2"
MPC="mpc-1.0.2"
GCC="gcc-5.1.0"
BINUTILS="binutils-2.25"
NEWLIB="newlib-2.0.0"

DOWNLOAD=0
EXTRACT=0
BASELIBS=0
RECONF=1
REBUILD=1
REINSTALL=1

while true ; do
    case "$1" in
        --nodownloads) DOWNLOAD=0 ; echo "Not downloading anything" ; shift ;;
        --noextract) EXTRACT=0 ; echo "Never extract archive" ; shift ;;
        --noreconf) RECONF=0 ; echo "Not reconfiguring anything" ; shift ;;
        --norebuild) REBUILD=0 ; echo "Not rebuilding anything" ; shift ;;
        --noreinstall) REINSTALL=0 ; echo "Not reinstalling anything" ; shift ;;
        --nobaselibs) BASELIBS=0 ; echo "Not building/installing support libs" ; shift ;;
        *) shift ; break ;;
    esac
done

# check if mingw is mounted, mount if needed
df /mingw
if [ $? -gt 0 ]; then
  mount $MINGW_PATH /mingw
  if [ $? -gt 0 ]; then
    echo "Failed to mount mingw using"
    echo $MINGW_PATH
    exit 1
  fi
  PATH=/mingw/bin:$PATH
fi

#find $XTDLP/*/build -type d | xargs rm -rf
mkdir -p $XTTC $XTDLP $XTBP

if [ $DOWNLOAD -gt 0 ]; then

  echo "Downloading..."

  echo "GMP"
  wget -c http://ftp.gnu.org/gnu/gmp/$GMP.tar.bz2 -P $XTDLP
  echo "MPFR"
  wget -c http://ftp.gnu.org/gnu/mpfr/$MPFR.tar.bz2 -P $XTDLP
  echo "MPC"
  wget -c http://ftp.gnu.org/gnu/mpc/$MPC.tar.gz -P $XTDLP
  echo "Binutils"
  wget -c http://dl.programs74.ru/get.php?file=esp32-$BINUTILS -O $XTDLP/$BINUTILS.tar.gz
  echo "Newlib"
  wget -c http://dl.programs74.ru/get.php?file=esp32-$NEWLIB -O $XTDLP/$NEWLIB.tar.gz
  echo "GCC"
  wget -c http://dl.programs74.ru/get.php?file=esp32-$GCC -O $XTDLP/$GCC.tar.gz

fi

if [ $EXTRACT -gt 0 ]; then

  echo "Extracting..."

  echo "GMP"
  tar xf $XTDLP/$GMP.tar.bz2 -C $XTDLP/
  echo "MPFR"
  tar xf $XTDLP/$MPFR.tar.bz2 -C $XTDLP/
  echo "MPC"
  tar xf $XTDLP/$MPC.tar.gz -C $XTDLP/

  echo "GCC"
  tar xf $XTDLP/$GCC.tar.gz -C $XTDLP/
  echo "Newlib"
  tar xf $XTDLP/$NEWLIB.tar.gz -C $XTDLP/
  echo "Binutils"
  tar xf $XTDLP/$BINUTILS.tar.gz -C $XTDLP/

  echo "Extract path fixes..."

  # Fixes in case archive name != folder name
  find $XTDLP -maxdepth 1 -type d -name gmp-* | xargs -i mv -v {} $XTDLP/$GMP
  find $XTDLP -maxdepth 1 -type d -name mpfr-* | xargs -i mv -v {} $XTDLP/$MPFR
  find $XTDLP -maxdepth 1 -type d -name mpc-* | xargs -i mv -v {} $XTDLP/$MPC

fi

mkdir -p $XTDLP/$GMP/build $XTDLP/$MPC/build $XTDLP/$MPFR/build 
mkdir -p $XTDLP/$GCC/{build-1,build-2} 
mkdir -p $XTDLP/$NEWLIB/build $XTDLP/$BINUTILS/build

set -e

cd $XTDLP/$GMP/build
if [ $BASELIBS -gt 0 -o ! -f .built ]; then
  echo "Buidling GMP..."
  if [ $RECONF -gt 0 -o ! -f .configured ]; then
    rm -f .configured
    ../configure --prefix=$XTBP/gmp --disable-shared --enable-static
    touch .configured
  fi
  if [ $REBUILD -gt 0 -o ! -f .built ]; then
    rm -f .built
    nice make $JOBS
    touch .built
  fi
  if [ $REINSTALL -gt 0 -o ! -f .installed ]; then
    rm -f .installed
    make install
    touch .installed
  fi
fi

cd $XTDLP/$MPFR/build
if [ $BASELIBS -gt 0 -o ! -f .built ]; then
  echo "Buidling MPFR"
  if [ $RECONF -gt 0 -o ! -f .configured ]; then
    rm -rf .configured
    ../configure --prefix=$XTBP/mpfr --with-gmp=$XTBP/gmp --disable-shared --enable-static
    touch .configured
  fi
  if [ $REBUILD -gt 0 -o ! -f .built ]; then
    rm -f .built
    nice make $JOBS
    touch .built
  fi
  if [ $REINSTALL -gt 0 -o ! -f .installed ]; then
    rm -f .installed
    make install
    touch .installed
  fi
fi

cd $XTDLP/$MPC/build
if [ $BASELIBS -gt 0 -o ! -f .built ]; then
  echo "Buidling MPC..."
  if [ $RECONF -gt 0 -o ! -f .configured ]; then
    rm -f .configured
    ../configure --prefix=$XTBP/mpc --with-mpfr=$XTBP/mpfr --with-gmp=$XTBP/gmp --disable-shared --enable-static
    touch .configured
  fi
  if [ $REBUILD -gt 0 -o ! -f .built ]; then
    rm -f .built
    nice make $JOBS
    touch .built
  fi
  if [ $REINSTALL -gt 0 -o ! -f .installed ]; then
    rm -f .installed
    make install
    touch .installed
  fi
fi

echo "Buidling Binutils..."
cd $XTDLP/$BINUTILS/build
if [ $RECONF -gt 0 -o ! -f .configured ]; then
  rm -f .configured
  ../configure --prefix=$XTTC --target=$TARGET --enable-werror=no  --enable-multilib --disable-nls --disable-shared --disable-threads --with-gcc --with-gnu-as --with-gnu-ld
  touch .configured
fi
if [ $REBUILD -gt 0 -o ! -f .built ]; then
  rm -f .built
  nice make $JOBS
  touch .built
fi
if [ $REINSTALL -gt 0 -o ! -f .installed ]; then
  rm -f .installed
  make install
  touch .installed
fi

echo "Building first stage GCC..."
cd $XTDLP/$GCC/build-1
if [ $RECONF -gt 0 -o ! -f .configured ]; then
  rm -f .configured
  ../configure --prefix=$XTTC --target=$TARGET --enable-multilib --enable-languages=c --with-newlib --disable-nls --disable-shared --disable-threads --with-gnu-as --with-gnu-ld --with-gmp=$XTBP/gmp --with-mpfr=$XTBP/mpfr --with-mpc=$XTBP/mpc  --disable-libssp --without-headers --disable-__cxa_atexit --enable-decimal-float=yes
  touch .configured
fi
if [ $REBUILD -gt 0 -o ! -f .built ]; then
  rm -f .built
  nice make $JOBS all-gcc
  touch .built
fi
if [ $REINSTALL -gt 0 -o ! -f .installed ]; then
  rm -f .installed
  make install-gcc
  touch .installed
fi

echo "Buidling Newlib..."
cd $XTDLP/$NEWLIB/build
if [ $RECONF -gt 0 -o ! -f .configured ]; then
  rm -f .configured
  ../configure  --prefix=$XTTC --target=$TARGET --enable-multilib --with-gnu-as --with-gnu-ld --disable-nls --disable-newlib-io-c99-formats --disable-newlib-io-long-long --disable-newlib-io-float --disable-newlib-io-long-double --disable-newlib-supplied-syscalls --enable-target-optspace
  touch .configured
fi
if [ $REBUILD -gt 0 -o ! -f .built ]; then
  rm -f .built
  nice make $JOBS
  touch .built
fi
if [ $REINSTALL -gt 0 -o ! -f .installed ]; then
  rm -rf .installed
  make install
  touch .installed
fi

echo "Building final GCC..."
cd $XTDLP/$GCC/build-2
if [ $RECONF -gt 0 -o ! -f .configured ]; then
  rm -f .configured
  ../configure --prefix=$XTTC --target=$TARGET --enable-multilib --disable-nls --disable-shared --disable-threads --with-gnu-as --with-gnu-ld --with-gmp=$XTBP/gmp --with-mpfr=$XTBP/mpfr --with-mpc=$XTBP/mpc --enable-languages=c,c++ --with-newlib --disable-libssp --disable-__cxa_atexit --enable-decimal-float=yes
  touch .configured
fi
if [ $REBUILD -gt 0 -o ! -f .built ]; then
  rm -f .built
  nice make $JOBS
  touch .built
fi
if [ $REINSTALL -gt 0 -o ! -f .installed ]; then
  rm -rf .installed
  make install
  touch .installed
fi

if [ -d "$XTTC/$TARGET/bin/" ]; then
  if [ -f "$XTTC/bin/$TARGET-g++.exe" ]; then
    cp "$XTTC/bin/$TARGET-g++.exe" "$XTTC/$TARGET/bin/g++.exe"
  fi
  if [ -f "$XTTC/bin/$TARGET-gcc.exe" ]; then
    cp "$XTTC/bin/$TARGET-gcc.exe" "$XTTC/$TARGET/bin/gcc.exe"
  fi
  if [ -f "$XTTC/bin/$TARGET-c++.exe" ]; then
    cp "$XTTC/bin/$TARGET-c++.exe" "$XTTC/$TARGET/bin/c++.exe"
  fi
fi

if [ -d "$MINGW_PATH/bin/" ]; then
  if [ -d "$XTTC/bin/" ]; then
    if [ -f "$MINGW_PATH/bin/libgcc_s_dw2-1.dll" ]; then
      cp "$MINGW_PATH/bin/libgcc_s_dw2-1.dll" "$XTTC/bin/"
    fi
    if [ -f "$MINGW_PATH/bin/zlib1.dll" ]; then
      cp "$MINGW_PATH/bin/zlib1.dll" "$XTTC/bin/"
    fi
  fi
  if [ -d "$XTTC/$TARGET/bin/" ]; then
    if [ -f "$MINGW_PATH/bin/libgcc_s_dw2-1.dll" ]; then
      cp "$MINGW_PATH/bin/libgcc_s_dw2-1.dll" "$XTTC/$TARGET/bin/"
    fi
    if [ -f "$MINGW_PATH/bin/zlib1.dll" ]; then
      cp "$MINGW_PATH/bin/zlib1.dll" "$XTTC/$TARGET/bin/"
    fi
  fi
fi

echo "Done!"
echo "Compiler is located at $XTTC"