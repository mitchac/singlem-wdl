FROM continuumio/miniconda3:latest
ENV USER=root
RUN apt update && \
      apt-get install -y curl unzip && \
      curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
      unzip awscliv2.zip && \
      ./aws/install
      
RUN conda create -c conda-forge -c bioconda -c defaults -n env python git extern pigz sra-tools google-cloud-sdk
RUN echo "source activate env" > ~/.bashrc
ENV PATH /opt/conda/envs/env/bin:$PATH

RUN git clone https://github.com/wwood/ena-fast-download && cd ena-fast-download && git checkout e1b7e73
