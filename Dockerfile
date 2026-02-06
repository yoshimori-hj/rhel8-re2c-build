ARG VERSION=4.4

FROM registry.access.redhat.com/ubi8/ubi
ARG VERSION
RUN dnf update -y
RUN dnf install -y git python3.12 cmake gcc gcc-c++ diffutils findutils gdb file
WORKDIR /opt/src
RUN git clone https://github.com/skvadrik/re2c.git re2c-${VERSION}
RUN cd /opt/src/re2c-${VERSION} && git checkout ${VERSION}
WORKDIR /opt/build/re2c-${VERSION}
RUN cmake -S /opt/src/re2c-${VERSION} -B . \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DRE2C_BUILD_LIBS=ON \
    -DCMAKE_INSTALL_PREFIX=/opt/re2c-${VERSION}
RUN make -j4
RUN make check
RUN make install
WORKDIR /opt
RUN find re2c-${VERSION} -type f -exec sh -exc 'f=`file \$* | grep ": *ELF\|:.* ar archive" | awk -F: "{print \\\$1}"`; for file in $f; do mkdir -p /opt/debug/`dirname $file`; strip --only-keep-debug -o /opt/debug/$file $file; strip --strip-debug --strip-unneeded $file; done' -- {} +
RUN find /opt/debug -type f -exec sh -exc '(while f=$1 && shift; do gdb --nx -q -ex "file $f" -ex "info sources" -ex "quit" | awk "BEGIN{RS=\",\"}{if(\$1~/\/opt\/[sb]/ && (getline junk < \$1) >= 0) print \$1;}"; done) | sort | uniq | xargs realpath | tar -czf /opt/re2c-${VERSION}-rhel8-debugsource.tar.gz -T -' -- {} +
RUN tar zcf re2c-${VERSION}-rhel8.tar.gz re2c-${VERSION}
RUN cd /opt/debug && tar zcf ../re2c-${VERSION}-rhel8-debug.tar.gz re2c-${VERSION}
