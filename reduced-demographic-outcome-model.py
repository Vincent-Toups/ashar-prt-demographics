import keras
from keras import layers, backend
import pandas as pd
import numpy as np
from dfply import *
from plotnine import *
from sklearn.cluster import SpectralClustering
from numpy.random import seed
from tensorflow.random import set_seed as tf_set_seed
import util as u
import pdb;
from pandasql import sqldf
import json

sql = lambda q: sqldf(q, globals())

reduced_demo_data = pd.read_csv("derived_data/reduced-demographics-one-hot.csv");
norm_info = u.read_json("./derived_data/reduced-demographics-one-hot-norm-info.json");

def unnormalize(df,norm_info):
    df = df.copy();
    for k in norm_info.keys():
        c = df[k];
        df[k] = df[k]*(norm_info[k]["max"]-norm_info[k]["min"]) + norm_info[k]["min"];
    return df;

rdd = unnormalize(reduced_demo_data, norm_info).drop(['treatment_saline','treatment_soc','treatment_prt'], axis=1);
outcomes = pd.read_csv("./derived_data/outcome_vectors_imputed.csv");

