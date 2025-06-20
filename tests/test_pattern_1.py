import os
from tests.helpers import TestCWL

class TestPattern1(TestCWL):

    def setUp(self):
        super().setUp()
        self.app_cwl_file = os.path.join(os.path.dirname(__file__), "../cwl-workflow/pattern-1.cwl")

    def test_pattern1_validation(self):
        self._cwl_validation()

    def test_pattern1_wrapped_cwl(self):
        self._wrapped_cwl_validation()

    