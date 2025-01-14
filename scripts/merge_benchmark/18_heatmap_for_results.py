import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
import numpy as np
from matplotlib.patches import Rectangle
from matplotlib.gridspec import GridSpec

# Read the Excel file
df = pd.read_excel('benchmark_results_summary.xlsx', sheet_name='Overview')

# Convert metrics from string to float
metrics = ['precision', 'recall', 'f1']
for metric in metrics:
    df[metric] = pd.to_numeric(df[metric], errors='coerce')

# Define dataset types
ngs_datasets = ['NA12878_ngs', 'visor_ngs']
lrs_datasets = ['NA12878_pacbio', 'visor_ont', 'visor_pacbio']

# Define colors for analysis categories
category_colors = {
    'intersection': '#FFB6C1',  # Light pink
    'union': '#98FB98',         # Light green
    'support': '#87CEFA'        # Light blue
}

def get_category(analysis_type):
    if 'intersection' in analysis_type:
        return 'intersection'
    elif 'union' in analysis_type:
        return 'union'
    else:
        return 'support'

# Create figure with increased size and spacing
fig = plt.figure(figsize=(35, 20))
gs = GridSpec(2, 3, figure=fig, hspace=0.4, wspace=0.25)

def prepare_heatmap_data(data, datasets, metric):
    pivot_data = data[data['dataset'].isin(datasets)].pivot_table(
        values=metric,
        index='tool',
        columns=['dataset', 'analysis_type'],
        fill_value=np.nan
    )
    tool_order = ['octopusv'] + sorted([t for t in pivot_data.index if t != 'octopusv'])
    return pivot_data.reindex(tool_order)

def create_heatmap(data, ax, title, metric, show_cbar=False, is_ngs=True):
    values = data.values
    mask = np.isnan(values)
    
    # Use different font sizes for NGS and LRS datasets
    font_size = 14 if is_ngs else 9
    
    # Create heatmap with adjusted font sizes
    sns.heatmap(data, ax=ax, cmap='YlOrRd', vmin=0, vmax=1, center=0.5,
                annot=True, fmt='.2f', cbar=show_cbar,
                cbar_kws={'label': f'{metric.capitalize()} Score'} if show_cbar else None,
                linewidths=1.0, linecolor='white', mask=mask,
                annot_kws={'size': font_size})
    
    # Customize appearance
    ax.set_title(title, pad=20, fontsize=16, fontweight='bold')
    
    # Adjust x-axis labels for better readability
    ax.set_xticklabels(ax.get_xticklabels(), rotation=45, ha='right', fontsize=9)
    ax.set_yticklabels(ax.get_yticklabels(), rotation=0, fontsize=10)
    
    # Add category bars
    prev_dataset = None
    prev_category = None
    for i, (dataset, analysis_type) in enumerate(data.columns):
        category = get_category(analysis_type.lower())
        if dataset != prev_dataset or category != prev_category:
            ax.axvline(x=i, color='black', linewidth=2)
            ax.add_patch(Rectangle((i, -0.15), 1, 0.15,
                                 facecolor=category_colors[category],
                                 edgecolor='none'))
        prev_dataset = dataset
        prev_category = category

# Create heatmaps for each metric and dataset type
for col, metric in enumerate(metrics):
    # NGS datasets (top row) with larger font
    ax = fig.add_subplot(gs[0, col])
    ngs_data = prepare_heatmap_data(df, ngs_datasets, metric)
    create_heatmap(ngs_data, ax, f'NGS Datasets - {metric.capitalize()}', metric, show_cbar=(col == 2), is_ngs=True)
    
    # LRS datasets (bottom row) with smaller font
    ax = fig.add_subplot(gs[1, col])
    lrs_data = prepare_heatmap_data(df, lrs_datasets, metric)
    create_heatmap(lrs_data, ax, f'LRS Datasets - {metric.capitalize()}', metric, show_cbar=(col == 2), is_ngs=False)

# Add overall title with adjusted position
fig.suptitle('Merge Module Benchmark Results', fontsize=20, y=0.98, fontweight='bold')

# Adjust layout
plt.tight_layout(rect=[0, 0.03, 1, 0.95])

# Save the figure with high resolution
plt.savefig('merge_benchmark_heatmap_optimized.svg', format='svg', dpi=300, bbox_inches='tight')
plt.savefig('merge_benchmark_heatmap_optimized.png', format='png', dpi=300, bbox_inches='tight')
plt.close()
