import os
import unittest
import tempfile
import ruamel.yaml
from cwltool.main import main as cwlmain
from cwltool.context import LoadingContext, RuntimeContext
from cwltool.executors import NoopJobExecutor
from io import StringIO
from click.testing import CliRunner
import yaml
from cwl_wrapper import app

        
class TestCWL(unittest.TestCase):

    def validate_cwl_dict(self, cwl_dict) -> int:
        with tempfile.NamedTemporaryFile(suffix=".cwl", mode="w", delete=True) as tmp:
            yaml = ruamel.yaml.YAML()
            yaml.dump(cwl_dict, tmp)
            tmp.flush()

            args = ["--enable-ext", "--validate", tmp.name]

            stream_err = StringIO()
            stream_out = StringIO()

            result = cwlmain(
                args,
                stdout=stream_out,
                stderr=stream_err,
                executor=NoopJobExecutor(),
                loadingContext=LoadingContext(),
                runtimeContext=RuntimeContext(),
            )
            if result != 0:
                print(stream_out.getvalue())
                raise RuntimeError(f"Validation failed with exit code {result}")

    def setUp(self):
        self.stagein_cwl_file = os.path.join(os.path.dirname(__file__), "templates/stage-in.yaml")
        self.stageout_cwl_file = os.path.join(os.path.dirname(__file__), "templates/stage-out.yaml")
        self.main_cwl_file = os.path.join(os.path.dirname(__file__), "templates/main.yaml")
        self.rules_file = os.path.join(os.path.dirname(__file__), "templates/rules.yaml")

        self.app_cwl_file = None    

    def _cwl_validation(self):
        #assert self.app_cwl_file, "app_cwl_file must be set by subclass"

        self.validate_cwl_dict(yaml.load(open(self.app_cwl_file, 'r'), Loader=yaml.SafeLoader))

    def _wrapped_cwl_validation(self):

        runner = CliRunner()
        result = runner.invoke(
            app.main,
            [
                "--maincwl",
                self.main_cwl_file,
                "--stagein",
                self.stagein_cwl_file,
                "--stageout",
                self.stageout_cwl_file,
                "--rulez",
                self.rules_file,
                self.app_cwl_file + "#main",
            ],
        )

        self.assertEqual(result.exit_code, 0, f"Wrapped CWL {self.app_cwl_file} validation failed")

        self.validate_cwl_dict(yaml.load(result.output, Loader=yaml.SafeLoader))
