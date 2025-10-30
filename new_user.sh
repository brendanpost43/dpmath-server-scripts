#!/bin/bash


set -euo pipefail # Exit on error (-e), undefined var (-u), and fail pipelines (-o pipefail)



#----BASIC INPUT AND ROOT CHECK----
USER_NAME="${1:-}" # First positional argument is the new username. Set USER_NAME equal to the first argument passed into the script; if nothing was provided, set it to an empty string instead of giving an error
ADMIN_EMAIL="${2:-}" #Second positional argument is the new username. Set ADMIN_EMAIL equal to the second argument passed into the script; if nothing was provided, set it to an empty string instead of giving an error

#NO USERNAME CHECK
if [[ -z "$USER_NAME" ]]; then # If no username was given
  echo "Usage: $0 <username> [notify_email]" # Show a tiny usage message
  exit 2 # Exit with a "bad usage" status
fi # End of the check

#ROOT CHECK
if [[ $EUID -ne 0 ]]; then # If not running as root (user id not equal to 0)
  echo "Please run as root (use sudo)." # Tell the user they need root privileges
  exit 1 # Exit with a failure code
fi # End of root check


#----VALIDATE USERNAME----
if ! [[ "$USER_NAME" =~ ^[a-z][-a-z0-9_]*$ ]]; then # Ensure username is simple/posix-ish: starts with a-z, then dashes/digits/underscores
  echo "Invalid username: $USER_NAME" # Tell the user what failed
  exit 1 # Exit with failure
fi # End of username regex check

if getent passwd "$USER_NAME" >/dev/null; then        # Check if the username already exists on the system
  echo "User already exists: $USER_NAME"              # Inform that we won’t overwrite existing users
  exit 1                                              # Exit with failure
fi                                                    # End of existence check




#----WORD SOURCE----
WORDLIST=""  # Initialize an empty variable for the wordlist path

if [[ -f /usr/share/dict/words ]]; then # Prefer the common dictionary if it exists
  WORDLIST="/usr/share/dict/words" # Use /usr/share/dict/words
elif [[ -f /usr/share/dict/american-english ]]; then # Otherwise try another common dict path
  WORDLIST="/usr/share/dict/american-english"  # Use american-english wordlist
else # If no system dictionary is available
  WORDLIST="/tmp/simple_words.txt" # Create a tiny ad-hoc list so the script still works
   
   # Write a small built-in list (lowercase 4–8 letters) to a temp file
  cat > "$WORDLIST" <<'EOF'                
apple
maple
river
rocket
stone
silver
forest
copper
delta
tango
vector
prairie
hunter
fabric
melon
ember
honey
laser
velvet
mammal
bridge
summer
winter
autumn
spring
planet
tunnel
candle
oxygen
bruin
sabre
red
wing
panther
senator
lightning
maple 
leaf
hurricane
blue
jacket
devil
islander
ranger
flyer
penguin
capital
black
hawk
avalanche
star
wild
predator
jet
coyote
mammoth
flame
oiler
king
shark
kraken
golden 
knight
duck
canuck
canadian
EOF
fi
# End of small inline wordlist                                            
# End of wordlist selection




#----FUNCTION: SELECT A RANDOM WORD----
pick_word() { # Define a simple function called pick_word
  tr '[:upper:]' '[:lower:]' < "$WORDLIST" | # Lowercase the wordlist so filtering is consistent
  grep -E '^[a-z]{4,11}$'       |  # Keep only words of length 4–11 letters
  shuf -n 1                         || # Shuffle and take one random word (fallback if shuf fails)
  echo "alpha" # If the pipeline fails for any reason, fallback to "alpha"
} # End of pick_word function


#----Build a password: word1.word2.word3 with one 3-digit chunk----

W1="$(pick_word)" # Pick the first random word
W2="$(pick_word)" # Pick the second random word
W3="$(pick_word)" # Pick the third random word
NUM="$(shuf -i 100-999 -n 1)" # Pick a random three-digit number between 100 and 999

BASE="${W1}.${W2}.${W3}" # Define the base as pattern word1.word2.word3

SPOT="$(shuf -i 1-6 -n 1)" # Choose a random insertion spot from 1 to 6

if   [[ "$SPOT" -eq 1 ]]; then  # If spot is 1 before first word
  PASS="${NUM}${W1}.${W2}.${W3}" # Insert number before word1
elif [[ "$SPOT" -eq 2 ]]; then # If spot is 2 after first word
  PASS="${W1}${NUM}.${W2}.${W3}" # Insert number immediately after word1
elif [[ "$SPOT" -eq 3 ]]; then # If spot is 3 after the first dot
  PASS="${W1}.${NUM}${W2}.${W3}" # Insert number right after the first period
elif [[ "$SPOT" -eq 4 ]]; then # If spot is 4 after second word
  PASS="${W1}.${W2}${NUM}.${W3}" # Insert number immediately after word2
elif [[ "$SPOT" -eq 5 ]]; then # If spot is 5 after the second dot
  PASS="${W1}.${W2}.${NUM}${W3}" # Insert number right after the second period
else # Otherwise (spot 6) after third word (end)
  PASS="${W1}.${W2}.${W3}${NUM}" # Insert number at the end
fi # End of insertion logic



#----Create the user, set password, force password change on first login----
useradd -m -s /bin/bash "$USER_NAME" # Create the user with a home directory and Bash shell

echo "${USER_NAME}:${PASS}" | chpasswd # Set the user’s password non-interactively via chpasswd

chage -d 0 "$USER_NAME" # Force the user to change password at first successful login



#----ADD THE NEW USER TO THE MATH NAS----
NAS_ROOT ="/mnt/nas_math"
NAS_USER_DIR="${NAS_ROOT}/${USER_NAME}"

mkdir "$NAS_USER_DIR" #create a directory for the user (USE THE USER'S SERVER UNAME)

sudo chown "${USER_NAME}:admin" "$NAS_USER_DIR" #change ownership and group

sudo chmod 750 "$NAS_USER_DIR" #change permissions; user can read and write while admin can only ready



#----Send the user credentials to admin so they can inform the user---
MAIL_BODY="Username: ${USER_NAME}\nPassword: ${PASS}\nHost: $(hostname -f)\nRotation: forced on first login"  # Prepare the email body text

if [[ -n "$ADMIN_EMAIL" ]]; then # If an email address was provided as the second argument
  if command -v mail >/dev/null 2>&1; then # If the 'mail' command exists on this system
    printf "%b" "$MAIL_BODY" | mail -s "New account: ${USER_NAME}" "$ADMIN_EMAIL"  # Send the email with subject and body
    SENT_STATUS=$? # Capture the exit status from the mail command
  else # If the 'mail' command is not available
    echo "Note: 'mail' command not found; displaying credentials below."  # Explain we can’t email
    echo -e "$MAIL_BODY" # Print the credentials to the terminal as a fallback
    SENT_STATUS=1 # Mark as a non-success so we can act if desired
  fi # End check for 'mail' binary

  if [[ $SENT_STATUS -ne 0 ]]; then # If sending the email failed
    echo "Warning: Email send appears to have failed." # Warn the operator
  fi  # End of email failure handling
else  # If no email was provided
  echo -e "$MAIL_BODY" # Simply print the credentials so you can copy them securely yourself
fi  # End of "email or print" branch


#----Minimal audit (no passwords)
LOG_DIR="/var/log/ops" # Send logs to /var/log/ops
LOG_FILE="${LOG_DIR}/newuser.log" # Choose a single log file name

mkdir -p "$LOG_DIR" # make sure the log directory exists
chmod 700 "$LOG_DIR" # Restrict the directory so only root can read it
touch "$LOG_FILE" # Ensure the log file exists
chmod 600 "$LOG_FILE" # Restrict the file so only root can read it

echo "$(date -Is) user=${USER_NAME} host=$(hostname -f) action=create" >> "$LOG_FILE"  # Append a one-line audit entry without the password


echo "Created user '${USER_NAME}'. Password change is required at first login. User now has access to the NAS. "  # Tell the operator we’re done
