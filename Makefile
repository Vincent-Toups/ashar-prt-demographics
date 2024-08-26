.PHONY: clean
.PHONY: d3-vis
.PHONY: visualization

clean:
	rm -rf models
	rm -rf figures
	rm -rf derived_data
	rm -rf sentinels
	rm -rf .created-dirs
	rm -f writeup.pdf

.created-dirs:
	mkdir -p models
	mkdir -p figures
	mkdir -p derived_data
	mkdir -p sentinels
	touch .created-dirs

# HW Solution

# We're asked to start with reduced-demographics-plots.R
# we're told that the models.load_model lines tell us some dependencies.
# There is also a read_csv line which gives another dependency.
# and we see that we have three figures at the bottom of the file; these
# are our target artifacts.
# Don't forget that the script is itself a dependency for these targets.
# and we need to include the .created-dirs directory to make sure that
# the figures directory will be created (this isn't strictly required since
# previous builds will do it).
figures/figures/reduced_demographic_projection.png\
figures/reduced-demo-married-roc.png\
figures/reduced-demo-ethnicity_white-roc.png\
figures/reduced-demo-gender_female-roc.png: \
 .created-dirs\
 models/reduced-demographics-enc.keras\
 models/reduced-demographics-ae.keras\
 derived_data/reduced-demographics-one-hot.csv\
 reduced-demographics-plots.R
	Rscript reduced-demographics-plots.R

# Now we need to check that each of the dependencies we listed above is either present
# by default or listed in the Makefile already.
# it appears that models/reduced-demographics-enc and ae are not in the makefile
# but if we `grep reduced-demographics-enc *` we see this file mentioned in
# reduced-demographic-ae.py. Examining this file shows that we save both models there.
# not only that, but we save a few json files and our reduced-demographics-one-hot.csv
# this file only loads source_data/demographics.csv
# note that we have included the .created-dirs target to ensure the derived_data
# directory is created.
derived_data/reduced-demographics-one-hot.csv\
derived_data/reduced-demographics-one-hot-norm-info.json\
derived_data/reduced-demographics-columns.json\
models/reduced-demographics-ae.keras\
models/reduced-demographics-enc.keras:\
 source_data/demographics.csv\
 reduced-demographic-ae.py\
 .created-dirs
	python3 reduced-demographic-ae.py

# End of HW Solution

# It is usefual to propogate the panas_na and panas_pa values forward
# in time for subsequent analysis which attempts to cluster the state
# of each person in the study regardless of time so that we can track
# their progress through a lower dimensional space.
derived_data/clinical-outcomes-preprocessed.csv: .created-dirs pre-process.R source_data/clinical_outcomes.csv
	Rscript pre-process.R

# Here we train and serialize an auto-encoder (and an encoder) for the
# state of patients (regardless of time). The encoder projects patient
# state down to 2 dimensions. Hopefully this projection allows us to
# understand their progress in a simple way. In practice it turns out
# that this encoder just encodes average pain, so we don't find it all
# that useful.
models/clinical-outcomes-ae.keras\
 models/clinical-outcome-enc.keras\
 derived_data/clinical-outcomes-with-ae.csv: \
  train-clinical-outcomes-ae.py\
  .created-dirs\
  derived_data/clinical-outcomes-preprocessed.csv\
  train-clinical-outcomes-ae.py
	python3 train-clinical-outcomes-ae.py

# Attempt a clustering based on clinical outcomes but ignoring
# time. See above. Not all that useful. There aren't distinct clusters
# except in the sense that people report different levels of pain on a
# quantized scale. Not very useful.
derived_data/clinical-outcomes-with-clustering.csv\
 figures/clinical-outcomes-clustering.png:\
  cluster-clinical-outcomes.py\
  .created-dirs\
  derived_data/clinical-outcomes-with-ae.csv
	python3 cluster-clinical-outcomes.py

figures/bpi_intensity_by_group.png: source_data/clinical_outcomes.csv bpi_intensity_by_group.R derived_data/clinical_outcomes-d3.csv
	Rscript bpi_intensity_by_group.R

# Plots of various non-projected properties of clinical outcomes per
# cluster. Not very interesting because the clusters are not very
# interesting and the AE projection is just (roughly) back pain
# intensity.
# Note this uses a sentinal value because we produce many plots.
sentinels/cluster-plots.txt: .created-dirs\
 derived_data/clinical-outcomes-with-clustering.csv\
 cluster-plots.R
	Rscript cluster-plots.R

# Similar to above.
sentinels/boxplots.txt: .created-dirs\
 source_data/clinical_outcomes.csv\
 box-scatters.R
	Rscript box-scatters.R


# Augment the clinical outcomes data (with its AE projection) with
# time points so that we can view them in a d3 visualization. Not
# useful.
derived_data/clinical_outcomes-d3.csv: .created-dirs\
 derived_data/clinical-outcomes-with-clustering.csv\
 augment-with-experimental-time.R\
 derived_data/demographic_ae.csv
	Rscript augment-with-experimental-time.R

# Train a (variational) auto-encoder for demographic data. This allows
# us to see some obvious demographic groups and makes (tuning)
# clustering easier. See "explain_encoding.R" for code which helps us
# understand what these clusters represent.  Produce two targets here:
# One with the normalized data (sdf) and one with the original data.
models/demographics-ae.keras models/demographics-enc.keras derived_data/normalized_demographics.csv: demographics-ae.py\
 source_data/demographics.csv
	python3 demographics-ae.py

derived_data/demographic_ae_sdf.csv derived_data/demographic_ae.csv figures/demo-projection.png figures/demo-projection.svg: demographic-clustering.py\
 models/demographics-ae.keras\
 models/demographics-enc.keras\
 derived_data/normalized_demographics.csv
	python3 demographic-clustering.py

# Since our clustering is based on a variational auto-encoder it is
# difficult to understand what the clusters represent.  Here we use
# gradient boosting to train a tree model on the raw data to predict
# each cluster. From this model we can extract the important variables
# for each cluster and report their medians. We simply save the labels
# here for future use.
derived_data/cluster_labels.csv: .created-dirs explain_encoding.R derived_data/demographic_ae_sdf.csv
	Rscript explain_encoding.R

# Produce a figure which shows the clinical outcomes for our
# demographic clusters. Use the labels we calculated above to make the
# results comprehensible.
figures/outcomes_by_demographic_clustering.png figures/outcomes_by_demographic_clustering.svg: .created-dirs\
 demo-outcomes.R\
 derived_data/clinical-outcomes-with-clustering.csv\
 derived_data/cluster_labels.csv\
 derived_data/demographic_ae.csv
	Rscript demo-outcomes.R

# dummy target to show a d3 visualization.
d3-vis: derived_data/clinical_outcomes-d3.csv
	python3 -m http.server 8888


derived_data/meta-data.csv: source_data/clinical_outcomes.csv source_data/demographics.csv gen-meta-data.R
	Rscript gen-meta-data.R

derived_data/patient-count.fragment.Rmd: source_data/demographics.csv count-subject-types.R
	Rscript count-subject-types.R

# Start a server for the d3 visualization of the results of this
# project.
visualization: derived_data/clinical_outcomes-d3.csv 
	lighttpd -D -f lighttpd.conf

# Build the final report for the project.
writeup.pdf: figures/bpi_intensity_by_group.png figures/demo-projection.png figures/outcomes_by_demographic_clustering.png
	pdflatex writeup.tex

report.pdf: figures/bpi_intensity_by_group.png figures/demo-projection.png figures/outcomes_by_demographic_clustering.png derived_data/patient-count.fragment.Rmd
	R -e "rmarkdown::render(\"report.Rmd\", output_format=\"pdf_document\")"

example.html: figures/bpi_intensity_by_group.png figures/demo-projection.png figures/outcomes_by_demographic_clustering.png
	Rscript -e "tinytex::install_tinytex(); rmarkdown::render('example.Rmd',output_format='html_document')";

