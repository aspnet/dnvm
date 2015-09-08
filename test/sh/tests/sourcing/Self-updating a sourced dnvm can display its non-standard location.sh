source $COMMON_HELPERS
mkdir nonstandard_path
cp $_DNVM_PATH nonstandard_path/
source nonstandard_path/dnvm.sh
dnvm update-self > update-self-output-nonstandard.txt
rm -rf nonstandard_path
source $_DNVM_PATH
