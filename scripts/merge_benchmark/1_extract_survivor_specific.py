#!/usr/bin/env python3

def parse_vcf(vcf_file):
    """解析VCF文件,返回变异列表"""
    variants = []
    with open(vcf_file) as f:
        for line in f:
            if line.startswith('#'):
                continue
            fields = line.strip().split('\t')
            
            # 获取基本信息
            chrom = fields[0]
            pos = int(fields[1])
            
            # 从INFO字段解析END位置
            info = dict(item.split('=') for item in fields[7].split(';') if '=' in item)
            end = int(info.get('END', pos))
            
            # 解析变异类型
            svtype = info.get('SVTYPE', 'unknown')
            
            variants.append({
                'chrom': chrom,
                'start': pos,
                'end': end,
                'svtype': svtype,
                'line': line.strip()  # 保存原始行用于输出
            })
    return variants

def is_overlapping(var1, var2, overlap_fraction=0.5):
    """判断两个变异是否重叠"""
    # 相同染色体才考虑重叠
    if var1['chrom'] != var2['chrom']:
        return False
    
    # 计算重叠区域
    overlap_start = max(var1['start'], var2['start'])
    overlap_end = min(var1['end'], var2['end'])
    
    if overlap_start <= overlap_end:
        # 计算重叠长度与较短变异的比例
        overlap_length = overlap_end - overlap_start
        var1_length = var1['end'] - var1['start']
        var2_length = var2['end'] - var2['start']
        min_length = min(var1_length, var2_length)
        
        return (overlap_length / min_length) >= overlap_fraction
    
    return False

def find_unique_variants(survivor_vcf, octopus_vcf, output_vcf, overlap_fraction=0.5):
    """找出Survivor特有的变异"""
    # 解析两个VCF文件
    survivor_vars = parse_vcf(survivor_vcf)
    octopus_vars = parse_vcf(octopus_vcf)
    
    # 查找Survivor特有的变异
    unique_variants = []
    for sv_var in survivor_vars:
        is_unique = True
        for oct_var in octopus_vars:
            if is_overlapping(sv_var, oct_var, overlap_fraction):
                is_unique = False
                break
        if is_unique:
            unique_variants.append(sv_var)
    
    # 输出特有变异到新的VCF文件
    with open(output_vcf, 'w') as f:
        # 写入VCF头部信息
        f.write('##fileformat=VCFv4.2\n')
        f.write('##INFO=<ID=UNIQUE_TO,Number=1,Type=String,Description="Variant unique to this caller">\n')
        f.write('#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tSAMPLE\n')
        
        # 写入变异
        for var in unique_variants:
            f.write(var['line'] + '\n')
    
    return unique_variants

if __name__ == '__main__':
    import sys
    if len(sys.argv) != 4:
        print("Usage: python script.py survivor.vcf octopus.vcf output.vcf")
        sys.exit(1)
    
    survivor_vcf = sys.argv[1]
    octopus_vcf = sys.argv[2]
    output_vcf = sys.argv[3]
    
    unique_vars = find_unique_variants(survivor_vcf, octopus_vcf, output_vcf)
    print(f"找到 {len(unique_vars)} 个Survivor特有的变异")
    
    # 输出一些统计信息
    sv_types = {}
    for var in unique_vars:
        sv_types[var['svtype']] = sv_types.get(var['svtype'], 0) + 1
    
    print("\n变异类型统计:")
    for svtype, count in sv_types.items():
        print(f"{svtype}: {count}")
