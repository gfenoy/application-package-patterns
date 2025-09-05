import unittest
from click.testing import CliRunner

from runner.app import app_group


class TestCli(unittest.TestCase):
    def setUp(self):
        self.runner = CliRunner()

    def test_runner_app(self):
        result = self.runner.invoke(app_group, ["--help"])
        self.assertEqual(result.exit_code, 0)
        self.assertIn("Usage: app [OPTIONS] COMMAND [ARGS]...", result.output)

    def test_pattern_1(self):
        result = self.runner.invoke(
            app_group,
            [
                "pattern-1",
                "--help",
            ],
        )
        self.assertEqual(result.exit_code, 0)
        self.assertIn("Usage: app pattern-", result.output)

    def test_pattern_2(self):
        result = self.runner.invoke(
            app_group,
            [
                "pattern-2",
                "--help",
            ],
        )
        self.assertEqual(result.exit_code, 0)
        self.assertIn("Usage: app pattern-", result.output)

    def test_pattern_3(self):
        result = self.runner.invoke(
            app_group,
            [
                "pattern-3",
                "--help",
            ],
        )
        self.assertEqual(result.exit_code, 0)
        self.assertIn("Usage: app pattern-", result.output)

    def test_pattern_4(self):
        result = self.runner.invoke(
            app_group,
            [
                "pattern-4",
                "--help",
            ],
        )
        self.assertEqual(result.exit_code, 0)
        self.assertIn("Usage: app pattern-", result.output)

    def test_pattern_5(self):
        result = self.runner.invoke(
            app_group,
            [
                "pattern-5",
                "--help",
            ],
        )
        self.assertEqual(result.exit_code, 0)
        self.assertIn("Usage: app pattern-", result.output)

    def test_pattern_6(self):
        result = self.runner.invoke(
            app_group,
            [
                "pattern-6",
                "--help",
            ],
        )
        self.assertEqual(result.exit_code, 0)
        self.assertIn("Usage: app pattern-", result.output)

    def test_pattern_7(self):
        result = self.runner.invoke(
            app_group,
            [
                "pattern-7",
                "--help",
            ],
        )
        self.assertEqual(result.exit_code, 0)
        self.assertIn("Usage: app pattern-", result.output)

    def test_pattern_8(self):
        result = self.runner.invoke(
            app_group,
            [
                "pattern-8",
                "--help",
            ],
        )
        self.assertEqual(result.exit_code, 0)
        self.assertIn("Usage: app pattern-", result.output)

    def test_pattern_9(self):
        result = self.runner.invoke(
            app_group,
            [
                "pattern-9",
                "--help",
            ],
        )
        self.assertEqual(result.exit_code, 0)
        self.assertIn("Usage: app pattern-", result.output)

    def test_pattern_10(self):
        result = self.runner.invoke(
            app_group,
            [
                "pattern-10",
                "--help",
            ],
        )
        self.assertEqual(result.exit_code, 0)
        self.assertIn("Usage: app pattern-", result.output)

    def test_pattern_11(self):
        result = self.runner.invoke(
            app_group,
            [
                "pattern-11",
                "--help",
            ],
        )
        self.assertEqual(result.exit_code, 0)
        self.assertIn("Usage: app pattern-", result.output)

    def test_crop_cli(self):
        result = self.runner.invoke(
            app_group,
            [
                "crop-cli",
                "--help",
            ],
        )
        self.assertEqual(result.exit_code, 0)
        self.assertIn("Usage: app crop-cli", result.output)

    def test_ndi_cli(self):
        result = self.runner.invoke(
            app_group,
            [
                "ndi-cli",
                "--help",
            ],
        )
        self.assertEqual(result.exit_code, 0)
        self.assertIn("Usage: app ndi-cli", result.output)

    def test_otsu_cli(self):
        result = self.runner.invoke(
            app_group,
            [
                "otsu-cli",
                "--help",
            ],
        )
        self.assertEqual(result.exit_code, 0)
        self.assertIn("Usage: app otsu-cli", result.output)
