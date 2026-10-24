"""Turn vfx/lab/<Service>/... into Lua chunks that recreate the scripts in Studio (run via Ropilot's
edit-context command or the command bar). One chunk per service. Usage: python3 build_install.py OUTDIR"""
import os, sys
ROOT = os.path.join(os.path.dirname(__file__), '..')
SERVICES = {'ReplicatedStorage': 'game:GetService("ReplicatedStorage")',
            'ServerScriptService': 'game:GetService("ServerScriptService")',
            'StarterPlayerScripts': 'game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")'}
def long_string(src):
    level = 0
    while ']' + '=' * level + ']' in src: level += 1
    eq = '=' * level
    return '[' + eq + '[\n' + src + ']' + eq + ']'
def main(out):
    os.makedirs(out, exist_ok=True)
    for svc, expr in SERVICES.items():
        base = os.path.join(ROOT, svc)
        lines = ['local svc = ' + expr, 'local made = {}',
                 'local function folder(parent, name) local f = parent:FindFirstChild(name) if not f then f = Instance.new("Folder") f.Name = name f.Parent = parent end return f end',
                 'local function put(parent, name, class, src) local old = parent:FindFirstChild(name) if old and old.ClassName ~= class then old:Destroy() old = nil end local s = old or Instance.new(class) s.Name = name s.Source = src s.Parent = parent table.insert(made, s:GetFullName()) end']
        for dirpath, dirs, files in os.walk(base):
            dirs.sort()
            rel = os.path.relpath(dirpath, base)
            parts = [] if rel == '.' else rel.split(os.sep)
            parent = 'svc'
            for p in parts:
                parent = f'folder({parent}, "{p}")'
            for f in sorted(files):
                if not f.endswith('.luau'): continue
                name = f[:-5]; cls = 'ModuleScript'
                if name.endswith('.server'): name, cls = name[:-7], 'Script'
                elif name.endswith('.client'): name, cls = name[:-7], 'LocalScript'
                src = open(os.path.join(dirpath, f), encoding='utf-8').read()
                lines.append(f'put({parent}, "{name}", "{cls}", {long_string(src)})')
        lines.append('return "installed " .. #made .. ": " .. table.concat(made, ", ")')
        open(os.path.join(out, svc + '.lua'), 'w', encoding='utf-8').write('\n'.join(lines))
        print(svc, os.path.getsize(os.path.join(out, svc + '.lua')))
main(sys.argv[1])
