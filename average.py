#!/usr/bin/python3
import numpy as np
import sys

def average(data):
    arr = np.array(data)
    avg = np.mean(arr)
    return avg

def main():
    data = [arg for arg in sys.argv]
    if data == []:
        print("0")
        return
    data = list(map(float, data[1:]))
    print("%.5f" % average(data))

if __name__=='__main__':
    main()
