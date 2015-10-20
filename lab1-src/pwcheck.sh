#!/bin/bash
pass=$(egrep '.*' $1)
count=0 #sets counter variable
len=${#pass} #gets the length of the password
if [ $len -lt 6 ] || [ $len -gt 32 ]; then   #checks for invalid length
	echo "Error.Password length invalid."
fi
if [ $len -gt 6 ] && [ $len -lt 32 ]; then   #checks for valid length and gets the initial count
	count=$len
fi
if egrep -q [#$+%@] $1 ; then  #checks the password for special characters
	let count+=5  #increments the counter variable by 5
fi
if egrep -q [0-9] $1 ; then  #checks to see if the password has a number
	let count+=5 #increments the count by 5
fi
if egrep -q [a-zA-Z] $1; then #checks to see if the password has a letter
	let count+=5 #increments the count by 5 
fi
if egrep -q [a-z][a-z][a-z] $1; then
	let count-=3 # checks the password for three consecutive lowercase letters and decrements by 3 if true
fi
if egrep -q [A-Z][A-Z[A-Z] $1; then  #checks for three consecutive uppercase letters
	let count-=3  #decrements by three
fi
if egrep -q [0-9][0-9][0-9] $1;then #checks for 3 consecutive numbers
	let count-=3  #decrements by 3
fi
if egrep -q '([a-zA-Z])\1+' $1;then  #checks for repetition
	let count-=10 #decrements by 10
fi
if [ $len -gt 6 ] && [ $len -lt 32 ]; then
echo "Password Score: $count" #prints the total count if it is in correct word length range
fi
