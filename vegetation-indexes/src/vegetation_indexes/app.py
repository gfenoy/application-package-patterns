import click
from vegetation_indexes.pattern_1 import pattern_1
from vegetation_indexes.pattern_2 import pattern_2

@click.group()
def app_group():
    pass

app_group.add_command(pattern_1)
app_group.add_command(pattern_2)