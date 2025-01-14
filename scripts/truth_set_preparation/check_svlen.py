#!/usr/bin/env python3
import argparse
import sys

def main():
    parser = argparse.ArgumentParser(description="Check SVLEN fields in a VCF file.")
    parser.add_argument("-i", "--input", required=True, help="Input VCF file")
    args = parser.parse_args()

    invalid_entries = 0
    total_variants = 0

    with open(args.input, 'r') as infile:
        for line in infile:
            line = line.strip()
            if line.startswith('#'):  # Skip header lines
                continue
            
            total_variants += 1

            # Split the VCF line
            fields = line.split('\t')
            if len(fields) < 8:
                print(f"Invalid VCF line (less than 8 columns): {line}", file=sys.stderr)
                invalid_entries += 1
                continue

            info_field = fields[7]  # INFO field is at index 7
            # Parse the INFO field into key-value pairs
            info_dict = {}
            for kv in info_field.split(';'):
                if '=' in kv:
                    key, val = kv.split('=', 1)
                    info_dict[key] = val
                else:
                    # Just a flag without value
                    info_dict[kv] = True
            
            # Check SVLEN
            svlen = info_dict.get("SVLEN", None)
            if svlen is None:
                # No SVLEN present
                print(f"Missing SVLEN: {line}")
                invalid_entries += 1
            else:
                # SVLEN might have multiple values if Number=., but we expect one integer
                # If multiple values, we check each one
                vals = svlen.split(',')
                # Check if all values are integers
                all_integers = True
                for v in vals:
                    try:
                        int(v)
                    except ValueError:
                        all_integers = False
                        break
                if not all_integers:
                    print(f"Non-integer SVLEN encountered: {line}")
                    invalid_entries += 1
                else:
                    # Check if there's any None or empty strings
                    if any(v.strip() == '' for v in vals):
                        print(f"Empty SVLEN value: {line}")
                        invalid_entries += 1

    print(f"Total variants checked: {total_variants}", file=sys.stderr)
    print(f"Invalid SVLEN entries found: {invalid_entries}", file=sys.stderr)

    if invalid_entries > 0:
        sys.exit(1)


if __name__ == "__main__":
    main()

