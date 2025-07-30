
import graphviz
import yaml
from cwl_wrapper import app
from click.testing import CliRunner
import os
from cwltool.main import main as cwlmain
from cwltool.context import LoadingContext, RuntimeContext
from cwltool.executors import NoopJobExecutor
from io import StringIO
from IPython.display import Markdown, display
from cwl_utils.parser import load_document
from eoap_cwlwrap import wrap
from eoap_cwlwrap.loader import ( load_workflow, dump_workflow )

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


class WorkflowViewer():
    def __init__(self, cwl_file, entrypoint):
        self.cwl_file = cwl_file
        with open(cwl_file, 'r') as f:
            cwl_content = f.read()
        self.cwl_dict = yaml.safe_load(StringIO(cwl_content))
        self.workflow = load_document(self.cwl_dict, baseuri="file:///", id_=entrypoint)
        self.entrypoint = entrypoint
        self.output = '.wrapped.cwl'
        self.base_url = 'https://raw.githubusercontent.com/eoap/application-package-patterns/refs/heads/main'

    def display_inputs(self):
        md = "### Inputs\n"
        headers = ["Id", "Type", "Label", "Doc"]
        md += "| " + " | ".join(headers) + " |\n"
        md += "| " + " | ".join(["---"] * len(headers)) + " |\n"

        for inp in self.workflow.inputs:
            md += f"| `{inp.id.replace(f'file:///#{self.entrypoint}/', '')}` | {inp.type_} | {inp.label} | {inp.doc} |\n"
        
        display(Markdown(md))

    def display_outputs(self):
        md = "### Outputs\n"
        headers = ["Id", "Type", "Label", "Doc"]
        md += "| " + " | ".join(headers) + " |\n"
        md += "| " + " | ".join(["---"] * len(headers)) + " |\n"

        for out in self.workflow.outputs:
            md += f"| `{out.id.replace(f'file:///#{self.entrypoint}/', '')}` | {out.type_} | {out.label} | {out.doc} |\n"
        
        display(Markdown(md))

    def display_steps(self):
        md = "### Steps\n"
        headers = ["Id", "Runs", "Label", "Doc"]
        md += "| " + " | ".join(headers) + " |\n"
        md += "| " + " | ".join(["---"] * len(headers)) + " |\n"

        for step in self.workflow.steps:
            md += f"| `{step.id.replace(f'file:///#{self.entrypoint}/', '')}` | {step.run} | {step.label} | {step.doc} |\n"
        
        display(Markdown(md))

    def plot(self):
        return graphviz.Source(plot_cwl(self.cwl_file, self.entrypoint))
    
class WorkflowWrapper():
    def __init__(self, cwl_file, entrypoint):
        self.cwl_file = cwl_file
        self.workflow = load_workflow(path=cwl_file)
        self.entrypoint = entrypoint
        self.base_url = 'https://raw.githubusercontent.com/eoap/application-package-patterns/refs/heads/main'

    def wrap(self):
        directory_stage_in = load_workflow(path=f"{self.base_url}/templates/stage-in.cwl")
        file_stage_in = load_workflow(path=f"{self.base_url}/templates/stage-in-file.cwl")
        workflows_cwl = load_workflow(path=f"{self.base_url}/cwl-workflow/{self.entrypoint}.cwl")
        stage_out_cwl = load_workflow(path=f"{self.base_url}/templates/stage-out.cwl")

        return wrap(
            directory_stage_in=directory_stage_in,
            file_stage_in=file_stage_in,
            workflows=workflows_cwl,
            workflow_id=self.entrypoint,
            stage_out=stage_out_cwl
        )
