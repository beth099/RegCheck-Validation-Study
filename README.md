This repository contains the code to set up and run our [RegCheck](https://arxiv.org/abs/2601.13330) validation study.

Our preregistration can be found: https://osf.io/9ykuw/overview 

## Repository structure

```
Analyses/               Analysis code for the collected data
Data/                   Coming soon!
Sample_selection/       Screening, sampling, coder allocation, RegCheck inputs
Planning_files/         Preregistered analysis plan + simulations for power analysis
```

## `Analyses/`
This folder contains analysis scripts for the analyses we will report in the manuscript.

## `Data/`
Coming soon: this folder will contain the RegCheck validation data.

## `Planning_files/`

This folder contains our preregistered analysis plan and the code and results for our simulated power analysis. 

```
Planning_files/
├── Analysis_plan/
│   ├── analysis_plan.Rmd                           The preregistered analysis plan
│   ├── rq3_simulated_data.Rmd                      Simulated data and analysis for RQ3
│   ├── test_pilot_data.csv                         Pilot coding data used to develop the preregistered analysis
│   ├── regcheck_validation_round2_check_test.csv   Round 2 pilot data
│   └── data_rq3_simulated.csv                      Simulated RQ3 data
│
└── Simulation_planning/
    ├── simulation.qmd                              Simulation code for the power analysis
    └── results/                                    Simulation results (round3_results_long.rds are the results used)
```

## `Sample_selection/`

This folder contains the full pipeline from all articles in the corpus to our sample of 100 randomly sampled articles with a preregistered study. Scripts are listed in the order they were run. Note that full text xmls are required to run these scripts, but these have not been uploaded (as this would breach copyright).

```
Sample_selection/
├── extracting_articles.Rmd            1. Unzip full text xml files and searches for articles that contain "preregistered", "pre-registered", "preregistration" or "pre-registration". Extract the text around these keywords and OSF links
├── preregistration_classifier.ipynb   2. LLM classifier + call to OSF's API to check the preregistration template used
├── sample_selection.Rmd               3. Draw the sample of 100 articles (with an OSF Prereg Template preregistration), assign coders
├── reassign_articles.Rmd              4. Rebalance allocation of coding after two coders joined
│
├── coders_sheets/                     Original 5-coder allocation
├── coding_in_progress/                Working sheets + 7-coder reallocation
└── feed_to_regcheck/                  Files given to RegCheck as input
```

## License

Code in this repository is released under the [MIT License](LICENSE).
Data and study materials are released under
[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).
