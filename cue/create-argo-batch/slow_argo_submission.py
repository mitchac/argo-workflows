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
import tempfile
import time
import extern

import queue

sys.path = [os.path.join(os.path.dirname(os.path.realpath(__file__)),'..')] + sys.path

if __name__ == '__main__':
    parent_parser = argparse.ArgumentParser()

    parent_parser.add_argument('--input-json',required=True, help='JSON format input e.g. merged with "jq -n \'[ inputs ]\' *"')
    
    parent_parser.add_argument('--sleep-interval', type=int, help='sleep this many seconds between submissions', default=60*5)
    parent_parser.add_argument('--batch-size', type=int, help='submit this many each time')
    parent_parser.add_argument('--batch-size-file', help='read from a file which is just a number - submit this many each time')
    parent_parser.add_argument('--blacklist', help='Ignore accessions that are in this file')
    parent_parser.add_argument('--whitelist', help='Only submit accessions that are in this file')
    
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
    nickname = j['data']['summary']

    entries = j['data']['sra_accessions']

    logging.info(f"Found {len(entries)} accessions from JSON input")

    if args.whitelist:
        with open(args.whitelist) as f:
            whitelist = list([s.strip() for s in f.readlines()])
    if args.blacklist:
        with open(args.blacklist) as f:
            blacklist = list([s.strip() for s in f.readlines()])

    num_submitted = 0
    qu = queue.Queue()
    for e in entries:
        if args.whitelist is None or e['acc'] in whitelist:
            if args.blacklist is None or e['acc'] not in blacklist:
                qu.put(e)
    total_to_submit = qu.qsize()
    logging.info(f"Found {total_to_submit} accessions to submit after white and blacklist filtering")

    if args.batch_size:
        batch_size = args.batch_size
    elif args.batch_size_file:
        batch_size = 0
    else:
        raise Exception("Need batch size or batch size file")

    while not qu.empty():
        if args.batch_size_file:
            with open(args.batch_size_file) as f:
                prev = batch_size
                batch_size = int(f.read().strip())
                if prev != batch_size:
                    logging.info(f"Changing batch size to {batch_size} entries")
        chunk = []
        while not qu.empty() and len(chunk) < batch_size:
            chunk.append(qu.get())

        # Create cue format manually

        # package create_argo_batch

        # _data: {
        #     // meta info
        #     summary:  "argo-first-batch"

        #     sra_accessions: [
        #         {acc: "ERR4374862", mbases: 444, mbytes: 555},
        #     ]
        # }

        # use cue import because otherwise the _data is surrounded by {}, which fails it.
        for_cue = json.dumps(
            {"data": {
                "summary": nickname,
                "sra_accessions": chunk
            }}, indent=4)
        with tempfile.NamedTemporaryFile(suffix='.json') as f:
            f.write(for_cue.encode())
            f.flush()
            cue_out = extern.run(f"cue import {f.name} -o -")
        logging.debug(f"cue_out was {cue_out}")

        # Add the extra bits to fix formatting
        cue_out = "package create_argo_batch\n\n_"+cue_out

        with tempfile.NamedTemporaryFile(suffix='.cue') as f:
            f.write(cue_out.encode())
            f.flush()

            logging.info("Creating workflow YAML and submitting ..")
            extern.run(f"cue eval . {f.name} --out yaml -p create_argo_batch |yq eval '.merged_templates.[] | splitDoc' - >merged-workflow-templates-list.yaml")

            # Keep trying submission, in case of head node failure.
            while True:
                try:
                    extern.run("argo submit -n argo -o json merged-workflow-templates-list.yaml |jq > submissions/slow-`date +%Y%m%d-%I%M`.argo_submission.json")
                except extern.ExternCalledProcessError as e:
                    logging.warn("Failed to argo submit. Retrying after pause. Error was {}".format(e))
                    time.sleep(args.sleep_interval)
                    continue

                logging.info("Submitted")
                break

            num_submitted += len(chunk)
            logging.info(f"Submitted {num_submitted} out of {total_to_submit} i.e. {round(float(num_submitted)/total_to_submit*100)}%")

            if num_submitted < total_to_submit:
                logging.info("sleeping ..")
                time.sleep(args.sleep_interval)

    logging.info("Finished all submissions")
