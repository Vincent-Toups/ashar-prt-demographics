import keras
from keras import layers, backend
import pandas as pd
import numpy as np
from dfply import *
from plotnine import *
from math import ceil
import util as u
import json

class NpEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, np.integer):
            return int(obj)
        if isinstance(obj, np.floating):
            return float(obj)
        if isinstance(obj, np.ndarray):
            return obj.tolist()
        return super(NpEncoder, self).default(obj)

def to_json(obj, filename):
    with open(filename, 'w', encoding='utf-8') as f:
        json.dump(obj, f, ensure_ascii=False, indent=4, cls=NpEncoder)

def read_json(filename):
    with open(filename, 'r', encoding='utf-8') as f:
        return json.load(f);

def one_hot_encode_column(df, column_name):
    col = df[column_name];
    df = df.drop(column_name, axis=1);
    for value in set(col):
        new_col_name = "_".join([column_name,str(value)]);
        df[new_col_name] = (col == value).astype(int);
    return df;

def one_hot_encode(df, columns):
    for c in columns:
        df = one_hot_encode_column(df, c);
    return df
    
def tt_split_groups(df, col, pct_test):
    df = df.reindex(range(df.shape[0]));
    keys = list(set(df[col]));
    trains = [];
    tests = [];
    for key in keys:
        subdf = df[df[col]==key];
        n = subdf.shape[0];
        if n==0 or n==1:
            print(f"Warning: too few rows for key {key}.");
        else:                
            n_test = round(pct_test*n);
            if n_test == 0:
                n_test = 1;
            if n_test == n:
                n_test = n_test - 1;            
            n_train = n - n_test;
            print(n_test, n_train);
            subdf = subdf.sample(frac = 1).reset_index();
            print(subdf)
            test = subdf.loc[list(range(n_test)),:];
            train = subdf.loc[[n_test + i for i in range(n_train)],:];
            trains.append(train)
            tests.append(test);
    return (pd.concat(trains), pd.concat(tests));

def boolean_perturber(p_flip, p_remove, censored=-1):
    def do_it(column):
        columnc = np.array(column);
        ii = np.where(np.random.uniform(0,1,columnc.size) < p_flip);
        print(columnc.size)
        v = np.logical_not(columnc[ii])*1;
        columnc[ii] = v;
        ii = np.where(np.random.uniform(0,1,columnc.size) < p_remove);
        columnc[ii] = censored;
        return columnc;
    return do_it;

def float_perturber(s, p_remove, censored=-1):
    def do_it(column):
        cc = column.copy() + np.random.standard_normal(size=column.size)*s;
        cc[np.random.uniform(0,1,size=column.size)<p_remove] = -1;
        return cc;
    return do_it;

def perturb_columns(df, transformers):
    df = df.copy();
    for k in list(transformers.keys()):
        df[k] = transformers[k](df[k]);
    return df;

def norm_columns(df, columns):
    df = df.copy();
    out = {};
    for column in columns:
        c = df[column];
        mn = c.min();
        mx = c.max();
        d = mx-mn;
        out[column] = {"min":mn,"max":mx};
        df[column] = (c-mn)/d;
    return (df,out);
