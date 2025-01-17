version 1.0

workflow SingleM_SRA {
  input {
    File SRA_accession_list
    String Download_Method_Order = ""
    File GCloud_User_Key_File
    String GCloud_Project_ID = ""
    String AWS_User_Key_Id = ""
    String AWS_User_Key = ""
  }
  call get_run_from_runlist { 
    input: 
      runlist = SRA_accession_list
    }
  scatter(SRA_accession_num in get_run_from_runlist.runarray) {
    call download_and_extract_ncbi {
      input:
        SRA_accession_num = SRA_accession_num,
        GCloud_User_Key_File = GCloud_User_Key_File,
        GCloud_Project_ID = GCloud_Project_ID,
        AWS_User_Key_Id = AWS_User_Key_Id,
        AWS_User_Key = AWS_User_Key,
        Download_Method_Order = Download_Method_Order
    }
    call singlem {
      input:
        collections_of_sequences = download_and_extract_ncbi.extracted_reads,
        srr_accession = SRA_accession_num
    }
  }
  output {
    Array[File?] SingleM_tables = select_all(singlem.singlem_otu_table_gz)
  }
}

task get_run_from_runlist {
  input { 
    File runlist
    String dockerImage = "ubuntu"
  }
  command <<<
  echo 'hello'
  >>>
  output {
    Array[String] runarray = read_lines(runlist)
  }
  runtime {
    docker: dockerImage
  }
}

task download_and_extract_ncbi {
  input {
    String SRA_accession_num
    String Download_Method_Order
    File GCloud_User_Key_File
    String GCloud_Project_ID
    String dockerImage = "public.ecr.aws/m5a0r7u5/ubuntu-sra-tools:dev7"
    String AWS_User_Key_Id
    String AWS_User_Key
    String kingfisher_extra_args="--allow-paid-from-gcp"
  }
  command <<<
    export AWS_ACCESS_KEY_ID=~{AWS_User_Key_Id}
    export AWS_SECRET_ACCESS_KEY=~{AWS_User_Key}
    ~{
    "python /ena-fast-download/bin/kingfisher -r ~{SRA_accession_num} --gcp-user-key-file ~{GCloud_User_Key_File} --output-format-possibilities fastq -m ~{Download_Method_Order} ~{kingfisher_extra_args}"
    }
  >>>
  runtime {
    docker: dockerImage
  }
  output {
    Array[File] extracted_reads = glob("*.fastq")
  }
}

task singlem {
  input { 
    Array[File] collections_of_sequences
    String srr_accession
    String dockerImage = "public.ecr.aws/m5a0r7u5/singlem-wdl:0.13.2-dev6.cfd1521a"
    String memory = "3.5 GiB"
    String disks = "local-disk 50 SSD"
  }
  command {
    echo starting at `date` >&2 && \
    cat /proc/meminfo >&2 && \
    lscpu >&2 && \
    /opt/conda/envs/env/bin/time /singlem/bin/singlem pipe \
      --forward ~{collections_of_sequences[0]} \
      ~{if length(collections_of_sequences) > 1 then "--reverse ~{collections_of_sequences[1]}" else ""} \
      --archive_otu_table ~{srr_accession}.singlem.json --threads 2 --diamond-package-assignment --assignment-method diamond \
      --diamond-prefilter-performance-parameters '--block-size 0.45' \
      --min_orf_length 72 \
      --singlem-packages `ls -d /pkgs/*spkg` \
      --working-directory-tmpdir && gzip ~{srr_accession}.singlem.json
  }
  runtime {
    docker: dockerImage
    memory: memory
    disks: disks
    cpu: 2
  }
  output {
    File singlem_otu_table_gz = "~{srr_accession}.singlem.json.gz"
  }
}
