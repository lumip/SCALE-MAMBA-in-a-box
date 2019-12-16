#######################################################################################################
################################# Container for building dependencies #################################
#######################################################################################################
FROM alpine:edge AS pre-build-container

LABEL maintainer="lukas.m.prediger@aalto.fi"

# Install required packages
RUN apk add g++ yasm m4 make libtool

RUN mkdir /src /built
WORKDIR /src

# Fetch, compile and install MPIR 3.0.0
RUN wget --quiet 'http://mpir.org/mpir-3.0.0.tar.bz2' && \
    tar xf mpir-3.0.0.tar.bz2 && \
    cd mpir-3.0.0 && \
    ./configure --enable-cxx --prefix="/built/mpir" && \
    make && \
    make check && \
    make install && \
    cd ../ && \
    rm -rf mpir-3.0.0*


#######################################################################################################
################################# Container for building SCALE-MAMBA ##################################
#######################################################################################################
FROM pre-build-container AS build-container

LABEL maintainer="lukas.m.prediger@aalto.fi"

RUN apk add libexecinfo-dev openssl-dev
RUN apk add --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing crypto++-dev

# Load SCALE-MAMBA source
COPY ["SCALE-MAMBA/", "SCALE-MAMBA"]
WORKDIR /src/SCALE-MAMBA

RUN cp CONFIG CONFIG.mine && \
    echo 'ROOT = /src/SCALE-MAMBA' >> CONFIG.mine && \
    echo 'OSSL = ""' >> CONFIG.mine

# Compile with DEBUG or RELEASE flags?
ARG MODE="RELEASE"

RUN if [ "$MODE" = "DEBUG" ] ; then \
        echo 'FLAGS = -DSH_DEBUG -DDEBUG -DMAX_MOD_SZ=$(MAX_MOD) -DDETERMINISTIC' >> CONFIG.mine; \
    else \
        echo 'FLAGS = -DMAX_MOD_SZ=$(MAX_MOD)'; \
    fi
    
# Compile!
RUN export C_INCLUDE_PATH="/built/mpir/include/:${C_INCLUDE_PATH}" && \
    export CPLUS_INCLUDE_PATH="/built/mpir/include/:${CPLUS_INCLUDE_PATH}" && \
    export LIBRARY_PATH="/built/mpir/lib/:${LIBRARY_PATH}" && \
    export LD_LIBRARY_PATH="/built/mpir/lib:${LD_LIBRARY_PATH}" && \
    echo $CPLUS_INCLUDE_PATH && \
    make progs

#######################################################################################################
################ Final "published" container, containing only the compiled executables ################
#######################################################################################################
FROM alpine:edge AS bundle

LABEL maintainer="lukas.m.prediger@aalto.fi"
LABEL version="1.6.0"

RUN apk add openssl python
RUN apk add --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing crypto++

WORKDIR /home
COPY --from=build-container ["/built/mpir/include/*", "/usr/include/"]
COPY --from=build-container ["/built/mpir/lib/*", "/usr/lib/"]
COPY --from=build-container ["/src/SCALE-MAMBA/License.txt", "/home"]
COPY --from=build-container ["/src/SCALE-MAMBA/Player.x", "src/SCALE-MAMBA/Setup.x", "/usr/bin/"]
COPY --from=build-container ["/src/SCALE-MAMBA/compile.py", "/home/bin/"]
COPY --from=build-container ["/src/SCALE-MAMBA/Compiler/", "/src/SCALE-MAMBA/compile.py", "/home/bin/Compiler/"]
RUN ln -s /home/bin/compile.py /usr/bin/compile

RUN mkdir /home/Cert-Store /home/Data

FROM bundle AS quickstart-bundle

COPY ["SCALE-MAMBA/Auto-Test-Data/Cert-Store/*", "/home/Cert-Store/"]

FROM bundle