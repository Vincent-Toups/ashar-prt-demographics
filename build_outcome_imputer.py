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
n = 10000;

data = pd.read_csv("derived_data/outcome_vectors.csv");

training_raw = data.dropna().sample(n, replace=True).reset_index(drop=True);
training_mask = data.isna().sample(n, replace=True).reset_index(drop=True);

def mask(x):
    i = x.name
    m = training_mask.loc[i];
    for key in ['-1','0','1','2','3','6','12']:
        x[key] = -1 if m[key] else x[key];
    return x;

training = training_raw.apply(mask, axis=1, result_type='broadcast');

Y = training_raw[['-1','0','1','2','3','6','12']]
X = training[['-1','0','1','2','3','6','12']]

def build_vae(n_input=7,
             n_intermediate=3,
             encoded_dimension=2,
              intermediate_size=5):

    input = keras.Input(shape=(n_input,));
    #e = layers.Dropout(0.1, input_shape=(n_input,))(input);
    e = layers.GaussianNoise(0.25)(input);
    e = layers.Dense(intermediate_size, activation='relu')(e);
    for i in range(n_intermediate-1):
        e = layers.Dense(intermediate_size, activation='relu')(e);

    mu_layer = layers.Dense(encoded_dimension, name="encoder_mu")(e);
    log_var_layer = layers.Dense(encoded_dimension, name="encoder_log_var")(e);

    def sampler(mu_log_var):
        mu, log_var = mu_log_var;
        eps = backend.random_normal(backend.shape(mu), mean=0.0, stddev=1.0)
        sample = mu + backend.exp(log_var/2) * eps
        return sample

    encoder_output = layers.Lambda(sampler, name="encoder_output")([mu_layer, log_var_layer])

    d = layers.Dense(intermediate_size, activation='relu')(encoder_output);
    for i in range(n_intermediate-1):
        d = layers.Dense(intermediate_size, activation='relu')(d);

    d = layers.Dense(n_input, activation='linear')(d);

    ae = keras.Model(input, d);
    encoder = keras.Model(input, encoder_output);
    ae.compile(optimizer='adam', loss='mean_squared_error');

    return (ae,encoder)

ae, enc = build_vae();
ae.fit(X,Y, epochs=1000);
ae.save("models/imputation-vae");
enc.save("models/imputation-enc");
