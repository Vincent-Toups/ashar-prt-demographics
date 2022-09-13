import keras
from keras import layers, backend
import pandas as pd
import numpy as np
from dfply import *
from plotnine import *
from sklearn.cluster import SpectralClustering
from numpy.random import seed
from tensorflow.random import set_seed as tf_set_seed

from pandasql import sqldf
sql = lambda q: sqldf(q, globals())


seed(1000);
tf_set_seed(1000);

demo_enc = pd.read_csv("./derived_data/demographic_ae.csv");
outcomes = pd.read_csv("./derived_data/outcome_vectors_imputed.csv");

def build_network(input_layer_n, output_layer_n,n_layers):
    input = keras.Input(shape=(input_layer_n,));
    e = layers.GaussianNoise(0.25)(input);
    for i in range(n_layers):
        e = layers.Dense(i+input_layer_n, activation='relu')(e);
    e = layers.Dense(output_layer_n, activation='linear')(e);
    m = keras.Model(input, e);
    m.compile(optimizer='adam', loss='mean_squared_error');
    return m;

j = sql('''select
case when o.`group` == 1 then 1 else 0 end as g1,
case when o.`group` == 2 then 1 else 0 end as g2,
case when o.`group` == 3 then 1 else 0 end as g3,
e.id, e.AE1, e.AE2,
o.`-1`,
o.`0`,
o.`1`,
o.`2`,
o.`3`,
o.`6`,
o.`12`
from demo_enc as e
join outcomes as o on e.id == o.id''')

model = build_network(5, 7, 5);
model.fit(j[['g1','g2','g3','AE1','AE2']], j[['-1','0','1','2','3','6','12']], epochs=10000);
keras.models.save_model(model, "models/demo_embedding_to_outcome")

