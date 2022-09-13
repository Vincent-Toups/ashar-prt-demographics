import keras
from keras import layers, backend
import pandas as pd
import numpy as np
from dfply import *
from plotnine import *
from sklearn.cluster import SpectralClustering
from numpy.random import seed
from tensorflow.random import set_seed as tf_set_seed

seed(1000);
tf_set_seed(1000);

outcomes = pd.read_csv("derived_data/outcome_vectors.csv").fillna(-1)
columns_to_encode = ['-1','0','1','2','3','6','12'];
enc = keras.models.load_model("models/imputation-enc/")
vae = keras.models.load_model("models/imputation-vae/")

auto_encoded = pd.DataFrame(vae.predict(outcomes[columns_to_encode]), columns=columns_to_encode)

def fill_in_missing(raw_outcomes, auto_enc_outcomes):
    def f(x):
        y = auto_enc_outcomes.loc[x.name];
        for c in columns_to_encode:
            x[c] = x[c] if x[c] > 0 else y[c];
        return x;
    return raw_outcomes.apply(f, axis=1, result_type='broadcast');

filled_in = fill_in_missing(outcomes, auto_encoded);

filled_in.to_csv("derived_data/outcome_vectors_imputed.csv", index=False);
