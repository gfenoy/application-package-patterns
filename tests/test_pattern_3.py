import os
from tests.helpers import TestCWL

class TestPattern3(TestCWL):

    def setUp(self):
        super().setUp()
        self.app_cwl_file = os.path.join(os.path.dirname(__file__), "../cwl-workflow/pattern-3.cwl")

    def test_pattern3_validation(self):
        self._cwl_validation()

    def test_pattern3_wrapped_cwl(self):
        self._wrapped_cwl_validation()

    