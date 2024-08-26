import keras
from keras import layers, backend
from keras.layers import Layer
import pandas as pd
import numpy as np
from dfply import *
from plotnine import *
from sklearn.cluster import SpectralClustering
from numpy.random import seed
from tensorflow.random import set_seed as tf_set_seed
import tensorflow as tf

# Define a custom sampling layer
@keras.saving.register_keras_serializable()
class SamplingLayer(Layer):
    def call(self, inputs):
        mu, log_var = inputs
        eps = tf.random.normal(shape=tf.shape(mu), mean=0.0, stddev=1.0)
        return mu + tf.exp(log_var / 2) * eps


s = 600
n_clus_main = 4;
seed(s);
tf_set_seed(s);

sdf = pd.read_csv("derived_data/normalized_demographics.csv");
enc = keras.models.load_model("models/demographics-enc.keras");
data = pd.read_csv("source_data/demographics.csv");


proj = pd.DataFrame(enc.predict(sdf),columns=['AE1','AE2']) >> mutate(outlier = X.AE2 > 2,
                                                                      ix = list(range(sdf.shape[0])));

proj_main = proj >> mask(~X.outlier) >> drop(X.outlier);
proj_outliers = proj >> mask(X.outlier) >> drop(X.outlier);


sc = SpectralClustering(n_clusters=n_clus_main);
proj_main['cluster'] = sc.fit_predict(proj_main >> select(X.AE1, X.AE2));
proj_outliers = proj_outliers >> mutate(cluster=n_clus_main);

proj = pd.concat([proj_main, proj_outliers]) >> arrange(X.ix) >> drop(X.ix);


plt = (ggplot(proj,aes('AE1','AE2')) + geom_point(aes(color="factor(cluster)")));
plt.save("figures/demo-projection.png")
plt.save("figures/demo-projection.svg")

data['cluster'] = proj['cluster'];
data['AE1'] = proj['AE1'];
data['AE2'] = proj['AE2'];

sdf['cluster'] = proj['cluster'];
sdf['AE1'] = proj['AE1'];
sdf['AE2'] = proj['AE2'];


sdf.to_csv("derived_data/demographic_ae_sdf.csv", index=False)

#demographic_reduction 

demographic_ae = (data >> select(X.id, X.AE1, X.AE2, X.cluster));
demographic_ae.to_csv("derived_data/demographic_ae.csv", index=False);
