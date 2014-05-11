Use integrity_check.bash not the other one.
It lets you check the integrity of files by creating an inital hash. Then every 5 seconds it creates a current hash. If the hashes match, it creates a backup. If they do not match, it warns you and lets you either
A) restore from a backup
B) create a new inital hash if you did intend to change the files.

UPDATE:
Both files and directory integrity check works, just be careful of where you put your script, as it creates files, thus triggering an integrity breach in directories.
