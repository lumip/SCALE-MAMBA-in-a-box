# SCALE and MAMBA in a box

A docker container script for the SCALE-MAMBA secure multi-party computation framework by the KU Leuven ( [website](https://homes.esat.kuleuven.be/~nsmart/SCALE/), [github](https://github.com/KULeuven-COSIC/SCALE-MAMBA) ).

The container is created with the aim of facilitating easy deployment and fully automates the compilation process. It also provides a quickstart configuration to immediately get going with the framework.

*Disclaimer: This work is completely independent of the SCALE-MAMBA framework. I claim no ownership of of the latter or affiliation with its authors.*

The last version of SCALE-MAMBA to work with the build process is 1.6. The version numbers of the containers follow those of the framework.

## How To Build

We include the SCALE-MAMBA repository as a submodule, so make sure to initialise submodules:
```
git clone --recursive https://github.com/lumip/SCALE-MAMBA-in-a-box.git
cd SCALE-MAMBA-in-a-box
```
or
```
git clone https://github.com/lumip/SCALE-MAMBA-in-a-box.git
cd SCALE-MAMBA-in-a-box
git submodule init
git submodule update
```

To build the container **containing only the executables**
```
docker build -t lumip/scale-mamba .
```

To build the container in **quickstart configuration**, containing executables as well as configuration files:
```
docker build --target quickstart-bundle --build-arg PARTIES=2 -t lumip/scale-mamba:quickstart .
```
where `PARTIES` is the number of parties involved in the computation. Valid values for which quickstart configuration is available are 2 to 5. (Default is 2).

You can also supply the addition `--build-args MODE=DEBUG` argument to the build command, which will the framework in debug configuration with more verbose output and debugging symbols.

## Container Structure

The container hosts the framework executables in `/usr/bin`, so they are globally available. A brief overview of the executables is as follows:

- `Player.x` is the main executable that runs a party instance (a Player) participating in a secure multi-party computation session.
- `Setup.x` is used to configure the framework (set addresses of remote parties and their certificates, configure secret sharing scheme, etc..)
- `compile` is used to compile MAMBA code into instruction tapes interpetable by `Player.x`.

For more detailed information please refer to the [framework documentation](https://homes.esat.kuleuven.be/~nsmart/SCALE/Documentation.pdf).

The workspace folder, in which all data the framework requires is in is `/home`. The framework expects the following directory structure

- `/home/Certs-Store/` contains OpenSSL readable certificates for all parties
- `/home/Data/` contains configuration files
- `/home/Circuits/` contains descriptions of built-in circuits (such as addition, subtraction, ...) used by the framework
- `/home/Programs` contains programs (i.e., MAMBA code) to be executed securly with the framework.

When using the plain container (without quickstart configuration), it is recommended to mount docker volumes at `/home/Certs-Store` and `/home/Data` and bind-mount your MAMBA code location to `/home/Programs`. To read on how to set up the framework and generate the configuration files using `Setup.x`, please again refer to the [framework documentation](https://homes.esat.kuleuven.be/~nsmart/SCALE/Documentation.pdf).

When using the container in quickstart configuration, you only need to mount your programs into `/home/Programs`.

## Details on Quickstart Configuration

Quickstart configuration is a slightly more flexible variant of the "idiot's installation" of the original framework. It is intended mostly for testing purposes within a docker network. If you plan to use these containers in a production setting, please set up the framework from scratch.

Quickstart configuration provides a full configuration for up to 5 parties using the Shamir secret sharing scheme (with `t=0`, i.e., all parties need to collaborate to recover the secret) and a 128 bit modulus for shared values.

The configuration assumes that the parties are hosted in containers named `mambaX` where `X` is the number of the respective party, starting from 1.

## Example: Running in Quickstart Configuration

Assume we want to run a program that is located in `/my-mamba-program/` in a 2-party quickstart configuration:

```
# build container
docker build --target quickstart-bundle --build-arg PARTIES=2 -t lumip/scale-mamba:quickstart <PATH_TO_THIS_REPOSITORY>

# compile MAMBA program
docker run --rm --volume /my-mamba-program/:/home/Programs/my-mamba-program/ lumip/scale-mamba:quickstart compile Programs/my-mamba-program

# create docker network
docker network create mamba-net

# run first party
docker run --rm --name mamba1 --network mamba-net --volume /my-mamba-program:/home/Programs/my-mamba-program lumip/scale-mamba:quickstart Player.x 0 Programs/my-mamba-program

# run second party (in separate terminal)
docker run --rm --name mamba2 --network mamba-net --volume /my-mamba-program:/home/Programs/my-mamba-program lumip/scale-mamba:quickstart Player.x 1 Programs/my-mamba-program

# wait until computation finished

# clean up
docker network rm mamba-net
```

Note that the names for the containers ( `mamba1` and `mamba2`) are crucial as they determine the network addresses for the container instances in the docker network and the framework is configured to expect these names.
