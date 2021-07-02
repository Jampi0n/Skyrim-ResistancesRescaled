import argparse
import os
import pathlib
import project_config


def clean_directory(args, config):
    include = args.include.split(',') if args.include is not None else []
    exclude = args.exclude.split(',') if args.exclude is not None else []
    for mod_dir in config.mod_directories:
        dir_path = pathlib.Path(mod_dir).joinpath(pathlib.Path(args.directory))
        for root, dir_names, walk_files in os.walk(dir_path, topdown=False):
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
                    remove_path = os.path.join(root, file_name)
                    os.remove(remove_path)
            for dir_name in dir_names:
                try:
                    os.rmdir(os.path.join(root, dir_name))
                except OSError:
                    pass
        if args.root:
            try:
                os.rmdir(dir_path)
            except OSError:
                pass


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('directory', type=str, help='The directory, whose files are copied.')
    parser.add_argument('-i', '--include', type=str,
                        help=' By default, all files are included.'
                             ' Use * at the start to match suffixes:"*.txt".'
                             ' Use , to combine included files:"*.txt,meta.ini"')
    parser.add_argument('-e', '--exclude', type=str,
                        help=' By default, no files are excluded.'
                             ' Use * at the start to match suffixes:"*.txt".'
                             ' Use , to combine excluded files:"*.txt,meta.ini"')
    parser.add_argument('-S', '--SE', action='store_true', help='Only copy for SE.')
    parser.add_argument('-L', '--LE', action='store_true', help='Only copy for LE.')
    parser.add_argument('-r', '--root', action='store_true', help='Removes the specified directory, if it is empty.')

    args = parser.parse_args()

    if not args.LE and not args.SE:
        args.LE = True
        args.SE = True

    config = project_config.Config(args.LE, args.SE)

    clean_directory(args, config)


if __name__ == '__main__':
    main()
