version 18

// Generates the fictitious trial data (data/disrupted.dta) and the Stata
// output (logs/*.log.tex) included in supplementary-material.pdf.
//
// Run from the repository's top-level directory:
//
//   do stata/supplementary_analysis.do
//
// Requires Stata 18 or later and the sjlog command (see README.md).

cd data // Working directory for disrupted.dta; logs are written to ../logs.
capture log close
set linesize 80 // Prevent Stata from printing too wide for a LaTeX page.

sjlog using ../logs/code_example_1, replace
clear all
set seed 12345
set cformat %9.2f
sjlog close, replace

// Define the number of clusters.
// Define a lognormal distribution of cluster sizes that is
// similar to that for the original trial.
sjlog using ../logs/code_example_2, replace
global num_clusters    59
global cluster_sz_mean 3
global cluster_sz_sd   1
sjlog close, replace

// Define the log control risk.
// Define the true treatment effect on the log risk ratio scale.
sjlog using ../logs/code_example_3, replace
global log_control_risk = log(0.15)
global log_rr           = log(0.75)
sjlog close, replace

// Define the variance component for the cluster effect on the log risk scale.
sjlog using ../logs/code_example_4, replace
global cluster_var 0.07
sjlog close, replace

// Define the proportion of participants non-disrupted.
sjlog using ../logs/code_example_5, replace
global nondisrupted_prop  = 0.37
sjlog close, replace

// Define a program to simulate cluster-level variables.
sjlog using ../logs/code_example_6, replace
program simulate_clusters, nclass
  version 18
  quietly set obs $num_clusters
  generate byte cluster     = _n
  generate log_cluster_risk = rnormal(0, sqrt($cluster_var))
  generate log_cluster_size = rnormal($cluster_sz_mean, $cluster_sz_sd)
  splitsample , generate(intervention) values(0 1) rround
  label variable cluster          "Cluster identifier (observable)"
  label variable log_cluster_risk "Log cluster risk (unobservable)"
  label variable log_cluster_size "Log cluster size (observable)"
  label variable intervention     "Intervention (observable)"
  label define   intervention     0 "Control"                          ///
                                     1 "Intervention"
  label values   intervention     intervention
end
sjlog close, replace

// Define a program to simulate participant-level variables, given
// a data frame with cluster-level variables.
sjlog using ../logs/code_example_7, replace
program simulate_participants, nclass
  version 18
  quietly expand exp(log_cluster_size)
  generate nondisrupted = intervention *                               ///
                             (runiform() < $nondisrupted_prop)
  generate log_risk     = $log_control_risk + log_cluster_risk +       ///
                             (nondisrupted * $log_rr)
  generate outcome      = rbinomial(1, exp(log_risk))
  label variable nondisrupted "Not disrupted (observable)"
  label define   nondisrupted 0 "Disrupted"                            ///
                                 1 "Not disrupted"
  label values   nondisrupted nondisrupted
  label variable log_risk     "Log risk (unobservable)"
  label variable outcome      "Outcome (observable)"
  label define   outcome      0 "No morbidity or mortality"            ///
                                 1 "Morbidity or mortality"
  label values   outcome      outcome
end
sjlog close, replace

///////////////////////////////////////////////////////////////////
// Simulate the trial once and then explore that data and perform a 
// naive analysis. These steps will appear in the manuscript before
// the above code and results. The code saves the data to a file
// called "disrupted.dta" that we will distribute with the article.
///////////////////////////////////////////////////////////////////

// Simulate a trial and save just the observable variables.
simulate_clusters
simulate_participants
keep cluster intervention nondisrupted outcome
save disrupted, replace

// Load the simulated trial data and describe it.
sjlog using ../logs/example_data_1, replace
use disrupted , clear
codebook
sjlog close, replace

// Tabulate to show the proportion affected by the intercurrent event.
sjlog using ../logs/example_data_2, replace
tabulate intervention nondisrupted , row
sjlog close, replace

// Perform a naïve analysis to estimate the risk ratio.
sjlog using ../logs/example_data_3, replace
mepoisson outcome i.intervention ||cluster:, vce(robust) eform(RR) nolog
sjlog close, replace


///////////////////////////////////////////////////////////////////
// Continue with the simulations.
///////////////////////////////////////////////////////////////////

// Define the prespecified analysis, which does not account for the problem.
sjlog using ../logs/code_example_8, replace
program prespecified_analysis, rclass
  version 18
  mepoisson outcome i.intervention ||cluster:, vce(robust)
  return scalar es1_Prespecified      = _b[1.intervention]
  return scalar se1_Prespecified      = _se[1.intervention]
  return scalar reject1_Prespecified  =                                ///
                    r(table)["pvalue", "outcome:1.intervention"] < 0.05
end
sjlog close, replace

// Define the modified ITT analysis - the prespecified analysis but which
// excludes participants randomized to the intervention who could not
// receive it (excludes participants!).
sjlog using ../logs/code_example_9, replace
program mITT_analysis, rclass
  version 18
  local included !intervention | nondisrupted
  mepoisson outcome i.intervention if `included' ||cluster: , vce(robust)
  return scalar es2_mITT      = _b[1.intervention]
  return scalar se2_mITT      = _se[1.intervention]
  return scalar reject2_mITT  =                                        ///
                    r(table)["pvalue", "outcome:1.intervention"] < 0.05
end
sjlog close, replace

// Define the as-treated analysis - an analysis in which arms are defined according to
// treatment received (breaks randomization!).
sjlog using ../logs/code_example_10, replace
program astreated_analysis, rclass
  version 18
  mepoisson outcome i.nondisrupted ||cluster:, vce(robust)
  return scalar es3_AsTreated      = _b[1.nondisrupted]
  return scalar se3_AsTreated      = _se[1.nondisrupted]
  return scalar reject3_AsTreated  =                                 ///
                      r(table)["pvalue", "outcome:1.nondisrupted"] < 0.05
end
sjlog close, replace

// Define the hypothetical analysis - preserves randomization, follows ITT,
// addresses the problem (requires additional assumptions!).
sjlog using ../logs/code_example_11, replace
program hypothetical_analysis, rclass
  version 18
  mepoisson outcome i.intervention i.nondisrupted ||cluster:, vce(robust)
  lincom _b[1.intervention] + _b[1.nondisrupted]
  return scalar es4_Hypothetical      = r(estimate)
  return scalar se4_Hypothetical      = r(se)
  return scalar reject4_Hypothetical  = r(p) < 0.05
end
sjlog close, replace

// Simulate a trial and analyze it using each analysis.
sjlog using ../logs/code_example_12, replace
program simulate_trial, rclass
  version 18
  clear
  simulate_clusters
  simulate_participants
  foreach method in prespecified mITT astreated hypothetical {
    `method'_analysis
    return add
  }
  ereturn clear
end
sjlog close, replace

// Run the simulation.
sjlog using ../logs/code_example_13, replace
simulate , reps(1000) nolegend : simulate_trial
sjlog close, replace

// Reshape into long format.
sjlog using ../logs/code_example_14, replace
generate simulation = _n
tempvar method
reshape long es se reject , i(simulation) j(`method') string
encode `method', generate(method)
sjlog close, replace

// Estimate bias as a percentage for each method.
sjlog using ../logs/code_example_15, replace
generate bias = 100 * (($log_rr - es) / $log_rr)
bysort method: regress bias , noheader
sjlog close, replace

// Test for a difference between methods 2 and 4
sjlog using ../logs/code_example_15a, replace
regress bias i.method , nocons noheader
test 2.method = 4.method
sjlog close, replace

// Estimate standard error for each method.
sjlog using ../logs/code_example_16, replace
bysort method: regress se , cformat(%9.4g) noheader
sjlog close, replace

// Test for a difference between methods 2 and 4
sjlog using ../logs/code_example_16a, replace
regress se i.method , nocons noheader
test 2.method = 4.method
sjlog close, replace

// Estimate power for each method.
sjlog using ../logs/code_example_17, replace
bysort method: ci proportions reject
sjlog close, replace

// Test for a difference between methods 2 and 4
sjlog using ../logs/code_example_17a, replace
regress reject i.method , nocons noheader
test 2.method = 4.method
sjlog close, replace

// Analyze the disrupted trial using the hypothetical method.
sjlog using ../logs/code_example_18, replace
use disrupted, clear
mepoisson outcome i.intervention i.nondisrupted ||cluster:, vce(robust) nolog
sjlog close, replace

// Estimate the risk ratio.
sjlog using ../logs/code_example_19, replace
lincom _b[1.intervention] + _b[1.nondisrupted] , eform
sjlog close, replace