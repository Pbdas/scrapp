#!/bin/bash
[ -z "$SCRAPP_SIM_CURDIR" ] && echo "SCRAPP_SIM_CURDIR empty! Aborting" && exit

REF=${SCRAPP_SIM_CURDIR}/msa/reference.fasta
QRY=${SCRAPP_SIM_CURDIR}/msa/query.fasta
TREE=${SCRAPP_SIM_CURDIR}/tree/reference.newick

OUT=${SCRAPP_SIM_CURDIR}/tree

cd $OUT
raxml-ng --evaluate --tree ${TREE} --msa ${REF} --model GTR+G --prefix ${OUT}/eval --blmin 1e-10 --blmax 1e5 --redo --blopt nr_safe --force model_lh_impr "$@"
cd -
