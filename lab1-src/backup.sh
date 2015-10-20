#!/bin/bash
c=1 #setting a counter variable
timestamp=$(date +"%Y-%m-%d-%H-%M-%S"+$1) #every file has a unique timestamp
cp $1 $2/$timestamp #copying it to the backup directory
while [ 1 ] ; do

sleep $3 #sleep for the desired amount

CHANGE=$(diff -u $1 $2/$timestamp) #diff the two files and save the output
len=${#CHANGE} #storing the length
if [ $len -ne 0 ]; then
	if [ $c -ge $4 ]; then #checks to see if the counter is greater than equal to max backups
	let c=c-1 #decrements the counter variable
	rm $2/`ls $2 | head -n 1` 

        #echo `$2/`ls $2 | head -n 1``
	fi
    timestamp=$(date +"%Y-%m-%d-%H-%M-%S"+$1) # getting the unique timestamp as the file name
    cp $1 $2/$timestamp #copying it into the backup directory
    let c=c+1 
    # echo $c
    echo $CHANGE>tmp-message
    /usr/bin/mailx -s "mail-hello" $USER < tmp-message #sends the email
fi
done

