::Copies the scripts from this directory to the mod directories.
python "..\Build Scripts\clean_files.py" Scripts -r -i "*.psc,*.pex"
python "..\Build Scripts\copy_files.py" -d Scripts -t Scripts -i "*.pex,*.psc"
