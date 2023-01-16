import matplotlib.pyplot as plt
import matplotlib.colors as mcolors
import numpy as np
import json
import os
import dtw 


def loadjson(file:str):
    with open(file) as json_file:
        return json.loads(json_file.read())
    
def extract(json, what):
    return [stat[what] for stat in json["stats"]]

def listRuns():
    return [d for d in next(os.walk("./results"))[1]]

def listInstances(run):
    return os.listdir(os.path.join("./results/", run))

def plot_stats(jsons, what="bound", save:bool=False):
    keys = jsons.keys()
    if jsons[keys[0]]["policy"] == "SATISFACTION" and what=="bound":
        print("No bound to plot in a CSP")
        return
    plt.figure(figsize=(15, 7), constrained_layout=True)
    colors = list(mcolors.TABLEAU_COLORS)
    for i, (json, name) in enumerate(jsons):
        bounds = extract(json, what)
        times = extract(json, 'time')
        col = colors[i]
        plt.step(times, bounds, where='post', color=col, marker='+', label=name)
        if json["exit"]["status"] == "TERMINATED": 
            plt.axvline(x=json["exit"]["time"], color=col, linestyle='dashed')
        
    plt.xlabel('time')
    plt.ylabel('objective')
    plt.legend(bbox_to_anchor=(1.05, 1),loc='upper left', borderaxespad=0.)
    instance = os.path.basename(jsons[0][0]["name"])
    plt.title(instance)
    if save:
        plt.savefig(instance+'.png')
        plt.close()
    
def cactus_plot(*runs, what="time", getDtw:bool=True, save:bool=False):
    fig1 = plt.figure(figsize=(15, 7), constrained_layout=True)
    ax0, ax1 = fig1.subplots(1, 2)
    colors = list(mcolors.TABLEAU_COLORS)
    times = []
    for i,run in enumerate(runs):
        instances = listInstances(run)
        timei = []
        for instance in instances:
            path = os.path.join('./results', run, instance)
            data = loadjson(path)
            timei.append(data["exit"][what])
        y = sorted(timei)
        y = np.cumsum(y)
        x = [j for j in range(len(y))]
        col = colors[i]
        
        ax0.plot(x, y, color=col, marker='|', label=run)
        times.append(y)
                
    ax0.set_xlabel('#instances')
    ax0.set_ylabel('cumulated '+ what)
    ax0.legend(loc='upper left', borderaxespad=0.)
    ax0.set_title('Cactus plot')
    
    distances = []
    for i, ti in enumerate(times):
        disti = []
        for j, tj in enumerate(times):
            alignment = dtw.dtw(times[i], times[j], dist_method='euclidean')
            disti.append(alignment.distance)
            #alignment.plot(type="threeway")
            
        distances.append(disti)
    print(distances)
    ax1.set_xticks(np.arange(len(runs)), labels=runs)
    ax1.set_yticks(np.arange(len(runs)), labels=runs)
    ax1.yaxis.tick_right()
    # Rotate the tick labels and set their alignment.
    plt.setp(ax1.get_xticklabels(), rotation=45, ha="right",
             rotation_mode="anchor")
    ax1.imshow(distances)
    ax1.set_title('Cactus DTW heatmap')
    if save:
        plt.savefig(instance+'.png')
        plt.close()