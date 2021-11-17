title=$1
m=$2
conf=$3
resdir=$4
rtdir=$5

function catme {
  fn=$1
  if [ -a $fn ]; then
    cat $fn
  else
    echo "$fn not found"
    exit -1
  fi
}

cat <<HeaderEOF
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport"
     content="width=device-width, initial-scale=1, user-scalable=yes">

  <title>${title}</title>
</head>
<body>
HeaderEOF

sections=( l.i0 l.x l.i1 q100.1 q500.1 q1000.1 )
isections=( l.i0 l.x l.i1 )
qsections=( q100.1 q500.1 q1000.1 )
# Ugh, I didn't use the same filename pattern
q2sections=( q.L1.ips100 q.L2.ips500 q.L3.ips1000 )

sectionText=( \
"l.i0: load without secondary indexes" \
"l.x: create secondary indexes" \
"l.i1: continue load after secondary indexes created" \
"q100.1: range queries with 100 insert/s per client" \
"q500.1: range queries with 500 insert/s per client" \
"q1000.1: range queries with 1000 insert/s per client" \
)

# ----- Generate Intro

cat <<IntroEOF
<div id="intro">
<h1 id="intro">Introduction</h1>
<p>
This is a report for the insert benchmark with $title.
It is generated by scripts (bash, awk, sed) and Tufte might not be impressed.
An overview of the insert benchmark <a href="http://smalldatum.blogspot.com/2017/06/the-insert-benchmark.html">is here</a>
and a short update <a href="http://smalldatum.blogspot.com/2020/07/updates-for-insert-benchmark.html">is here</a>.
Below, by <b>DBMS</b>, I mean DBMS+version.config.
An example is <b>my8020.c10b40</b> where <b>my</b> means MySQL, 8020 is version 8.0.20 and c10b40 is the name for the configuration file.
</p>
IntroEOF

catme $conf

# ----- Generate ToC
cat <<ToCStartEOF
<div id="toc">
<hr />
<h1 id="toc">Contents</h1>
<ul>
<li><a href="#summary">Summary</a>
ToCStartEOF

for sx in $( seq ${#sections[@]}  ) ; do
x=$(( $sx - 1 ))

cat <<SecEOF
<li>${sectionText[$x]}
<ul>
<li><a href="#${sections[$x]}.graph">graph</a>
<li><a href="#${sections[$x]}.metrics">metrics</a>
<li><a href="#${sections[$x]}.rt">response time</a>
</ul>
SecEOF
done

cat <<ToCEndEOF
</ul>
</div>
ToCEndEOF

# ----- Generate summary

cat <<SumEOF
<hr />
<h1 id="summary">Summary</h1>
<p>
The numbers are inserts/s for l.i0 and l.i1, indexed docs (or rows) /s for l.x and queries/s for q*.2.
The values are the average rate over the entire test for inserts (IPS) and queries (QPS).
The range of values for IPS and QPS is split into 3 parts: bottom 25&#37;, middle 50&#37;, top 25&#37;.
Values in the bottom 25&#37; have a red background, values in the top 25&#37; have a green background and values in the middle have no color.
A gray background is used for values that can be ignored because the DBMS did not sustain the target insert rate.
Red backgrounds are not used when the minimum value is within 80&#37 of the max value.
</p>
SumEOF

catme tput.tab

cat <<Sum2EOF
<p>
This lists the average rate of inserts/s for the tests that do inserts concurrent with queries.
For such tests the query rate is listed in the table above.
The read+write tests are setup so that the insert rate should match the target rate every second.
Cells that are not at least 95&#37; of the target have a red background to indicate a failure to satisfy the target.
</p>
Sum2EOF

catme iput.tab

# ----- Generate graph sections

for sx in $( seq ${#isections[@]}  ) ; do

x=$(( $sx - 1 ))
sec=${isections[$x]}
txt=${sectionText[$x]}

cat <<H0IpsEOF
<hr />
<h1 id="${sec}.graph">${sec}</h1>
<p>$txt.
H0IpsEOF

if [[ $sec != "l.x" ]]; then
cat <<H1IpsEOF
 Graphs for performance per 1-second interval <a href="tput.${sec}.html">are here</a>.
H1IpsEOF
fi
printf "</p>\n"

cat <<H2IpsEOF
<p>Average throughput:</p>
<img src = "ch.${sec}.ips.png" alt = "Image" />
H2IpsEOF

if [[ $sec != "l.x" ]]; then
printf "<p>Insert response time histogram: each cell has the percentage of responses that take <= the time in the header and <b>max</b> is the max response time in seconds. For the <b>max</b> column values in the top 25&#37; of the range have a red background and in the bottom 25&#37; of the range have a green background. The red background is not used when the min value is within 80&#37 of the max value.</p>" 
catme $rtdir/mrg.${sec}.rt.insert.ht

fi

cat <<H3IpsEOF
<p>
Performance metrics for the DBMS listed above. Some are normalized by throughput, others are not. Legend for results <a href="https://mdcallag.github.io/ibench-results.html">is here</a>.
</p>
<pre>
H3IpsEOF

catme $resdir/mrg.${sec}.some
echo "</pre>"

done

for sx in $( seq ${#qsections[@]}  ) ; do

x=$(( $sx - 1 ))
sec=${qsections[$x]}
sec2=${q2sections[$x]}
txt=${sectionText[$(( $x + 3))]}

cat <<H0QpsEOF
<hr />
<h1 id="${sec}.graph">${sec}</h1>
<p>$txt. Graphs for performance per 1-second interval <a href="tput.${sec2}.html">are here</a>.</p>
H0QpsEOF

cat <<H2QpsEOF
<p>Average throughput:</p>
<img src = "ch.${sec}.qps.png" alt = "Image" />
H2QpsEOF

printf "<p>Query response time histogram: each cell has the percentage of responses that take <= the time in the header and <b>max</b> is the max response time in seconds. For <b>max</b> values in the top 25&#37; of the range have a red background and in the bottom 25&#37; of the range have a green background. The red background is not used when the min value is within 80&#37 of the max value.</p>" 
catme $rtdir/mrg.${sec2}.rt.query.ht

printf "<p>Insert response time histogram: each cell has the percentage of responses that take <= the time in the header and <b>max</b> is the max response time in seconds. For <b>max</b> values in the top 25&#37; of the range have a red background and in the bottom 25&#37; of the range have a green background. The red background is not used when the min value is within 80&#37 of the max value.</p>" 
catme $rtdir/mrg.${sec2}.rt.insert.ht

cat <<H3QpsEOF
<p>
Performance metrics for the DBMS listed above. Some are normalized by throughput, others are not. Legend for results <a href="https://mdcallag.github.io/ibench-results.html">is here</a>.
</p>
<pre>
H3QpsEOF

catme $resdir/mrg.${sec}.some
echo "</pre>"
done

# ----- Generate metrics sections

for sx in $( seq ${#sections[@]}  ) ; do

x=$(( $sx - 1 ))
sec=${sections[$x]}
txt=${sectionText[$x]}

cat <<MetricHeaderEOF
<hr />
<h1 id="${sec}.metrics">${sec}</h1>
<p>$txt</p>
<p>
Performance metrics for all DBMS, not just the ones listed above. Some are normalized by throughput, others are not. Legend for results <a href="https://mdcallag.github.io/ibench-results.html">is here</a>.
</p>
<pre>
MetricHeaderEOF

catme $resdir/mrg.${sec}
echo "</pre>"

done

# ----- Generate response time sections

for sx in $( seq ${#sections[@]}  ) ; do

x=$(( $sx - 1 ))
sec=${sections[$x]}
txt=${sectionText[$x]}

# Ugh, fixup because different naming pattern was used
fsec=$sec
if [[ $x -ge 3 ]]; then
  fsec=${q2sections[$(( $x - 3 ))]}
fi

cat <<RtHeaderEOF
<hr />
<h1 id="${sec}.rt">${sec}</h1>
<p>
<ul>
<li>$txt
<li>Legend for results <a href="https://mdcallag.github.io/ibench-results.html">is here</a>.
<li>Each entry lists the percentage of responses that fit in that bucket (slower than max time for previous bucket, faster than min time for next bucket).
</ul>
</p>
RtHeaderEOF

if [[ $sec == "l.x" ]]; then
echo "<p>TODO - determine whether there is data for create index response time</p>"
continue
fi

if [[ $x -ge 3 ]]; then
echo "<p>Query response time histogram</p>"
echo "<pre>"
catme $rtdir/mrg.${fsec}.rt.query
echo "</pre>"
fi

echo "<p>Insert response time histogram</p>"
echo "<pre>"
catme $rtdir/mrg.${fsec}.rt.insert
echo "</pre>"

done

cat <<FooterEOF
</body>
</html>
FooterEOF
