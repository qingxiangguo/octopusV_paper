#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import json
import pandas as pd
from pathlib import Path

def read_summary_json(file_path):
    """Read summary.json file and extract key metrics"""
    try:
        with open(file_path, 'r') as f:
            data = json.load(f)
            return {
                'precision': data.get('precision', 'NA'),
                'recall': data.get('recall', 'NA'),
                'f1': data.get('f1', 'NA')
            }
    except Exception as e:
        print(f"Error reading {file_path}: {e}")
        return {
            'precision': 'NA',
            'recall': 'NA',
            'f1': 'NA'
        }

def process_directory(base_path):
    """Process directory structure and collect all results"""
    results = []
    
    # Five main dataset directories
    datasets = ['NA12878_ngs', 'NA12878_pacbio', 'visor_ngs', 'visor_ont', 'visor_pacbio']
    
    # Datasets that include combisv_4callers analysis
    combisv_datasets = ['NA12878_pacbio', 'visor_ont', 'visor_pacbio']
    
    for dataset in datasets:
        evaluation_path = os.path.join(base_path, dataset, 'evaluation')
        if not os.path.exists(evaluation_path):
            print(f"Warning: {evaluation_path} does not exist")
            continue
            
        # Process combisv_4callers first if applicable
        if dataset in combisv_datasets:
            combisv_path = os.path.join(evaluation_path, 'combisv_4callers')
            if os.path.exists(combisv_path):
                # combisv_4callers only supports union analysis
                union_eval_path = os.path.join(combisv_path, 'merged_union_evaluation', 'summary.json')
                if os.path.exists(union_eval_path):
                    metrics = read_summary_json(union_eval_path)
                    results.append({
                        'dataset': dataset,
                        'tool': 'combisv_4callers',
                        'analysis_type': 'union',
                        **metrics
                    })
            
        # Iterate through each tool directory
        for tool_dir in os.listdir(evaluation_path):
            # Skip if it's combisv_4callers as we've already processed it
            if tool_dir == 'combisv_4callers':
                continue
                
            tool_path = os.path.join(evaluation_path, tool_dir)
            if not os.path.isdir(tool_path):
                continue
                
            # Process different analysis types
            for analysis_type in os.listdir(tool_path):
                analysis_path = os.path.join(tool_path, analysis_type)
                
                if analysis_type == 'support_threshold':
                    # Process min2, min3, etc. subdirectories
                    for threshold_dir in os.listdir(analysis_path):
                        threshold_path = os.path.join(analysis_path, threshold_dir)
                        eval_dir = next((d for d in os.listdir(threshold_path) 
                                      if d.endswith('_evaluation')), None)
                        
                        if eval_dir:
                            summary_path = os.path.join(threshold_path, eval_dir, 'summary.json')
                            if os.path.exists(summary_path):
                                metrics = read_summary_json(summary_path)
                                results.append({
                                    'dataset': dataset,
                                    'tool': tool_dir,
                                    'analysis_type': threshold_dir,
                                    **metrics
                                })
                                
                else:  # union or intersection
                    eval_dir = next((d for d in os.listdir(analysis_path) 
                                   if d.endswith('_evaluation')), None)
                    
                    if eval_dir:
                        summary_path = os.path.join(analysis_path, eval_dir, 'summary.json')
                        if os.path.exists(summary_path):
                            metrics = read_summary_json(summary_path)
                            results.append({
                                'dataset': dataset,
                                'tool': tool_dir,
                                'analysis_type': analysis_type,
                                **metrics
                            })
    
    return results

def main():
    # Base path for the benchmark results
    base_path = '/projects/b1171/qgn1237/6_SV_VCF_merger/20241202_octopusv_merge_benchmark'
    
    # Collect all results
    results = process_directory(base_path)
    
    # Convert to DataFrame
    df = pd.DataFrame(results)
    
    # Sort data
    df = df.sort_values(['dataset', 'tool', 'analysis_type'])
    
    # Fill NaN values with 'NA'
    df = df.fillna('NA')
    
    # Create Excel writer object
    output_file = 'benchmark_results_summary.xlsx'
    writer = pd.ExcelWriter(output_file, engine='openpyxl')
    
    # Create separate sheet for each dataset
    for dataset in df['dataset'].unique():
        dataset_df = df[df['dataset'] == dataset]
        dataset_df.to_excel(
            writer, 
            sheet_name=dataset,
            index=False,
            columns=['tool', 'analysis_type', 'precision', 'recall', 'f1']
        )
    
    # Create overview sheet
    df.to_excel(
        writer,
        sheet_name='Overview',
        index=False,
        columns=['dataset', 'tool', 'analysis_type', 'precision', 'recall', 'f1']
    )
    
    # Save Excel file
    writer.close()
    
    print(f"Results have been saved to {output_file}")

if __name__ == "__main__":
    main()
