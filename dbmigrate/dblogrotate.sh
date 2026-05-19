LOGFILE="/root/net2300/dbmigrate/dbmigrate.log"

if [ -f "$LOGFILE" ]; then
	rm "$LOGFILE"

	touch "$LOGFILE"
	echo "Log rotated on $(date)"
else
	echo "Log file not found, nothing to rotate."
fi
