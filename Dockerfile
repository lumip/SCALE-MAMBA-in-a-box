#######################################################################################################
################################# Container for building dependencies #################################
#######################################################################################################
FROM ubuntu AS pre-build-container

LABEL maintainer="lukas.m.prediger@aalto.fi"

# Install required packages
RUN apt-get update && apt-get install -y g++ yasm m4 make libtool wget

RUN mkdir /src /built
WORKDIR /src

# Fetch, compile and install MPIR 3.0.0
RUN wget --quiet 'http://mpir.org/mpir-3.0.0.tar.bz2' && \
    tar xf mpir-3.0.0.tar.bz2 && \
    cd mpir-3.0.0 && \
    ./configure --enable-cxx --prefix="/built/mpir" && \
    make -j$(nproc) && \
    make -j$(nproc) check && \
    make install && \
    cd ../ && \
    rm -rf mpir-3.0.0*


#######################################################################################################
################################# Container for building SCALE-MAMBA ##################################
#######################################################################################################
FROM pre-build-container AS build-container

LABEL maintainer="lukas.m.prediger@aalto.fi"

RUN apt-get update && apt-get install -y libssl-dev libcrypto++-dev

# Load SCALE-MAMBA source
COPY ["SCALE-MAMBA/", "/src/SCALE-MAMBA"]
WORKDIR /src/SCALE-MAMBA

RUN cp CONFIG CONFIG.mine && \
    echo 'ROOT = /src/SCALE-MAMBA' >> CONFIG.mine && \
    echo 'OSSL = ' >> CONFIG.mine

# Compile with DEBUG or RELEASE flags?
ARG MODE="RELEASE"

RUN if [ "$MODE" = "DEBUG" ] ; then \
        echo 'FLAGS = -g -DSH_DEBUG -DDEBUG -DMAX_MOD_SZ=$(MAX_MOD) -DDETERMINISTIC' >> CONFIG.mine; \
        echo "OPT = -O0" >> CONFIG.mine; \
        echo "LDFLAGS = -lexecinfo" >> CONFIG.mine; \
    else \
        echo 'FLAGS = -DMAX_MOD_SZ=$(MAX_MOD)'; \
        echo "OPT = -O3" >> CONFIG.mine; \
    fi
    
ENV C_INCLUDE_PATH="/built/mpir/include/:${C_INCLUDE_PATH}" \
    CPLUS_INCLUDE_PATH="/built/mpir/include/:${CPLUS_INCLUDE_PATH}" \
    LIBRARY_PATH="/built/mpir/lib/:${LIBRARY_PATH}" \
    LD_LIBRARY_PATH="/built/mpir/lib:${LD_LIBRARY_PATH}"

RUN make clean && make -j$(nproc) progs

#######################################################################################################
################ Final "published" container, containing only the compiled executables ################
#######################################################################################################
FROM ubuntu AS bundle

LABEL maintainer="lukas.m.prediger@aalto.fi"
LABEL version="1.7.0"

RUN apt-get update && apt-get install -y python cargo libcrypto++ openssl

WORKDIR /home
COPY --from=build-container ["/built/mpir/lib/*", "src/SCALE-MAMBA/libMPC.so", "/usr/lib/"]
COPY --from=build-container ["/src/SCALE-MAMBA/License.txt", "/home"]
COPY --from=build-container ["/src/SCALE-MAMBA/Player.x", "src/SCALE-MAMBA/Setup.x", "/usr/bin/"]
COPY --from=build-container ["/src/SCALE-MAMBA/Circuits/Bristol/", "/home/Circuits/Bristol/"]
# copy old compiler files
COPY --from=build-container ["/src/SCALE-MAMBA/Compiler/", "/home/Compiler/"]
COPY --from=build-container ["/src/SCALE-MAMBA/compile-mamba.py", "/src/SCALE-MAMBA/compile-old.sh", "/home/"]
# copy new compiler files
COPY --from=build-container ["/src/SCALE-MAMBA/Assembler/", "/home/Assembler/"]
COPY --from=build-container ["/src/SCALE-MAMBA/scasm", "/src/SCALE-MAMBA/compile-new.sh", "/src/SCALE-MAMBA/compile.sh", "/home/"]

RUN useradd --no-create-home --user-group scale && chown -R scale:scale /home
USER scale

RUN mkdir /home/Cert-Store /home/Data /home/Programs


#######################################################################################################
####################### Quickstart container, ready to run with preconfiguration ######################
#######################################################################################################
FROM bundle AS quickstart-bundle

COPY ["SCALE-MAMBA/Auto-Test-Data/Cert-Store/*", "/home/Cert-Store/"]
COPY ["SCALE-MAMBA/Programs/", "/home/Programs"]
VOLUME /home/Programs

# number of parties to configure quickstart for (2 to 5); default is 2
ARG PARTIES=2
COPY ["Quickstart-Data/${PARTIES}/", "/home/Data"]
VOLUME /home/Data

############################################
#### bundle container as default target ####
############################################

FROM bundle
