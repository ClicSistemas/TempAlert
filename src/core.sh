#!/bin/sh

sendEmail() {
   echo "Send the email to the administrator..."
   /usr/bin/sendEmail -f $SMTPEmailFrom -t $EmailTo -u $1 -m $2 -s $SMTPServer -xu $SMTPLogin -xp $SMTPPass
}
powerOff() {
   echo "Powering off the machine, high temperature in the sensors.."
   shutdown -r now "Powering off the machine, high temperature in the sensors.."
}

echo "Clic Sistemas Ltda"
echo "TempAlert with lm-sensors"

echo "Loading the configuration..."
source ./config.cfg

echo "Running the sensors.."

results=$(sensors -u -A)

echo "Checking the reads.."
for i in "${SensorList[@]}"
do
        # Parse Variables names
        senDscVrName="SENSOR_$i"

        senWarnVrName="$senDscVrName"
        senWarnVrName+="_WARN"

        senCritVrName="$senDscVrName"
        senCritVrName+="_CRIT"

        senPoffVrName="$senDscVrName"
        senPoffVrName+="_POWEROFF"

        senCpOffVrName="$senDscVrName"
        senCpOffVrName+="_CANPOFF"

        senSdWarnVrName="$senDscVrName"
        senSdWarnVrName+="_SEWARNING"

        senKeyVrName="$senDscVrName"
        senKeyVrName+="_KEY"

        # DEBUG INFO
        if [[ $InDebug == 1 ]] 
        then
           echo "Sensor Cfg: $senDscVrName"
           echo "Sensor Warn Temp Cfg: $senWarnVrName"
           echo "Sensor Critical Temp Cfg: $senCritVrName"
           echo "Sensor PowerOff Temp Cfg: $senPoffVrName"
           echo "Can Power Off if too hot Cfg: $senCpOffVrName"
           echo "Send Email if Warning Cfg: $senSdWarnVrName"
           echo "Sensor Key Cfg: $senKeyVrName"
        fi

        # Evaluates the Variables
        senName=${!senDscVrName}
        senWarnTemp=${!senWarnVrName}
        senCritTemp=${!senCritVrName}
        senPoffTemp=${!senPoffVrName}
        senCanPoff=${!senCpOffVrName}
        senSendEWarn=${!senSdWarnVrName}
        senKey=${!senKeyVrName}

	echo "Sensor: $senName"

        # DEBUG INFO
        if [[ $InDebug == 1 ]] 
        then
           echo "Sensor Warn Temp: $senWarnTemp"
           echo "Sensor Critical Temp: $senCritTemp"
           echo "Sensor PowerOff Temp: $senPoffTemp"
           echo "Can Power Off if too hot: $senCanPoff"
           echo "Send Email if Warning: $senSendEWarn"
           echo "Sensor Key: $senKey"
        fi

	while read -r line; do
		if [[ $line == *"$i:"* ]] 
		then
		  echo "Found $i"
                  echo "Checking..."

		  while read -r cLine; do
			if [[ $cLine == *"$senKey"* ]]
			then
			   cRead=${cLine#$senKey}
			   cRead="${cRead##*( )}"
			   cRead=${cRead%.*}
			   cRead=$((cRead*1))

			   echo  "Readed: $cRead"		   

			   if [[ $cRead -ge $senWarnTemp ]]
			   then
				echo "Sensor in warning temp!"

                                if [[ $senSendEWarn == 1 ]] 
                                then
                                    emaiBody="The TempAlert captured a warning reading from the sensor:"
                                    emailBody+="\nMachine: $HOSTNAME"
                                    emailBody+="\nSensor: $senName"                                
                                    emailBody+="\nReading: $cRead"

                                    sendEmail "TempAlert: Warning Reading Alert" "$emailBody"
                                fi
			   fi

			   if [[ $cRead -ge $senCritTemp ]]
                           then
                                echo "Sensor in critical temp!"

                                emaiBody="The TempAlert captured a critical reading from the sensor:"
                                emailBody+="\nMachine: $HOSTNAME"
                                emailBody+="\nSensor: $senName"                                
                                emailBody+="\nReading: $cRead"

                                sendEmail "TempAlert: Critical Reading Alert" "$emailBody"
                           fi

                           if [[ $cRead -ge $senPoffTemp ]]
                           then
                                emaiBody="The TempAlert captured a extreme reading from the sensor:"
                                emailBody+="\nMachine: $HOSTNAME"
                                emailBody+="\nSensor: $senName"                                
                                emailBody+="\nReading: $cRead"
                                emailBody+="\nAction: Try to power off"

                                sendEmail "TempAlert: Extreme Reading Alert" "$emailBody"

                                echo "Sensor in extreme temp! Powering the machine off!"
                                if [[ $senCanPoff == 1 ]]
                                then
                                   powerOff
                                fi 
                           fi

                           break
			fi
     		  done <<< "$results"

                  break
		fi
	done <<< "$results"
done
