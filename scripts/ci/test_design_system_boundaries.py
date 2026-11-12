"""Keep reusable native UI independent of application and signing-domain types."""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[2]


class DesignSystemBoundaries(unittest.TestCase):
    def assert_boundary(self, folder, suffixes, forbidden):
        paths = [p for p in (ROOT / folder).rglob('*') if p.suffix in suffixes]
        self.assertTrue(paths, f'No design-system sources under {folder}')
        for path in paths:
            with self.subTest(path=str(path.relative_to(ROOT))):
                # Ignore documentation; check both imports and fully-qualified uses.
                text = re.sub(r'/\*.*?\*/|//[^\n]*', '', path.read_text(), flags=re.S)
                self.assertNotRegex(text, forbidden)

    def test_apple_components_have_no_application_or_core_types(self):
        self.assert_boundary('apple/Apps/Shared/DesignSystem', {'.swift'},
            r'\b(MoldSignKit|AppModel|ReaderStatus|CardSlot|SigningService|ActivityItem|Verdict|L10n|AppPreferencesStore)\b')
        package = (ROOT / 'apple/Package.swift').read_text()
        self.assertIn('.target(name: "DesignSystem", path: "Apps/Shared/DesignSystem")', package)
        ci = (ROOT / '.github/workflows/ci.yml').read_text()
        self.assertIn('swift build --package-path apple --target DesignSystem', ci)

    def test_android_components_only_use_ui_and_platform_dependencies(self):
        for folder in ['components', 'theme']:
            self.assert_boundary('android/app/src/main/kotlin/md/moldsign/app/ui/' + folder, {'.kt'},
                r'\bmd\.moldsign\.(?:core|transport)\b|\bmd\.moldsign\.app\.(?!(?:R|ui\.(?:components|theme))\b)')

    def test_windows_controls_have_no_application_services_or_domain_types(self):
        self.assert_boundary('windows/src/MoldSign.App/Controls', {'.cs', '.xaml'},
            r'\bMoldSign\.(?:Core|Desktop)\b|\bMoldSign\.App\.(?!Controls\b)|'
            r'\b(AppState|AppServices|WalletCardItem|CertificateSummary|App\.Current|WindowHelpers)\b')

    def test_linux_widgets_have_no_domain_or_controller_types(self):
        self.assert_boundary('linux/Sources/MoldSignGnome/Presentation/DesignSystem', {'.swift'},
            r'\b(MoldSignKit|AppController|ReaderStatus|CardSlot|SigningService|CertificateSummary|Format)\b')
        self.assertIn('python3 scripts/ci/check-linux-design-system.py',
                      (ROOT / '.github/workflows/ci.yml').read_text())
        # The GTK and localization support used by these widgets must also remain core-free.
        for support in ['Infrastructure/GTK', 'Infrastructure/Localization']:
            paths = (ROOT / 'linux/Sources/MoldSignGnome' / support).glob('*.swift')
            for path in paths:
                if path.name == 'Files.swift':
                    continue  # OS file actions are not imported by the reusable widgets.
                self.assertNotIn('import MoldSignKit', path.read_text(), path.name)


if __name__ == '__main__':
    unittest.main()
