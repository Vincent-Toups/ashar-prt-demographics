import keras
from keras import layers, backend
import pandas as pd
import numpy as np
from dfply import *
from plotnine import *
from math import ceil
import util as u

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
