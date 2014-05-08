#!/bin/bash

#checks shit and shit.

while true; do
#If the inital hash doesn't exist, create it
if [[ ! -e ./init_hash.md5 ]]; then
  echo "[-] There were no inital hashes found, what file would you like to check? "
  read -a init_hash_file
  echo "[+] Creating inital hash..."
  md5sum $init_hash_file > ./init_hash.md5

#If the hash exists we need to create the current hash and check integrity
else
  
  #you have to pass the variable the file location using awk
  filepath=$(awk '{print $2}' ./init_hash.md5)

  echo "[+] Creating current hash now..."
  md5sum $filepath > ./current_hash.md5

    #Now that the two hashes are there, compare them for integrity
  if [[ "$( cat ./init_hash.md5)" == "$( cat ./current_hash.md5)" ]]; then
    echo "[+] All Clear"
    echo ""

  else
    #If the hashes don't match, it asks you if you want to restore from a backup or take a
    #new inital hash, in case you changed the config yourself.
    echo "[+] ERROR: HASHES DO NOT MATCH. YOU HAVE BEEN COMPROMISED." | wall
    echo "[-] Would you like to restore the file from a backup? Y\N "
    read -a user_input

    #toUpper()
    user_input=$(echo $user_input | tr '[a-z]' '[A-Z]')
    if [[ $user_input = "Y" ]]; then
        #call the restore from backup function
        echo "[+] Restoring if it was implemented..."
    else
        echo "[-] Would you like to create a new inital hash? (You actually intended this change)? "
        read -a new_init
        new_init=$(echo $new_init | tr '[a-z]' '[A-Z]')
        if [[ $new_init = "Y" ]]; then
          #Creates a new inital hash to compare against
          md5sum $filepath > ./init_hash.md5
          echo "[-] New inital hash has been created."
          echo ""
	fi
    fi
 fi


fi
sleep 5

done
