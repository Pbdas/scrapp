#!/bin/bash
DATE=`date '+%Y-%m-%d-%H:%M'`

BASE=$(cd `dirname "${BASH_SOURCE[0]}"`/.. && pwd)
REF=${BASE}/msa/reference.fasta
QRY=${BASE}/msa/query.fasta
TREE=${BASE}/tree/reference.newick
MODEL=${BASE}/tree/eval.raxml.bestModel
JPLACE=${BASE}/placed/epa_result.jplace
SC=${BASE}/script

NUM_THREADS=40
SEED=4242


echo "start at `date`"

cd ${SC}

# set -e
# write the csv header
echo "run,seq_length,mut_rate,species,sample_size,pop_size,prune_fract,krd,norm_krd,norm_norm_krd,norm_unit_krd,abs_err_sum,abs_err_mean,abs_err_med,rel_err_sum,rel_err_mean,rel_err_med,norm_err_sum,norm_err_mean,norm_err_med" > results.csv

run=0
for seq_length in 1000 5000 10000; do
  for prune_fract in 0.2; do
    for pop_size in 1e6; do
      for species in 60; do
        for mut_rate in 1e-8; do
          for sample_size in 50; do
            for i in {1..10}; do
              echo "Starting run ${run}!"

              scrapp_mode=rootings

              SCRAPP_SIM_CURDIR=${BASE}/runs/scrapp_mode_${scrapp_mode}/seq_length_${seq_length}/prune_fract_${prune_fract}/pop_size_${pop_size}/species_${species}/mut_rate_${mut_rate}/sample_size_${sample_size}/iter_${i}
              export SCRAPP_SIM_CURDIR
              rm -rf ${SCRAPP_SIM_CURDIR}/* 2> /dev/null

              printf "${run},${seq_length},${mut_rate},${species},${sample_size},${pop_size},${prune_fract}," >> results.csv

              # echo "  generate the tree..."
              ./msprime.sh --seq-length ${seq_length} --mutation-rate ${mut_rate} --species ${species} --population-size ${pop_size} --prune ${prune_fract} --sample-size ${sample_size} 1> /dev/null
              # echo "  tree done!"

              # generate the sequences and split into query and ref set
              # echo "  generate the sequences..."
              ./seqgen.sh -l ${seq_length} 1> /dev/null
              # echo "  sequences done!"

              # infer model params
              # echo "  infer model params..."
              #  --blmin 1e-7 --blmax 5000
              ./eval_reftree.sh --threads ${NUM_THREADS} --seed --opt-branches off --force perf 1> /dev/null
              # echo "  model params done!"

              # run placement
              # echo "  place..."
              ./epa.sh --threads ${NUM_THREADS} 1> /dev/null
              # echo "  placement done!"

              # run scrapp
              # echo "  running scrapp..."
              case "${scrapp_mode}" in
                rootings )
                  ./scrapp.sh --num-threads ${NUM_THREADS} --seed ${SEED} 1> /dev/null
                  ;;
                bootstrap )
                  ./scrapp.sh --num-threads ${NUM_THREADS} --seed ${SEED} --bootstrap 1> /dev/null
                  ;;
                outgroup )
                  ./scrapp.sh --num-threads ${NUM_THREADS} --ref-align-outgrouping ${SCRAPP_SIM_CURDIR}/msa/reference.fasta 1> /dev/null
                  ;;
                *)
                  echo "invalid scrapp_mode, aborting"
                  exit 1
              esac
              # echo "  scrapp done!"

              # print statistic
              # echo "  printing statistic..."
              ./compare_species_counts ${SCRAPP_SIM_CURDIR}/delimit/summary.newick ${SCRAPP_SIM_CURDIR}/tree/annot_reference.newick 1 >> results.csv
              printf "\n" >> results.csv
              # echo "  statistic done!"

              let run+=1

            done # runs
          done # sample_size
        done # mut_rate
      done # species
    done # pop_size
  done # prune_fract
done # seq_length

echo "end at `date`"
