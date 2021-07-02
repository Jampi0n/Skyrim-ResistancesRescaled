import argparse
import os
import pathlib
import json


class XML:
    def __init__(self, parent, name, arg3=None):
        self.name = name
        self.attributes = None
        self.line = ""
        self.children = []
        if isinstance(arg3, type({})):
            self.attributes = arg3
        if isinstance(arg3, type("")):
            self.line = arg3
        if parent is not None:
            parent.addChild(self)

    def addChild(self, child):
        self.children.append(child)

    def __str__(self):
        return self.get_str(0)

    def get_attribute_str(self):
        s = ""
        for k, v in self.attributes.items():
            s += " " + k + "=\"" + v + "\""
        return s

    def get_str(self, indentation=0):
        s = "  " * indentation
        s += "<" + self.name
        if self.attributes is not None:
            s += self.get_attribute_str()
        s += ">"
        if self.line != "":
            assert len(self.children) == 0
            s += self.line + "</" + self.name + ">\n"
        else:
            s += "\n"
            for c in self.children:
                s += c.get_str(indentation + 1)
            s += "  " * indentation + "</" + self.name + ">\n"
        return s


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('path', type=str, help='The path of the generated project file.')
    parser.add_argument('-a', '--anonymize', action='store_true', help='Anonymizes the scripts.')
    parser.add_argument('-i', '--import', type=str, help='Additional import directories.')
    parser.add_argument('-p', '--post', type=str, nargs=2, help='Post build event.')

    args = parser.parse_args()

    project = XML(None, 'PapyrusProject',
                  {
                      'xmlns': 'PapyrusProject.xsd',
                      'Game': 'TESV',
                      'Flags': 'TESV_Papyrus_Flags.flg',
                      'Output': 'Scripts',
                      'Optimize': 'true',
                      'Release': 'false',
                      'Final': 'false',
                      'Anonymize': 'true' if args.anonymize else 'false'
                  })
    script_imports = XML(project, 'Imports')
    XML(script_imports, 'Import', os.path.join(os.environ['SkyrimLEPath'], 'Data', 'Scripts', 'Source'))
    if args.__getattribute__('import') is not None:
        import_list = args.__getattribute__('import').split(',')
        for import_single in import_list:
            XML(script_imports, 'Import', os.path.join(import_single))

    folders = XML(project, 'Folders')
    XML(folders, 'Folder', os.path.join('.', 'Scripts', 'Source'))

    if args.post is not None:
        post_build = XML(project, 'PostBuildEvent', {
            'Description': args.post[0],
            'UseInBuild': 'true'
        })
        XML(post_build, 'Command', args.post[1])

    with open(args.path, 'w') as f:
        f.write(project.get_str(0))

    tasks = pathlib.Path(args.path).parent.joinpath(pathlib.Path(".vscode"), pathlib.Path("tasks.json"))
    tasks.parent.mkdir(parents=True, exist_ok=True)
    with open(tasks, 'w') as f:
        json.dump({
            "version": "2.0.0",
            "tasks": [
                {
                    "type": "pyro",
                    "projectFile": "Papyrus.ppj",
                    "gamePath": os.path.join(os.environ['SkyrimLEPath']),
                    "problemMatcher": [
                        "$PapyrusCompiler"
                    ],
                    "group": {
                        "kind": "build",
                        "isDefault": True
                    }
                }
            ]
        }, f, indent=4, sort_keys=True)

    workspace = pathlib.Path(args.path).parent.joinpath(pathlib.Path("Papyrus.code-workspace"))
    with open(workspace, 'w') as f:
        json.dump({
            "folders": [
                {
                    "path": "."
                }
            ],
            "settings": {
                "papyrus.skyrimSpecialEdition.enabled": False,
                "papyrus.fallout4.enabled": False,
                "papyrus.skyrim.enabled": True,
            }
        }
            , f, indent=4, sort_keys=True)


if __name__ == '__main__':
    main()
