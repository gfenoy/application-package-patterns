import click
from vegetation_indexes.pattern_1 import pattern_1
from vegetation_indexes.pattern_2 import pattern_2
from vegetation_indexes.pattern_3 import pattern_3
from vegetation_indexes.pattern_4 import pattern_4
from vegetation_indexes.pattern_5 import pattern_5
from vegetation_indexes.pattern_6 import pattern_6
from vegetation_indexes.pattern_7 import pattern_7
from vegetation_indexes.pattern_8 import pattern_8
from vegetation_indexes.pattern_9 import pattern_9
from vegetation_indexes.pattern_10 import pattern_10
from vegetation_indexes.pattern_11 import pattern_11
from vegetation_indexes.crop import crop_cli
from vegetation_indexes.ndi import ndi_cli
from vegetation_indexes.otsu import otsu_cli

@click.group()
def app_group():
    pass

for pattern in [pattern_1, pattern_2, pattern_3, pattern_4, pattern_5, pattern_6, pattern_7, pattern_8, pattern_9, pattern_10, pattern_11, crop_cli, ndi_cli, otsu_cli]:
    app_group.add_command(pattern)

