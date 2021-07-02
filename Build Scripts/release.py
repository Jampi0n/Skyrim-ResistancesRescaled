import zipfile
import os
import project_config
import argparse
import pathlib

def pack(name, env, dir_name):
    prev_dir = os.getcwd()
    path = os.environ[env]
    assert path != "", "Set environment variable " + env + "!"
    path = os.path.join(path, dir_name)
    ignore_txt = str(pathlib.Path(__file__).parent.joinpath(pathlib.Path('release_ignore.txt')))
    ignore_list_file = open(ignore_txt)
    ignore_list = ignore_list_file.readlines()
    ignore_list_file.close()

    ignore_files = []
    ignore_extensions = []

    for line in ignore_list:
        line = line[:-1]
        if line.startswith('*.'):
            ignore_extensions.append(line[1:])
        else:
            ignore_files.append(line)

    pack_files = []

    for root, _, files in os.walk(path, topdown=False):
        for file_name in files:
            ext = os.path.splitext(file_name)[1]
            if ext not in ignore_extensions and file_name not in ignore_files:
                pack_files.append(os.path.relpath(os.path.join(root, file_name), path))

    zip_path = os.path.join(os.getcwd(), "Release", name)
    pathlib.Path(os.path.join(os.getcwd(), "Release")).mkdir(exist_ok=True)
    os.chdir(path)
    with zipfile.ZipFile(zip_path, 'w') as zip_file:
        for file in pack_files:
            print(file)
            zip_file.write(file)
    os.chdir(prev_dir)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('-S', '--SE', action='store_true', help='Only copy for SE.')
    parser.add_argument('-L', '--LE', action='store_true', help='Only copy for LE.')
    args = parser.parse_args()

    if not args.LE and not args.SE:
        args.LE = True
        args.SE = True

    config = project_config.Config(args.LE, args.SE)

    if config.le:
        pack(config.mod_name + ' LE ' + config.version + '.zip', 'SkyrimLEModPath', config.output)
    if config.se:
        pack(config.mod_name + ' SE ' + config.version + '.zip', 'SkyrimSEModPath', config.output)

if __name__ == '__main__':
    main()
