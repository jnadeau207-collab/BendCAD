import json, os, subprocess, sys
sys.stdout.reconfigure(encoding="utf-8")
ROOT = 'C:/dev/BendCAD-k2'
ENV = dict(os.environ, BENDCAD_BIN='/home/jesse/bc/bendcad-g2', BENDCAD_TIMEOUT_MS='14400000',
           BENDCAD_LOG=ROOT + '/docs/receipts/g2/run1/calls.jsonl')
def call(tool, **args):
    r = subprocess.run(['node', ROOT + '/tools/mcp/mcpc.mjs', tool, json.dumps(args)], capture_output=True, text=True, env=ENV, encoding='utf-8')
    return r.stdout + r.stderr
if __name__ == '__main__':
    print(call(sys.argv[1], **json.loads(sys.argv[2])))
