sec=$1
# rw, siha, ...
t=$2
# binary - 5084, ...
b=$3
# host
h=$4
# max dop
p=$5
# yes == warmup
w=$6
# engine == innodb, ...
e=$7
bash run.sh $p /data yes root pw test no $e 2000000 $sec $t yes yes yes $h yes u $w $b
