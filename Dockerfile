FROM voltagex/aarch64-musl-cross

ENV NCURSES_VERSION 6.2
ENV HTOP_VERSION 3.0.2

COPY patches /patches

ENV PATH "/aarch64--musl--bleeding-edge-2020.08-1/bin/:${PATH}"
ENV TRIPLET "aarch64-buildroot-linux-musl"
ENV STRIP ${TRIPLET}-strip
ENV MAKEFLAGS "-j"
ENV LDFLAGS "-static"

RUN apt update &> /dev/null && apt -y --no-install-recommends install autoconf automake curl make patch strace

RUN mkdir /src
WORKDIR /src

RUN curl https://invisible-mirror.net/archives/ncurses/ncurses-${NCURSES_VERSION}.tar.gz | tar -zxf -
WORKDIR /src/ncurses-${NCURSES_VERSION}

#https://www.raspberrypi.org/forums/viewtopic.php?t=241230#p1559247
RUN patch -p1 < /patches/ncurses-strip.patch

RUN ./configure --host=${TRIPLET} \
    --without-ada \
	--without-tests \
	--disable-termcap \
    --disable-rpath-hack \
	--with-terminfo-dirs="/etc/terminfo:/usr/share/terminfo:/lib/terminfo:/usr/lib/terminfo" \
	--enable-widec \
	--without-debug \
    --prefix=/output/ && make 

RUN make install

RUN echo LISTING
RUN ls -R /output/


WORKDIR /src
RUN curl -L https://bintray.com/htop/source/download_file?file_path=htop-$HTOP_VERSION.tar.gz | tar -zxf -
WORKDIR /src/htop-${HTOP_VERSION}
RUN ./autogen.sh

ENV CFLAGS "-I/output/include"
ENV CPPFLAGS ${CFLAGS} 
ENV LIBRARY_PATH "/output/lib/"
ENV LD_LIBRARY_PATH ${LIBRARY_PATH}

RUN HTOP_NCURSESW_CONFIG_SCRIPT=/output/bin/ncursesw6-config ./configure --prefix=/output --host=${TRIPLET} --enable-cgroup
RUN make && make install

ENTRYPOINT tar -cf - /output/bin/htop
