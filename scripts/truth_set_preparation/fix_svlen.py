#!/usr/bin/env python3
import argparse
import sys

def main():
    parser = argparse.ArgumentParser(description="Fix SVLEN for TRA and INS in VCF for Truvari.")
    parser.add_argument("-i", "--input", required=True, help="Input VCF file")
    parser.add_argument("-o", "--output", required=True, help="Output VCF file")
    args = parser.parse_args()

    with open(args.input, 'r') as infile, open(args.output, 'w') as outfile:
        for line in infile:
            if line.startswith('#'):
                # Write header lines as-is
                outfile.write(line)
                continue

            fields = line.strip().split('\t')
            if len(fields) < 8:
                outfile.write(line)
                continue

            info_field = fields[7]
            info_pairs = info_field.split(';')
            info_dict = {}
            for kv in info_pairs:
                if '=' in kv:
                    key, val = kv.split('=', 1)
                    info_dict[key] = val
                else:
                    # Flag
                    info_dict[kv] = True

            svtype = info_dict.get("SVTYPE", None)
            svlen = info_dict.get("SVLEN", None)

            # If SVTYPE=TRA and no SVLEN, set SVLEN=0
            if svtype == "TRA" and svlen is None:
                info_dict["SVLEN"] = "0"

            # If SVTYPE=INS and SVLEN='.', recalculate SVLEN using END - POS
            if svtype == "INS" and svlen == ".":
                try:
                    pos = int(fields[1])
                    end_str = info_dict.get("END", None)
                    if end_str is not None and end_str != ".":
                        end = int(end_str)
                        # Calculate length (assuming END and POS define the insertion length)
                        calc_len = end - pos
                        if calc_len == 0:
                            # If the calculated length is zero, you might decide to set it to 1 
                            # or handle this as a special case.
                            calc_len = 1
                        info_dict["SVLEN"] = str(calc_len)
                    else:
                        # If END not available or '.', fallback to 1 or skip
                        info_dict["SVLEN"] = "1"
                except ValueError:
                    # If POS or END are not integers, fallback
                    info_dict["SVLEN"] = "1"

            # Rebuild the INFO field
            new_info = []
            for k, v in info_dict.items():
                if v is True:
                    new_info.append(k)
                else:
                    new_info.append(f"{k}={v}")

            fields[7] = ';'.join(new_info)
            outfile.write('\t'.join(fields) + '\n')

if __name__ == "__main__":
    main()

