#!/usr/bin/env python3

###############################################################################
#
#    Copyright (C) 2020 Ben Woodcroft
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
###############################################################################

__author__ = "Ben Woodcroft"
__copyright__ = "Copyright 2020"
__credits__ = ["Ben Woodcroft"]
__license__ = "GPL3"
__maintainer__ = "Ben Woodcroft"
__email__ = "benjwoodcroft near gmail.com"
__status__ = "Development"

import argparse
import logging
import sys
import os
import json
import random

sys.path = [os.path.join(os.path.dirname(os.path.realpath(__file__)),'..')] + sys.path

if __name__ == '__main__':
    parent_parser = argparse.ArgumentParser()

    parent_parser.add_argument('--input-json',required=True, help='JSON format input e.g. merged with "jq -n \'[ inputs ]\' *"')
    parent_parser.add_argument('--nickname',required=True)
    parent_parser.add_argument('--sample', type=int, help='randomly choose this many runs [default: no sampling]')
    
    parent_parser.add_argument('--debug', help='output debug information', action="store_true")
    #parent_parser.add_argument('--version', help='output version information and quit',  action='version', version=repeatm.__version__)
    parent_parser.add_argument('--quiet', help='only output errors', action="store_true")

    args = parent_parser.parse_args()

    # Setup logging
    if args.debug:
        loglevel = logging.DEBUG
    elif args.quiet:
        loglevel = logging.ERROR
    else:
        loglevel = logging.INFO
    logging.basicConfig(level=loglevel, format='%(asctime)s %(levelname)s: %(message)s', datefmt='%m/%d/%Y %I:%M:%S %p')

    with open(args.input_json) as f:
        j = json.load(f)

    # {
    # "data": {
    #     "summary": "first test set of singlem runs for argo",
    #     "sra_accessions": [
    #         {
    #             "number": "SRR12512309",
    #             "GB": 1,
    #             "gbp": 2
    #         },
    jo = {
        'data': {
            'summary': args.nickname,
            'sra_accessions': []
        }
    }

    #     [
    #   {
    #     "acc": "SRR1046270",
    #     "mbases": "379",
    #     "mbytes": "224"
    #   },
    count = 0
    fails = 0
    entries = []
    for e in j:
        if 'acc' not in e or 'mbases' not in e or 'mbytes' not in e:
            logging.debug("Incomplete metadata for {}".format(e))
            fails += 1
            continue

        mbases = int(e['mbases'])
        mbytes = int(e['mbytes'])
        if str(mbases) != e['mbases']: raise Exception("INT format error with {}".format(e))
        if str(mbytes) != e['mbytes']: raise Exception("INT format error with {}".format(e))
        e2 = {
            'acc': e['acc'],
            'mbases': mbases,
            'mbytes': mbytes
        }
        entries.append(e2)
        count += 1

    logging.info("Consolidated {} SRA accessions, with {} failed due to incomplete metadata".format(count, fails))

    final_entries = entries
    if args.sample:
        logging.info("Randomly choosing {} entries".format(args.sample))
        final_entries = random.sample(entries, args.sample)

    jo['data']['sra_accessions'] = final_entries

    json.dump(jo, sys.stdout, indent=4)