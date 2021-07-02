import argparse
import shutil
import os
import pathlib
import project_config

def copy_file(args, config):
    for mod_dir in config.mod_directories:
        path = mod_dir.joinpath(pathlib.Path(args.target))
        if not os.path.exists(path):
            os.makedirs(path)
        shutil.copy(args.file, path)


def copy_directory(args, config):
    include = args.include.split(',') if args.include is not None else []
    exclude = args.exclude.split(',') if args.exclude is not None else []
    files = []
    for root, _, walk_files in os.walk(args.directory, topdown=False):
        for file_name in walk_files:
            include_file = False
            if len(include) > 0:
                for i in include:
                    if i[0] == '*':
                        if file_name.endswith(i[1:]):
                            include_file = True
                            break
                    else:
                        if file_name == i:
                            include_file = True
                            break
            else:
                include_file = True

            if include_file:
                if len(exclude) > 0:
                    for e in exclude:
                        if e[0] == '*':
                            if file_name.endswith(e[1:]):
                                include_file = False
                                break
                        else:
                            if file_name == e:
                                include_file = False
                                break

            if include_file:
                files.append(os.path.join(root, file_name))

    for mod_dir in config.mod_directories:
        for file in files:
            rel_path = os.path.relpath(file, args.directory)
            path = mod_dir.joinpath(pathlib.Path(args.target).joinpath(pathlib.Path(rel_path))).parent
            if not os.path.exists(path):
                os.makedirs(path)
            shutil.copy(file, path)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('-f', '--file', type=str, help='The file to copy.')
    parser.add_argument('-d', '--directory', type=str, help='The directory, whose files are copied.')
    parser.add_argument('-t', '--target', type=str, help='The target location in which files are copied.')
    parser.add_argument('-i', '--include', type=str,
                        help='If a directory is copied, these files will be included.'
                             ' By default, all files are included.'
                             ' Use * at the start to match suffixes:"*.txt".'
                             ' Use , to combine included files:"*.txt,meta.ini"')
    parser.add_argument('-e', '--exclude', type=str,
                        help='If a directory is copied, these files will be excluded.'
                             ' By default, no files are excluded.'
                             ' Use * at the start to match suffixes:"*.txt".'
                             ' Use , to combine excluded files:"*.txt,meta.ini"')
    parser.add_argument('-S', '--SE', action='store_true', help='Only copy for SE.')
    parser.add_argument('-L', '--LE', action='store_true', help='Only copy for LE.')

    args = parser.parse_args()

    if not args.LE and not args.SE:
        args.LE = True
        args.SE = True

    config = project_config.Config(args.LE, args.SE)

    if args.file is not None and args.directory is None:
        copy_file(args, config)
    elif args.file is None and args.directory is not None:
        copy_directory(args, config)
    else:
        print('Provide either a directory or file to copy.')


if __name__ == '__main__':
    main()
