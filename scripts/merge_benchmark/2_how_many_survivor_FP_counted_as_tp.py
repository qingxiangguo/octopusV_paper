#!/usr/bin/env python3

def parse_variant_types(sample_field):
    """解析样本字段中的变异类型
    返回该变异包含的所有类型"""
    types = set()
    samples = sample_field.split('\t')[9:]  # 从FORMAT字段后的样本开始
    for sample in samples:
        fields = dict(zip(sample_field.split('\t')[8].split(':'), sample.split(':')))
        if 'TY' in fields:
            sv_types = fields['TY'].split(',')
            types.update(sv_types)
    return types

def is_false_positive(main_type, sample_types):
    """判断是否为假阳性
    如果样本中存在与主类型不同的类型，则判定为假阳性"""
    return any(t != main_type for t in sample_types)

def analyze_variants(specific_vcf, tp_vcf):
    """分析变异文件
    specific_vcf: survivor特有的变异文件
    tp_vcf: 被判定为TP的变异文件"""
    
    # 存储分析结果
    results = {
        'total_specific': 0,        # survivor特有变异总数
        'false_positives': 0,       # 假阳性数量
        'false_tp': 0,              # 错误计入TP的假阳性数量
        'details': []               # 详细信息
    }
    
    # 读取TP变异的位置信息
    tp_positions = set()
    with open(tp_vcf) as f:
        for line in f:
            if line.startswith('#'):
                continue
            fields = line.strip().split('\t')
            chrom = fields[0]
            pos = int(fields[1])
            tp_positions.add(f"{chrom}_{pos}")
    
    # 分析特异性变异
    with open(specific_vcf) as f:
        for line in f:
            if line.startswith('#'):
                continue
                
            fields = line.strip().split('\t')
            chrom = fields[0]
            pos = int(fields[1])
            variant_key = f"{chrom}_{pos}"
            
            # 获取主要变异类型
            info = dict(item.split('=') for item in fields[7].split(';') if '=' in item)
            main_type = info.get('SVTYPE', 'unknown')
            
            # 获取所有样本的变异类型
            sample_types = parse_variant_types(line.strip())
            
            # 判断是否为假阳性
            is_fp = is_false_positive(main_type, sample_types)
            
            # 更新统计信息
            results['total_specific'] += 1
            if is_fp:
                results['false_positives'] += 1
                # 检查是否被错误地计入TP
                if variant_key in tp_positions:
                    results['false_tp'] += 1
                    
                    # 保存详细信息
                    variant_info = {
                        'chrom': chrom,
                        'pos': pos,
                        'main_type': main_type,
                        'sample_types': list(sample_types)
                    }
                    results['details'].append(variant_info)
    
    return results

def print_results(results):
    """打印分析结果"""
    print(f"\n分析结果:")
    print(f"Survivor特有变异总数: {results['total_specific']}")
    print(f"假阳性数量: {results['false_positives']}")
    print(f"错误计入TP的假阳性数量: {results['false_tp']}")
    print(f"假阳性比例: {results['false_positives']/results['total_specific']*100:.2f}%")
    print(f"错误TP占假阳性比例: {results['false_tp']/results['false_positives']*100:.2f}%")
    
    print("\n错误计入TP的变异详情:")
    for var in results['details']:
        print(f"\n染色体 {var['chrom']} 位置 {var['pos']}:")
        print(f"主要类型: {var['main_type']}")
        print(f"包含的变异类型: {', '.join(var['sample_types'])}")

if __name__ == '__main__':
    import sys
    
    if len(sys.argv) != 3:
        print("使用方法: python script.py survivor_specific.vcf survivor_tp.vcf")
        sys.exit(1)
    
    specific_vcf = sys.argv[1]
    tp_vcf = sys.argv[2]
    
    results = analyze_variants(specific_vcf, tp_vcf)
    print_results(results)
