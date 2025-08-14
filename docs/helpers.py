
import graphviz
from cwl2puml import (
    to_puml,
    DiagramType
)
from cwltool.main import main as cwlmain
from cwltool.context import LoadingContext, RuntimeContext
from cwltool.executors import NoopJobExecutor
from io import (
    StringIO,
    BytesIO
)
from IPython.display import Markdown, display
from eoap_cwlwrap import _search_workflow, wrap
from eoap_cwlwrap.types import type_to_string
from cwl_loader import load_cwl_from_location
from PIL import Image
from plantuml import deflate_and_encode
from urllib.request import urlopen
import cwl_utils

class WorkflowViewer():
    def __init__(self, cwl_file, workflow, entrypoint):
        self.cwl_file = cwl_file
        self.workflow = workflow
        self.entrypoint = entrypoint
        self.output = '.wrapped.cwl'
        self.base_url = 'https://raw.githubusercontent.com/eoap/application-package-patterns/refs/heads/main'

    @staticmethod
    def from_file(cwl_file, entrypoint):
        workflow = load_cwl_from_location(path=cwl_file)
        return WorkflowViewer(cwl_file, workflow, entrypoint)
    
    @staticmethod
    def from_reference(cwl_file, workflow, entrypoint):
        return WorkflowViewer(cwl_file, workflow, entrypoint)

    def display_inputs(self):
        headers = ["Id", "Type", "Label", "Doc"]
        md = "| " + " | ".join(headers) + " |\n"
        md += "| " + " | ".join(["---"] * len(headers)) + " |\n"

        for inp in _search_workflow(workflow_id=self.entrypoint, workflow=self.workflow).inputs:
            md += f"| `{inp.id}` | `{type_to_string(inp.type_)}` | {inp.label} | {inp.doc} |\n"
        
        display(Markdown(md))

    def display_outputs(self):
        headers = ["Id", "Type", "Label", "Doc"]
        md = "| " + " | ".join(headers) + " |\n"
        md += "| " + " | ".join(["---"] * len(headers)) + " |\n"

        for out in _search_workflow(workflow_id=self.entrypoint, workflow=self.workflow).outputs:
            md += f"| `{out.id}` | `{type_to_string(out.type_)}` | {out.label} | {out.doc} |\n"
        
        display(Markdown(md))

    def display_steps(self):
        headers = ["Id", "Runs", "Label", "Doc"]
        md = "| " + " | ".join(headers) + " |\n"
        md += "| " + " | ".join(["---"] * len(headers)) + " |\n"

        for step in _search_workflow(workflow_id=self.entrypoint, workflow=self.workflow).steps:
            md += f"| `{step.id.replace(f'file:///#{self.entrypoint}/', '')}` | `{step.run}` | {step.label} | {step.doc} |\n"
        
        display(Markdown(md))

    def display_components_diagram(self):
        out = StringIO()
        to_puml(
            cwl_document=self.workflow,
            diagram_type=DiagramType.COMPONENTS,
            output_stream=out
        )

        clear_output = out.getvalue()
        encoded = deflate_and_encode(clear_output)
        diagram_url = f"https://www.plantuml.com/plantuml/png/{encoded}"

        with urlopen(diagram_url) as url:
            img = Image.open(BytesIO(url.read()))
        display(img)

    def plot(self):
        args = ["--print-dot", f"{self.cwl_file}#{self.entrypoint}"]

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

        return graphviz.Source(stream_out.getvalue())
    
class WorkflowWrapper():
    def __init__(self, workflow, entrypoint):
        self.workflow = workflow
        self.entrypoint = entrypoint
        self.base_url = 'https://raw.githubusercontent.com/eoap/application-package-patterns/refs/heads/main'

    def wrap(self):
        directory_stage_in = load_cwl_from_location(path=f"{self.base_url}/templates/stage-in.cwl")
        file_stage_in = load_cwl_from_location(path=f"{self.base_url}/templates/stage-in-file.cwl")
        stage_out_cwl = load_cwl_from_location(path=f"{self.base_url}/templates/stage-out.cwl")

        return wrap(
            directory_stage_in=directory_stage_in,
            file_stage_in=file_stage_in,
            workflows=self.workflow,
            workflow_id=self.entrypoint,
            stage_out=stage_out_cwl
        )
