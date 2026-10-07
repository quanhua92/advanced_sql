"""Offline tests of argument validation. Docker and PostgreSQL are not invoked."""
import importlib.util
from pathlib import Path
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('course_cli', ROOT / 'scripts/course.py')
course = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(course)


class CourseCliTests(unittest.TestCase):
    def test_manifest_lesson_resolution(self):
        self.assertEqual(course.select_entry(21)['slug'], 'partitioning')

    def test_bonus_resolution(self):
        self.assertEqual(course.select_entry(26, 'extras')['slug'], 'row_level_security')

    def test_unknown_lesson_rejected(self):
        with self.assertRaises(ValueError):
            course.select_entry(99)

    def test_sql_path_escape_rejected(self):
        with self.assertRaises(ValueError):
            course.run_sql('../not_this_course.sql', 'invalid')

    def test_reset_requires_explicit_yes(self):
        with patch.object(course, 'execute') as invoke:
            self.assertEqual(course.main(['reset']), 1)
            invoke.assert_not_called()

    def test_invalid_seed_rejected_before_docker(self):
        with patch.object(course, 'execute') as invoke:
            self.assertEqual(course.main(['reseed', '--rows', '1', '--yes']), 1)
            invoke.assert_not_called()

    def test_clean_schema_range_guard(self):
        with patch.object(course, 'execute') as invoke:
            self.assertEqual(course.main(['clean', '27']), 1)
            invoke.assert_not_called()

    def test_solution_maps_to_packaged_file(self):
        with patch.object(course, 'execute') as invoke:
            self.assertEqual(course.main(['solution', '4']), 0)
            args = invoke.call_args.args[0]
            self.assertIn('/course/sql/solutions/04_composite_indexes.sql', args)

    def test_down_preserves_volume_by_default(self):
        with patch.object(course, 'execute') as invoke:
            self.assertEqual(course.main(['down']), 0)
            invoke.assert_called_once_with(['down'])


if __name__ == '__main__':
    unittest.main()
