
import subprocess
import graphviz
import yaml
from cwl_wrapper import app
from click.testing import CliRunner
import os
import tempfile
from cwltool.main import main as cwlmain
from cwltool.context import LoadingContext, RuntimeContext
from cwltool.executors import NoopJobExecutor
from io import StringIO
from time import sleep

def plot_cwl(cwl_file, entrypoint="main"):
    """Plot a CWL file using Graphviz."""
    
    args = ["--print-dot", f"{cwl_file}#{entrypoint}"]

    stream_err = StringIO()
    stream_out = StringIO()

    _ = cwlmain(
        args,
        stdout=stream_out,
        stderr=stream_err,
        executor=NoopJobExecutor(),
        loadingContext=LoadingContext(),
        runtimeContext=RuntimeContext(),
    )
    
    return stream_out.getvalue()


def wrap_cwl(cwl_file, entrypoint="main"):

    stagein_cwl_file = os.path.join("..", "tests", "templates/stage-in.yaml")
    stageout_cwl_file = os.path.join("..", "tests","templates/stage-out.yaml")
    main_cwl_file = os.path.join("..", "tests", "templates/main.yaml")
    rules_file = os.path.join("..", "tests", "templates/rules.yaml")

    runner = CliRunner()
    result = runner.invoke(
        app.main,
        [
            "--maincwl",
            main_cwl_file,
            "--stagein",
            stagein_cwl_file,
            "--stageout",
            stageout_cwl_file,
            "--rulez",
            rules_file,
            f"{cwl_file}#{entrypoint}",
        ],
    )

    return result.output