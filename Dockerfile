FROM nvidia/cuda:11.7.0-runtime-ubuntu22.04

ENV USE_TORCH=1
ENV PYTHONPATH=.

ARG DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
RUN apt-get update && apt-get install -y --no-install-recommends \
        git \
        curl \
        ncdu \
        iotop \
        bzip2 \
        python3-venv \
        python3-pip \
        python3-opencv \
        libglib2.0-0 \
        libgl1-mesa-glx \
        build-essential \
        libopencv-dev &&\
    apt-get clean && apt-get autoclean

# This is needed for patchmatch support
RUN cd /usr/lib/x86_64-linux-gnu/pkgconfig/ &&\
   ln -sf opencv4.pc opencv.pc
#
# ENV PATH /opt/conda/bin:$PATH
#
# RUN curl -fsSL -v -o ~/anaconda.sh -O "https://repo.anaconda.com/archive/Anaconda3-2022.10-Linux-x86_64.sh"
# RUN chmod +x ~/anaconda.sh && \
#     bash ~/anaconda.sh -b -p /opt/conda && \
#     rm ~/anaconda.sh
# RUN /opt/conda/bin/conda update -n base -c defaults conda


ARG WORKDIR=/invokeai
WORKDIR ${WORKDIR}

ENV VIRTUAL_ENV=${WORKDIR}/.venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

COPY . .

RUN python3 -m venv ${VIRTUAL_ENV} &&\
    pip install -r requirements.txt &&\
    pip install -e .

# build patchmatch
RUN python -c "from patchmatch import patch_match"

## workaround for non-existent initfile when runtime directory is mounted; see #1613
RUN touch /root/.invokeai

RUN useradd -m invokeai
WORKDIR /home/invokeai

CMD ["-c", "python3 scripts/invoke.py --web --host 0.0.0.0"]
