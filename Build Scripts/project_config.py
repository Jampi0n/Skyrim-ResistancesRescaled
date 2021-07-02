import os
import pathlib
import json

class Config:
    def __init__(self, le, se):
        self.project_dir = pathlib.Path(__file__).parent

        with open(self.project_dir.parent.joinpath(pathlib.Path('project.json'))) as f:
            data = json.load(f)
            self.version = data['version']
            self.mod_name = data['name']
            self.output = data['output']
            self.identifier = data['identifier']

            self.le = le
            self.se = se

            self.mod_directories = []


            if le:
                le_path = os.environ['SkyrimLEModPath']
                assert le_path != "", "Set environment variable " + "SkyrimLEModPath" + "!"
                self.mod_directories.append(pathlib.Path(le_path).joinpath(pathlib.Path(self.output)))
            if se:
                se_path = os.environ['SkyrimSEModPath']
                assert se_path != "", "Set environment variable " + "SkyrimSEModPath" + "!"
                self.mod_directories.append(pathlib.Path(se_path).joinpath(pathlib.Path(self.output)))
