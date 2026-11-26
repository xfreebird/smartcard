"""Reverse-engineering LLDB scans and the test-VM VNC/screenshot helpers, with fake debugger and VNC APIs."""
import builtins
import io
import sys
from types import SimpleNamespace
from unittest.mock import Mock, call, patch

from PIL import Image, ImageFont

from support import TempCase, png, run

SHOTS = '.agents/skills/esemnbun-test-vms/scripts/shots/'
RE_OUTPUT = '/Users/nghimbovschi/Projects/smartcard/re/'


class Region:
    def __init__(self, base=0, end=0, readable=True):
        self.base, self.end, self.readable = base, end, readable

    def IsReadable(self):
        return self.readable

    def GetRegionBase(self):
        return self.base

    def GetRegionEnd(self):
        return self.end


class FakeLLDB:
    """Minimal SB API: memory regions over one byte string, with an optional unreadable chunk."""

    def __init__(self, memory, regions, fail_from=None):
        self.memory, self.regions, self.fail_from, self.reads = memory, regions, fail_from, 0
        outer = self

        class SBError:
            def __init__(self):
                self.ok = True

            def Success(self):
                return self.ok

        class Regions:
            def GetSize(self):
                return len(outer.regions)

            def GetMemoryRegionAtIndex(self, index, region):
                region.__dict__.update(outer.regions[index].__dict__)

        class Process:
            def GetMemoryRegions(self):
                return Regions()

            def ReadMemory(self, address, size, error):
                outer.reads += 1
                error.ok = outer.fail_from is None or outer.reads < outer.fail_from
                return outer.memory[address:address + size] if error.ok else None

        self.module = SimpleNamespace(SBError=SBError, SBMemoryRegionInfo=Region,
                                      debugger=SimpleNamespace(GetSelectedTarget=lambda: SimpleNamespace(GetProcess=Process)))


class Captured(io.BytesIO):
    def close(self):
        self.final = self.getvalue()
        super().close()


class LLDBScriptTests(TempCase):
    def run_script(self, name, lldb):
        files = {}
        real_open = builtins.open

        def intercept(path, mode='r', *args, **kwargs):
            if str(path).startswith(RE_OUTPUT):
                files[str(path)] = Captured() if 'b' in mode else io.StringIO()
                files[str(path)].close = lambda stream=files[str(path)]: None
                return files[str(path)]
            return real_open(path, mode, *args, **kwargs)
        with patch.dict(sys.modules, {'lldb': lldb.module}), patch('builtins.open', intercept), \
                patch('os.makedirs') as makedirs:
            result = run('re/' + name)
        return result, files, makedirs

    def test_regions_with_markers_are_dumped_completely(self):
        memory = bytearray(b'\0' * 0x3000)
        memory[0x1100:0x1100 + 21] = b'token_class_idacosmox'
        lldb = FakeLLDB(bytes(memory), [Region(0x1000, 0x2000), Region(0x2000, 0x3000), Region(0, 0x10, False),
                                        Region(0x3000, 0x3000)])
        result, files, makedirs = self.run_script('dump_regions.py', lldb)
        self.assertEqual(result.code, 0, result.stderr)
        makedirs.assert_called_once_with(RE_OUTPUT + 'dumps', exist_ok=True)
        self.assertEqual(list(files), [RE_OUTPUT + 'dumps/region_1000_1000.bin'])
        self.assertEqual(files[RE_OUTPUT + 'dumps/region_1000_1000.bin'].getvalue(), bytes(memory[0x1000:0x2000]))
        self.assertIn('region 0x1000 size 0x1000 has 1 marker hits', result.stdout)
        self.assertTrue(result.stdout.endswith('done\n'))

    def test_unreadable_memory_is_skipped_or_ends_a_dump(self):
        memory = b'_detect_fs(): is a ID-A CosmoX' + b'\0' * 100
        result, files, _ = self.run_script('dump_regions.py', FakeLLDB(memory, [Region(0, len(memory))], fail_from=1))
        self.assertEqual(files, {})
        self.assertIn('dumping 0 regions', result.stdout)
        # The scan read succeeds, the dump read fails: the partial file is closed without data.
        result, files, _ = self.run_script('dump_regions.py', FakeLLDB(memory, [Region(0, len(memory))], fail_from=2))
        self.assertEqual(files[RE_OUTPUT + f'dumps/region_0_{len(memory):x}.bin'].getvalue(), b'')

    def test_scan_reports_every_pattern_with_context(self):
        memory = b'..cosmox..' + bytes.fromhex('492D28A5F7722BE4222BA37B4D53FE83') + b'\x1bLua..idacosmox'
        lldb = FakeLLDB(memory, [Region(0, len(memory)), Region(0, 0), Region(0, 4, False)])
        result, files, _ = self.run_script('scan.py', lldb)
        self.assertIn("TOTALS: {'const16': 1, 'lua_bytecode_hdr': 1, 'idacosmox': 1, 'cosmox': 2}", result.stdout)
        report = files[RE_OUTPUT + 'memscan_hits.txt'].getvalue()
        self.assertIn('HIT cosmox at 2:\n' + memory[:2 + 6 + 96].hex(), report)
        self.assertEqual(report.count('HIT '), 5)


class FakeVNC:
    def __init__(self):
        self.client = Mock()
        self.api = SimpleNamespace(connect=Mock(return_value=self.client))
        self.modules = {'vncdotool': SimpleNamespace(api=self.api), 'vncdotool.api': self.api}


class VNCHelperTests(TempCase):
    def drive(self, script, *argv, env=None):
        vnc = FakeVNC()
        with patch.dict(sys.modules, vnc.modules), patch('time.sleep'):
            result = run(SHOTS + script, *argv, env=env)
        return result, vnc

    def test_vshot_chains_pointer_keyboard_and_capture_commands(self):
        result, vnc = self.drive('vshot.py', '5901', 'click', '10', '20', 'rclick', '1', '2', 'dbl', '3', '4',
                                 'drag', '0', '0', '20', '40', 'move', '5', '6', 'type', 'aB:|', 'typeenv', 'SECRET_TEXT',
                                 'key', 'enter', 'sleep', '0.1', 'shot', 'out.png', env={'SECRET_TEXT': 'x!'})
        self.assertEqual(result.code, 0, result.stderr)
        vnc.api.connect.assert_called_once_with('127.0.0.1::5901')
        client = vnc.client
        self.assertEqual(client.mousePress.call_args_list[:4], [call(1), call(3), call(1), call(1)])
        self.assertEqual(client.mouseMove.call_args_list[3:5], [call(0, 0), call(1, 2)])
        self.assertIn(call(20, 40), client.mouseMove.call_args_list)
        self.assertEqual([c.args[0] for c in client.keyPress.call_args_list], ['a', 'b', ';', '\\', 'x', '1', 'enter'])
        self.assertEqual(client.keyDown.call_count, 4)
        client.captureScreen.assert_called_once_with('out.png')
        client.disconnect.assert_called_once()
        self.assertEqual(self.drive('vshot.py', '5901', 'jump')[0].code, 'unknown jump')

    def test_scroll_and_ctrl_click_helpers(self):
        result, vnc = self.drive('scroll.py', '5902', '5', '3', 'after.png')
        self.assertEqual(vnc.client.mousePress.call_args_list, [call(5)] * 3)
        vnc.client.captureScreen.assert_called_once_with('after.png')
        result, vnc = self.drive('scroll.py', '5902', '4', '1')
        vnc.client.captureScreen.assert_not_called()
        result, vnc = self.drive('ctrlclick.py', '10,20', '30,40', '50,60')
        self.assertEqual(vnc.client.mouseMove.call_args_list, [call(10, 20), call(30, 40), call(50, 60)])
        vnc.client.keyDown.assert_called_once_with('ctrl')
        vnc.client.keyUp.assert_called_once_with('ctrl')


class ScreenshotSheetTests(TempCase):
    def test_crop_and_contact_sheets(self):
        source = png(self.tmp / 'raw.png', (40, 30))
        run(SHOTS + 'crop.py', source, self.tmp / 'crop.png', '5,5,25,15')
        with Image.open(self.tmp / 'crop.png') as image:
            self.assertEqual(image.size, (20, 10))
        run(SHOTS + 'crop.py', source, self.tmp / 'copy.png')
        with Image.open(self.tmp / 'copy.png') as image:
            self.assertEqual(image.size, (40, 30))

        shots = self.tmp / 'Desktop/esemnbun-screenshots'
        for index in range(5):
            png(shots / f'linux/{index}-light.png', (800, 600))
        png(shots / 'macos/0-dark.png', (300, 900))
        real_truetype = ImageFont.truetype

        def missing_system_font(font, *args, **kwargs):
            if isinstance(font, str):
                raise OSError('no font')
            return real_truetype(font, *args, **kwargs)
        with patch.object(ImageFont, 'truetype', missing_system_font):
            result = run(SHOTS + 'sheets.py', env={'HOME': str(self.tmp)})
        self.assertEqual(result.stdout.splitlines(), ['macos dark 1', 'linux light 5'])
        with Image.open(shots / 'linux-light-contact-sheet.png') as sheet:
            self.assertEqual(sheet.size, (4 * 420, 2 * 326))
        self.assertFalse((shots / 'windows-light-contact-sheet.png').exists())
