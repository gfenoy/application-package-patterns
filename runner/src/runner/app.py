import click
from runner.pattern_1 import pattern_1
from runner.pattern_2 import pattern_2
from runner.pattern_3 import pattern_3
from runner.pattern_4 import pattern_4
from runner.pattern_5 import pattern_5
from runner.pattern_6 import pattern_6
from runner.pattern_7 import pattern_7
from runner.pattern_8 import pattern_8
from runner.pattern_9 import pattern_9
from runner.pattern_10 import pattern_10
from runner.pattern_11 import pattern_11
from runner.crop import crop_cli
from runner.ndi import ndi_cli
from runner.otsu import otsu_cli

@click.group()
def app_group():
    pass

patterns = [
    pattern_1,
    pattern_2,
    pattern_3,      
    pattern_4,
    pattern_5,
    pattern_6,
    pattern_7,
    pattern_8,
    pattern_9,
    pattern_10,
    pattern_11,
    crop_cli,
    ndi_cli,
    otsu_cli,
]

for pattern in patterns:
    app_group.add_command(pattern)

