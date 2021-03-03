version 1.0

workflow SingleM_SRA {
  input {
    File SRA_accession_list
    String smallTaskQueueArn = "DUMMY_FOR_MINIWDL"
    String singlemTaskQueueArn = "DUMMY_FOR_MINIWDL"
  }
  call get_run_from_runlist { 
    input: 
      runlist = SRA_accession_list,
      queueArn = smallTaskQueueArn
    }
  scatter(SRA_accession_num in get_run_from_runlist.runarray) {
    call get_reads_from_run { 
      input: 
        SRA_accession_num = SRA_accession_num,
        queueArn = smallTaskQueueArn
    }
    scatter(download_path_suffix in get_reads_from_run.download_path_suffixes) {
      call download_ascp { 
        input: 
          download_path_suffix = download_path_suffix,
          queueArn = smallTaskQueueArn
      }
    }
    call singlem {
      input:
        collections_of_sequences = download_ascp.collection_of_sequences,
        srr_accession = SRA_accession_num,
        queueArn = singlemTaskQueueArn
    }
  }
  output {
    Array[File] SingleM_tables = select_all(singlem.singlem_otu_table_gz)
  }
}

task get_run_from_runlist {
  input { 
    File runlist
    String dockerImage = "ubuntu"
    String queueArn
  }
  command <<<
  echo 'hello'
  >>>
  output {
    Array[String] runarray = read_lines(runlist)
  }
  runtime {
    docker: dockerImage
    queueArn: queueArn
  }
}

task get_reads_from_run {
  input { 
    String SRA_accession_num
    String dockerImage = "tutum/curl"
    String queueArn
  }
  command <<<
    curl -k 'https://www.ebi.ac.uk/ena/portal/api/filereport?accession=~{SRA_accession_num}&result=read_run&fields=fastq_ftp' \
    | grep -Po 'vol.*?fastq.gz' \
    > ftp.txt
  >>>
  output {
    Array[String] download_path_suffixes = read_lines("ftp.txt")
  }
  runtime {
    docker: dockerImage
    queueArn: queueArn
  }
}

task download_curl {
  input { 
    String download_path_suffix
    String filename = basename(download_path_suffix)
    String dockerImage = "tutum/curl"
    String queueArn
  }
  command <<<
    curl \
    -L \
    ftp://ftp.sra.ebi.ac.uk/~{download_path_suffix} -o ~{filename}
    gunzip -f ~{filename}
    >>>
  runtime {
    docker: dockerImage
    queueArn: queueArn
  }
  output {
    File extracted_read = basename(filename, ".gz")
  }
}

task download_ascp {
  input { 
    String download_path_suffix
    String filename = basename(download_path_suffix)
    String dockerImage = "mitchac/asperacli"
    String queueArn
  }
  command <<<
    ascp -QT -l 300m -P33001 -i /root/.aspera/cli/etc/asperaweb_id_dsa.openssh era-fasp@fasp.sra.ebi.ac.uk:~{download_path_suffix} ~{filename}
    >>>
  runtime {
    docker: dockerImage
    queueArn: queueArn
  }
  output {
    File collection_of_sequences = basename(filename)
  }
}

task singlem {
  input { 
    Array[File] collections_of_sequences
    String srr_accession
    String dockerImage = "public.ecr.aws/m5a0r7u5/singlem-wdl:0.13.2-dev1.dc630726" #"wwood/singlem:dev20210225"
    String queueArn

    String reverse_inputs = if length(collections_of_sequences) > 1 then "--reverse ~{collections_of_sequences[1]}" else ""
  }
  command {
    echo starting at `date` >&2 && \
    /singlem/bin/singlem pipe --forward ~{collections_of_sequences[0]} ~{reverse_inputs} \
      --archive_otu_table ~{srr_accession}.singlem.json --threads 2 --diamond-package-assignment --assignment-method diamond \
      --min_orf_length 72 \
      --singlem-packages `ls -d /pkgs/*spkg` \
     --working-directory-tmpdir && gzip ~{srr_accession}.singlem.json
  }
  runtime {
    docker: dockerImage
    memory: "4 GiB"
    cpu: 2
    queueArn: queueArn
  }
  output {
    File singlem_otu_table_gz = "~{srr_accession}.singlem.json.gz"
  }
}
