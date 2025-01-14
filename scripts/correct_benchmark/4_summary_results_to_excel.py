import matplotlib.pyplot as plt
import numpy as np

# Set general plotting parameters
plt.rcParams['font.family'] = 'Arial'
plt.style.use('seaborn-whitegrid')
plt.rcParams['axes.grid'] = True
plt.rcParams['grid.alpha'] = 0.3

# Simplified color scheme: only two colors
short_read_color = '#B19CD9'  # Light purple for short-read callers
long_read_color = '#87CEEB'   # Light blue for long-read callers

# Define tool types
long_read_tools = ['pbsv', 'svim', 'sniffles', 'cutesv']
short_read_tools = ['delly', 'lumpy', 'manta', 'svaba']

# Data definition
data = {
    'visor_ont': {
        'tools': ['pbsv', 'svim', 'sniffles', 'cutesv'],
        'accuracy': [100, 100, 0, 0],
        'total': [66, 56, 0, 0]
    },
    'visor_ngs': {
        'tools': ['delly', 'lumpy', 'manta', 'svaba'],
        'accuracy': [0, 100, 100, 100],
        'total': [0, 32, 644, 3803]
    },
    'visor_pacbio': {
        'tools': ['pbsv', 'svim', 'sniffles', 'cutesv'],
        'accuracy': [100, 100, 0, 0],
        'total': [82, 44, 0, 0]
    },
    'NA12878_ngs': {
        'tools': ['delly', 'lumpy', 'manta', 'svaba'],
        'accuracy': [0, 100, 100, 100],
        'total': [0, 41, 81, 892]
    },
    'NA12878_pacbio': {
        'tools': ['pbsv', 'svim', 'sniffles', 'cutesv'],
        'accuracy': [100, 100, 100, 0],
        'total': [1, 29, 1, 0]
    }
}

# Create figure
fig = plt.figure(figsize=(15, 8))
fig.suptitle('c. Correct Module Benchmark Results', y=0.95, fontsize=14)

# Create grid layout
gs = plt.GridSpec(2, 3, height_ratios=[1, 1], hspace=0.4, wspace=0.3)

def plot_subplot(ax, dataset_data, dataset_name):
    bars = []
    for j, (tool, acc) in enumerate(zip(dataset_data['tools'], dataset_data['accuracy'])):
        color = long_read_color if tool in long_read_tools else short_read_color
        bar = ax.bar(j, acc, width=0.6, color=color)
        bars.append(bar)
    
    # Add value labels
    for j, bar in enumerate(bars):
        if dataset_data['accuracy'][j] > 0:
            ax.text(j, dataset_data['accuracy'][j] + 2, f'n={dataset_data["total"][j]}',
                   ha='center', va='bottom', fontsize=8)
    
    # Set axis properties
    ax.set_ylim(0, 100)
    ax.set_yticks([0, 25, 50, 75, 100])
    ax.set_yticklabels(['0%', '25%', '50%', '75%', '100%'])
    ax.set_title(dataset_name, pad=10, fontsize=10)
    ax.set_xticks(range(len(dataset_data['tools'])))
    ax.set_xticklabels(dataset_data['tools'], rotation=45, ha='right')
    
    # Customize grid
    ax.grid(True, axis='y', linestyle='--', alpha=0.3)
    ax.set_axisbelow(True)

# Plot upper three subplots (visor data)
for i, dataset in enumerate(['visor_ont', 'visor_ngs', 'visor_pacbio']):
    ax = plt.subplot(gs[0, i])
    plot_subplot(ax, data[dataset], dataset)

# Plot lower two subplots (NA12878 data)
for i, dataset in enumerate(['NA12878_ngs', 'NA12878_pacbio']):
    ax = plt.subplot(gs[1, i])
    plot_subplot(ax, data[dataset], dataset)

# Create legend with only two colors
legend_handles = [
    plt.Rectangle((0,0),1,1, color=long_read_color),
    plt.Rectangle((0,0),1,1, color=short_read_color)
]
legend_labels = ['Long-read callers', 'Short-read callers']
plt.figlegend(legend_handles, legend_labels, 
              title='Tools', 
              loc='center right', 
              bbox_to_anchor=(1.15, 0.5))

# Adjust layout and save
plt.tight_layout()
plt.savefig('correct_benchmark.svg', format='svg', dpi=300, bbox_inches='tight')
plt.close()
