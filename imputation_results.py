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

vae = keras.models.load_model("models/imputation-vae")
enc = keras.models.load_model("models/imputation-enc")

complete = pd.read_csv("derived_data/outcome_vectors.csv").dropna().reset_index();
numerical_part = complete[['-1','0','1','2','3','6','12']];

predicted = pd.DataFrame(vae.predict(numerical_part), columns=['-1','0','1','2','3','6','12']);
encoded = pd.DataFrame(enc.predict(numerical_part),columns=['AE1','AE2']);
encoded['group'] = data['group'];

p = (ggplot(encoded, aes("AE1","AE2"))+geom_point(aes(color="factor(group)")));
p.save("figures/encoded_outcomes.png");

rms = np.sqrt((numerical_part-predicted)*(numerical_part-predicted));
rms['id'] = complete['id'];
rms['group'] = complete['group'];

rms_long = rms.melt(id_vars=['id','group'], var_name = 'time', value_name='error')
rms_long['time'] = pd.to_numeric(rms_long['time']);

p = (ggplot(rms_long, aes("time","error")) + geom_path(aes(group="factor(id)",color="factor(group)")))
p.save("figures/outcome_imputer_error.png");



