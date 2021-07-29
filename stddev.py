#!/usr/bin/python3

import numpy as np
import sys

def stddev(data):
    arr = np.array(data)
    std = np.std(arr)
    return std

def main():
    data = [arg for arg in sys.argv]
    if data == []:
        print("0")
        return
    data = list(map(float, data[1:]))
    print("%.2f" % stddev(data))

if __name__=='__main__':
    main()
