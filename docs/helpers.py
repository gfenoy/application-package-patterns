
import graphviz
import yaml
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
from cwl_utils.parser import load_document
from eoap_cwlwrap import wrap
from cwl_loader import load_cwl_from_location
from PIL import Image
from plantuml import deflate_and_encode
from urllib.request import urlopen
import cwl_utils

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
        
        headers = ["Id", "Type", "Label", "Doc"]
        md = "| " + " | ".join(headers) + " |\n"
        md += "| " + " | ".join(["---"] * len(headers)) + " |\n"

        for inp in self.workflow.inputs:
            if isinstance(inp.type_, (cwl_utils.parser.cwl_v1_0.InputArraySchema, cwl_utils.parser.cwl_v1_1.InputArraySchema, cwl_utils.parser.cwl_v1_2.InputArraySchema)):
                inp_type = f"Array of {inp.type_.items}"
            else:
                inp_type = inp.type_
            md += f"| `{inp.id.replace(f'file:///#{self.entrypoint}/', '')}` | {inp_type} | {inp.label} | {inp.doc} |\n"
        
        display(Markdown(md))

    def display_outputs(self):
        headers = ["Id", "Type", "Label", "Doc"]
        md = "| " + " | ".join(headers) + " |\n"
        md += "| " + " | ".join(["---"] * len(headers)) + " |\n"

        for out in self.workflow.outputs:
            if isinstance(out.type_, (cwl_utils.parser.cwl_v1_0.OutputArraySchema, cwl_utils.parser.cwl_v1_1.OutputArraySchema, cwl_utils.parser.cwl_v1_2.OutputArraySchema)):
                out_type = f"Array of {out.type_.items}"
            else:
                out_type = out.type_
            md += f"| `{out.id.replace(f'file:///#{self.entrypoint}/', '')}` | {out_type} | {out.label} | {out.doc} |\n"
        
        display(Markdown(md))

    def display_steps(self):
        headers = ["Id", "Runs", "Label", "Doc"]
        md = "| " + " | ".join(headers) + " |\n"
        md += "| " + " | ".join(["---"] * len(headers)) + " |\n"

        for step in self.workflow.steps:
            md += f"| `{step.id.replace(f'file:///#{self.entrypoint}/', '')}` | {step.run} | {step.label} | {step.doc} |\n"
        
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
        return graphviz.Source(plot_cwl(self.cwl_file, self.entrypoint))
    
class WorkflowWrapper():
    def __init__(self, cwl_file, entrypoint):
        self.cwl_file = cwl_file
        self.workflow = load_cwl_from_location(path=cwl_file)
        self.entrypoint = entrypoint
        self.base_url = 'https://raw.githubusercontent.com/eoap/application-package-patterns/refs/heads/main'

    def wrap(self):
        directory_stage_in = load_cwl_from_location(path=f"{self.base_url}/templates/stage-in.cwl")
        file_stage_in = load_cwl_from_location(path=f"{self.base_url}/templates/stage-in-file.cwl")
        workflows_cwl = load_cwl_from_location(path=f"{self.base_url}/cwl-workflow/{self.entrypoint}.cwl")
        stage_out_cwl = load_cwl_from_location(path=f"{self.base_url}/templates/stage-out.cwl")

        return wrap(
            directory_stage_in=directory_stage_in,
            file_stage_in=file_stage_in,
            workflows=workflows_cwl,
            workflow_id=self.entrypoint,
            stage_out=stage_out_cwl
        )
