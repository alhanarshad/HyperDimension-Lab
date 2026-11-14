# Split Telemetry

Compare two runs on the same course. The tool resamples each recorded elapsed time by course distance, then shows the cumulative and per-sector time difference.

```sh
python split_telemetry.py examples/reference.csv examples/candidate.csv --step 80
python -m unittest -v
```

CSV files require `elapsed_s` and `distance_m`. Time must increase and distance may stay equal or increase. Where a run pauses exactly at a split, the split time is its first crossing, and the paused time belongs to the following sector. Times at unsampled distances use linear interpolation between adjacent observations.

The comparison starts at the first common distance and ends at the last common distance. A positive delta means the candidate took longer. The supplied recordings are synthetic. This tool compares distances already measured along one course, so GPS traces require a separate map-matching step.
