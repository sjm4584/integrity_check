#!/bin/bash

#---------------------------------------------------------------------------------------
#There are two scenarios, with two cases:					       	|
#---------------------------------------------------------------------------------------|
#				Scenario 1: Checking a file			       	|
#---------------------------------------------------------------------------------------|
#The script creates an inital hash, 'inital_hash.md5'. Then every 5 seconds the script	|
#creates a current hash, 'current_hash.md5', which is checked against the inital hash 	|
#-----------------------------------------						|
#	Case 1: Hashes match								|
#-----------------------------------------						|
#The inital hash and the current hash match, and the script takes a backup of the file.	|
------------------------------------------						|
#	Case 2: Hashes don't match							|
#-----------------------------------------						|
#The inital hash and current hash don't match. The script alerts the user by using the	|
#'wall' command alerting all users that they've been compromised. Now you can either	|
#restore from a backup, or if you intended the change, you can create a new inital	|
#hash that will be used for the comparison						|
#---------------------------------------------------------------------------------------|
#				Scenario 2: Checking a directory			|
#---------------------------------------------------------------------------------------|
#You take a hash of all the files in the directory, then take a hash of all of the	|
#hashes.										|
#---------------------------------------------------------------------------------------

main(){
  #We have a while loop that we use instead of crontab because then the script can
  #prompt us when we get compromised.
  while true; do
    #We check for the inital hash of the file, if it's not there we have to get user input
    #the '-e' flag tells bash to check for the existence of the file.
    if [[ ! -e ./inital_hash.md5 ]]; then
      echo "[-] There were no inital hashes found, what file would you like to check? "
      read -a init_hash_file
    
      #Determine if the given item is a file or directory, or neither.
      if [[ -d $init_hash_file ]]; then
        echo "[+] Creating inital hash of directory..."

	#Calls the 'hash_directory' function and passes the variable $init_hash_file.
        hash_directory $init_hash_file;

      elif [[ -f $init_hash_file ]]; then
        echo "[+] Creating inital hash of file..."
        hash_file $init_hash_file;
      else
        echo "[+] That's not an option, exiting."
        exit 1
      fi
    
    #If the inital hash exists, we need to create the current hash and check integrity
    else
      #you have to pass the variable the file location using awk
      filepath=$(awk '{print $2}' ./inital_hash.md5)

      #Now that we have the path, we determine if it's a file or dir and call func
      echo "[+] ------- Current Hash Stage -------- [+]"
      if [[ -d $filepath ]]; then
        echo "[+] Creating current hash of directory now..."
        hash_directory $filepath "c";
      elif [[ -f $filepath ]]; then
        echo "[+] Creating current hash of file now..."
        hash_file $filepath "c";
      else
        echo "[+] That's not an option, exiting."
        exit 1  
      fi

      #calls the comparison function to compare inital hash and current hash and passes
      #the filepath to the file being hashed so we can create a backup if necessary.
      hash_comparison $filepath
    fi
    #Run the script every 5 seconds
    sleep 5
  done
}


# ------        functions       ------ #


#This function lets us hash a directory, yay for the mega hash.
hash_directory(){
  if [[ $2 == "c" ]]; then
    #This line finds all the files in the directory, sorts them, and then creates
    #a hash of each file. Once this is done, it creates a hash of all the
    #hashes, so we only have one hash to compare against instead of lots
    #of them, reducing potential for errors.
    find $1 -type f -print0 | sort -z | xargs -0 md5sum | md5sum > ./current_hash.md5
  else
    find $1 -type f -print0 | sort -z | xargs -0 md5sum | md5sum > ./inital_hash.md5
    #This command replaces the '-' that is in the file with the directory that the user 
    #wants to check. This is because when you create the hash of hashes it doesn't have
    #the path. This causes problems because then our current hash won't know where to
    #take the hash from.
    sed -e "s|-|$1|" -i ./inital_hash.md5
  fi
}

#This function just hashes a file. It's boring and probably didn't need a function.
hash_file(){
  #$1 is the variable that is getting passed, i.e. the file with it's path.
  
  #We need a way to determine whether or not we are creating the current hash or the
  #inital hash, so we send a 'c' as a function parameter to indicate a current hash.
  if [[ $2 == "c" ]]; then
    md5sum $1 > ./current_hash.md5
  else
    md5sum $1 > ./inital_hash.md5
  fi
}

#This function extracts and compares the hashes.
hash_comparison(){
  #We need to extract them with awk because the md5sum file stores the hash in the file
  #as <hash_of_file> <location_of_file> and the location can mess things up.

  Ihash=$(awk '{print $1}' ./inital_hash.md5)
  Chash=$(awk '{print $1}' ./current_hash.md5)

  #$1 is the filepath to the file we are checking so we can make a backup.
  if [[ $Ihash == $Chash ]]; then
    echo "[+] All Clear"; echo "";
    cp -r $1 ./file.backup
  else
    #If the hashes don't match, you're in trouble. It asks you if you want to restore
    #from a backup, or take a new inital hash (if you intended to make the change)
    #It uses 'wall' so you will see it in any shell as it's a pretty big deal.
    echo "[+] ERROR: HASHES DO NOT MATCH. YOU HAVE BEEN COMPROMISED." | wall
    echo "[-] Would you like to restore from a backup? Y/N "
    read -a user_input

    #toUpper()
    user_input=$(echo $user_input | tr '[a-z]' '[A-Z]')
    if [[ $user_input = "Y" ]]; then
      echo "[+] Restoring from backup..."
      cp -r file.backup $1
    else
      echo "[-] Would you like to create a new inital hash? (You wanted this change) Y/N "
      read -a new_init

      new_init=$(echo $new_init | tr '[a-z]' '[A-Z]')
      if [[ $new_init = "Y" ]]; then
        #$1 is the $filepath so we can tell if its a dir or a file
        if [[ -d $1 ]]; then
          hash_directory $1
        elif [[ -f $1 ]]; then
          hash_file $1
        fi
        echo "[+] New inital hash has been created."; echo "";
      fi
    fi
  fi
}

#Calls the main function. 
main "$@"
