# Installs zoom as needed on Apple Silicon or Intel macs.

exitcode=0

# Determine OS version
# Save current IFS state

OLDIFS=$IFS

IFS='.' read osvers_major osvers_minor osvers_dot_version <<< "$(/usr/bin/sw_vers -productVersion)"

# restore IFS to previous state

IFS=$OLDIFS

  # Check the processor

  processor=$(/usr/sbin/sysctl -n machdep.cpu.brand_string | grep -o "Intel")
  
  if [[ -n "$processor" ]]; then
	echo "Installing Intel Package"
	installer -pkg /PATH/TO/PKG -target /
	echo "done installing Intel package"
  else
	echo "Installing M1 package"
	installer -pkg PATH/TO/PKG -target /
	echo "done installing m1 package"
  fi   
exit $exitcode
