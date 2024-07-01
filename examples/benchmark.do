* Create a dataset with 10,000,000 observations
clear
set obs 10000000

* Generate variable i from 1 to 10,000,000
gen i = _n

* Generate variable g with random integers between 0 and 99
set seed 12345
gen g = floor(runiform() * 100)

* Measure time for mean calculation by group
timer clear 1
preserve
timer on 1
egen mean_i = mean(i), by(g)
timer off 1
restore
timer list 1

* Measure time for collapse by group
preserve
timer clear 3
timer on 3
collapse (mean) mean_i=i, by(g)
timer off 3
restore
timer list 3

* Measure time for tabulate
timer clear 5
timer on 5
tabulate g
timer off 5
timer list 5

* Measure time for summarize
timer clear 7
timer on 7
summarize g, detail
timer off 7
timer list 7

* Measure time for regress with condition
preserve
timer clear 9
timer on 9
regress i g if g > 50
timer off 9
restore
timer list 9
