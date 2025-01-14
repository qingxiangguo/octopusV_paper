import matplotlib.pyplot as plt
import numpy as np

# 设置字体和样式
plt.rcParams['font.family'] = 'Arial'
plt.style.use('seaborn-whitegrid')

# 数据定义
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

# 创建图表
fig = plt.figure(figsize=(15, 8))
fig.suptitle('c. Correct Module Benchmark Results', y=0.95, fontsize=14)

# 创建网格布局
gs = fig.add_gridspec(2, 3, height_ratios=[1, 1], hspace=0.4, wspace=0.3)

# 绘制上面三个子图（visor数据）
visor_datasets = ['visor_ont', 'visor_ngs', 'visor_pacbio']
for i, dataset in enumerate(visor_datasets):
    ax = fig.add_subplot(gs[0, i])
    d = data[dataset]
    bars = ax.bar(d['tools'], d['accuracy'], color='#7EB6FF', alpha=0.7)
    
    # 添加数据标签
    for j, bar in enumerate(bars):
        if d['accuracy'][j] > 0:
            ax.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 2,
                   f'n={d["total"][j]}', ha='center', va='bottom', fontsize=8)
    
    # 设置坐标轴
    ax.set_ylim(0, 105)
    ax.set_yticks([0, 30, 60, 105])
    ax.set_yticklabels(['0%', '30%', '60%', '105%'])
    ax.set_title(dataset, pad=10, fontsize=10)
    ax.tick_params(axis='x', rotation=45)
    ax.grid(True, axis='y', linestyle='--', alpha=0.7)
    ax.set_axisbelow(True)

# 绘制下面两个子图（NA12878数据）
na12878_datasets = ['NA12878_ngs', 'NA12878_pacbio']
for i, dataset in enumerate(na12878_datasets):
    ax = fig.add_subplot(gs[1, i])
    d = data[dataset]
    bars = ax.bar(d['tools'], d['accuracy'], color='#7EB6FF', alpha=0.7)
    
    # 添加数据标签
    for j, bar in enumerate(bars):
        if d['accuracy'][j] > 0:
            ax.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 2,
                   f'n={d["total"][j]}', ha='center', va='bottom', fontsize=8)
    
    # 设置坐标轴
    ax.set_ylim(0, 105)
    ax.set_yticks([0, 30, 60, 105])
    ax.set_yticklabels(['0%', '30%', '60%', '105%'])
    ax.set_title(dataset, pad=10, fontsize=10)
    ax.tick_params(axis='x', rotation=45)
    ax.grid(True, axis='y', linestyle='--', alpha=0.7)
    ax.set_axisbelow(True)

# 调整布局
plt.tight_layout()

# 保存图片为SVG格式
plt.savefig('correct_benchmark.svg', format='svg', dpi=300, bbox_inches='tight')
plt.close()
