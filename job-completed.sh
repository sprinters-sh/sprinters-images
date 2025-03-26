#!/bin/bash

echo "Temp Usage: $(df | grep /dev | head -1  | awk '{print $5}')"

/publish-event.sh job-completed
