#!/bin/bash

for i in ../javascript/img_hd/*; do convert -resize 50% $i ../javascript/img/`basename $i`; done
