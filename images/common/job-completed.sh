#!/bin/bash

echo "Temp usage : $(df | grep /dev | head -1  | awk '{print $5}')"

/publish-event.sh job-completed
