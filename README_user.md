# How to use the WRF Docker Containers

This requires the use of the the docker utility: 
docker.com

## Get the WRF container infrastructure

1. Docker is needed   
The WRF container build and run requires the use of docker. This may be downloaded at `docker.com`.

2. Clone the WRF-specific wrf-coop repository. This is the code that builds the container for WRF.
```
git clone https://github.com/davegill/wrf-coop
cd wrf-coop
```

## Prepare the docker image

1. Edit the runtime files for docker: `Dockerfile` and `Dockerfile-NMM`. 

Here is the entire Dockerfile for ARW: `Dockerfile`:
```
#
FROM davegill/wrf-coop:eighthtry
MAINTAINER Dave Gill <gill@ucar.edu>

RUN git clone _FORK_/_REPO_.git WRF \
  && cd WRF \
  && git checkout _BRANCH_ \
  && cd ..

RUN git clone https://github.com/davegill/SCRIPTS.git SCRIPTS \
  && cp SCRIPTS/rd_l2_norm.py . && chmod 755 rd_l2_norm.py \
  && cp SCRIPTS/script.csh .    && chmod 755 script.csh    \
  && ln -sf SCRIPTS/Namelists . 

RUN curl -SL https://www2.mmm.ucar.edu/wrf/dave/sbm.tar.gz | tar -xzC /wrf

VOLUME /wrf
CMD ["/bin/tcsh"]
```

Here is the entire Dockerfile for NMM: `Dockerfile-NMM`:
```
#
FROM davegill/wrf-coop:sixthtry
MAINTAINER Dave Gill <gill@ucar.edu>

RUN git clone _FORK_/_REPO_.git WRF \
  && cd WRF \
  && git checkout _BRANCH_ \
  && cd ..

RUN git clone https://github.com/davegill/SCRIPTS.git SCRIPTS \
  && cp SCRIPTS/rd_l2_norm.py . && chmod 755 rd_l2_norm.py \
  && cp SCRIPTS/script.csh .    && chmod 755 script.csh    \
  && ln -sf SCRIPTS/Namelists . 

VOLUME /wrf
CMD ["/bin/tcsh"]
```

What needs to be modified in both files is the location of the WRF repository to test. That is the section that has:
```
RUN git clone _FORK_/_REPO_.git WRF \
  && cd WRF \
  && git checkout _BRANCH_ \
  && cd ..
```

For example,
```
_FORK_ => https://github.com/davegill
_REPO_ => WRF
_BRANCH_ => irr=3
```

Some people have their repository name as `WRF-1`.

2. Construct the docker image

Using the `Dockerfile` and the `Dockerfile-NMM`, build two docker images. Note that there are indeed periods at the end of these commands!

```
docker build -t wrf_regtest .
docker build -f Dockerfile-NMM -t wrf_nmmregtest .
```

You have to be in the directory where the Dockerfiles are located. The first takes about 5 minutes to complete (several GB of data and code). The second takes about the same amount of time.

## Contruct the docker containers

1. Choose a shared directory for docker

To get data and files between the host OS and the docker container, a user-defined assignment maps a local directory to a directory inside of the WRF container. For example, let's assume that the existing local directory is `/users/gill/DOCKER_STUFF`.

2. Build the containers

```
docker run -it --name ARW -v /users/gill/DOCKER_STUFF:/wrf/wrfoutput wrf_regtest /bin/tcsh
```
You are now in the ARW container.

In another window execute:
```
docker run -it --name NMM -v /users/gill/DOCKER_STUFF:/wrf/wrfoutput wrf_nmmregtest /bin/tcsh
```
You are now in the NMM container.

## Build executables from source, run tests

Now, build the WRF code as usual. From inside the ARW container:

```
cd WRF
configure -d << EOF
34
1
EOF
compile em_real -j 4 >& foo ; tail -20 foo
```

Run a sample test case:

```
cd test/em_real
cp /wrf/Namelists/weekly/em_real/MPI/namelist.input.conus namelist.input
ln -sf /wrf/Data/em_real/* .
mpirun -np 3 --oversubscribe real.exe
mpirun -np 3 --oversubscribe wrf.exe
```
To check the results, you can look at the rsl files:
```
cat rsl.out.0000 | tail -20
ThompMP: read qr_acr_qsV2.dat instead of computing
ThompMP: read freezeH2O.dat instead of computing
Timing for Writing wrfout_d01_2000-01-24_12:00:00 for domain        1:    0.43323 elapsed seconds
d01 2000-01-24_12:00:00  Input data is acceptable to use: wrfbdy_d01
Timing for processing lateral boundary for domain        1:    0.15323 elapsed seconds
 Tile Strategy is not specified. Assuming 1D-Y
WRF TILE   1 IS      1 IE     74 JS      1 JE     20
WRF NUMBER OF TILES =   1
Timing for main: time 2000-01-24_12:03:00 on domain   1:    5.54555 elapsed seconds
Timing for main: time 2000-01-24_12:06:00 on domain   1:    1.12536 elapsed seconds
Timing for main: time 2000-01-24_12:09:00 on domain   1:    1.09936 elapsed seconds
Timing for main: time 2000-01-24_12:12:00 on domain   1:    1.20909 elapsed seconds
Timing for main: time 2000-01-24_12:15:00 on domain   1:    1.17452 elapsed seconds
Timing for main: time 2000-01-24_12:18:00 on domain   1:    1.22385 elapsed seconds
Timing for main: time 2000-01-24_12:21:00 on domain   1:    1.13674 elapsed seconds
Timing for main: time 2000-01-24_12:24:00 on domain   1:    6.43835 elapsed seconds
Timing for main: time 2000-01-24_12:27:00 on domain   1:    1.20856 elapsed seconds
Timing for main: time 2000-01-24_12:30:00 on domain   1:    1.26051 elapsed seconds
Timing for Writing wrfout_d01_2000-01-24_12:30:00 for domain        1:    0.15855 elapsed seconds
d01 2000-01-24_12:30:00 wrf: SUCCESS COMPLETE WRF
```

To visualize the data, copy or link the file to `/wrf/wrfoutput`:
```
cp wrfout_d01_2000-01-24_12:00:00 /wrf/wrfoutput/
```

In the host OS, go to the shared volume directory:
```
cd /users/gill/DOCKER_STUFF
ls -ls
total 78936
78936 -rw-r--r--  1 gill  1500  40413808 Apr  3 14:19 wrfout_d01_2000-01-24_12:00:00
```
