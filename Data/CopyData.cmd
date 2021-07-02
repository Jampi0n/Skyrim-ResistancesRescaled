::Copies the scripts from this directory to the mod directories.
python "..\Build Scripts\clean_files.py" "" -e "*.psc,*.pex,*.dll,*.esp,meta.ini"
python "..\Build Scripts\copy_files.py" -d Data -t ""
python "..\Build Scripts\copy_files.py" -L -d DataLE -t ""
python "..\Build Scripts\copy_files.py" -S -d DataSE -t ""
