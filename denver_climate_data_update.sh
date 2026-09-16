# !/bin/bash
#
# Timothy Salazar
# 7/7/23
#
# This script updates the data for the Denver Water Climate streamlit application
# located at:
#    https://denver-water-climate.streamlit.app/
# The streamlit application's source code is located in a github repo located at:
#    https://github.com/LREadmin/multipage
#
# This script performs the following steps:
#   - changes to the multipage repo, which is a git repo
#   - does a "git pull" to be sure the repo is up to date
#   - runs Data_fetch.py:
#      - with the "--snotel" argument, to download the SNOTEL data
#      - with the "--weather" argument, to read the weather data from excel documents
#        stored in a dropbox account we made for Denver Water
#   - does "git add", adding the files:
#      - DW_weather.csv.gz
#      - SNOTEL_data_raw.csv.gz
#   - does a "git commit"
#   - pushes the updated repo to main

VERBOSE=''
WEATHER=0
SNOTEL=0
MOISTURE=0
DRY_RUN=0
while getopts 'hvwsmd' OPTION; do
    case "$OPTION" in
        h)
            echo "  HELP:"
            echo "-------"
            echo -e "\t-v: verbose. Print info to stdout as program runs"
            echo -e "\t-w: weather. Pulls the weather data from dropbox, formats and saves it."
            echo -e "\t-s: snotel. Pulls the SNOTEL data from the API, formats and saves it"
            echo -e "\t-m: soil moisture. Pulls soil moisture data from USDS api, formats, and saves it."
            echo -e "\t-d: dry run. Run through steps selected (-v or -w), but don't perform any git operations"
            exit 0
            ;;
        v)
            VERBOSE='-v'
            ;;
        w)
            WEATHER=1
            ;;
        s)
            SNOTEL=1
            ;;
        m)
            MOISTURE=1
            ;;
        d)
            DRY_RUN=1
            ;;
    esac
done

verbose_text(){
    if [[ "$VERBOSE" = '-v' ]]; then
        echo "$1"
    fi
}

# The first part of the commit message, with timestamp
REFRESH_TIMESTAMP=$(date --iso-8601=minutes)
COMMIT_MSG="AUTOMATIC DATA REFRESH: $REFRESH_TIMESTAMP"

# change to the dw_climate_dashboard directory
cd /home/cron/streamlit_refresh/dw_climate_dashboard
# update repo
verbose_text "Performing git pull..."
git pull
# activate conda
source ~/miniconda3/etc/profile.d/conda.sh
# activate conda environment
conda activate den

# get SNOTEL data
if [[ $SNOTEL -eq 1 ]]; then
    verbose_text "Beginning SNOTEL data refresh..."
    python Data_fetch.py --snotel $VERBOSE
    # git add new file
    git add SNOTEL_data_raw.csv.gz
    # add "SNOTEL data" to commit message
    COMMIT_MSG=$COMMIT_MSG+", SNOTEL data"
    verbose_text "SNOTEL data refresh complete"
fi

# get weather data
if [[ $WEATHER -eq 1 ]]; then
    verbose_text "Beginning weather data refresh..."
    python Data_fetch.py --weather $VERBOSE
    # git add new file
    git add DW_weather.csv.gz
    # add "weather data" to commit message
    COMMIT_MSG=$COMMIT_MSG+", weather data"
    verbose_text "Weather data refresh complete"
fi

# get soil moisture data
if [[ $MOISTURE -eq 1 ]]; then
    verbose_text "Beginning soil moisture data refresh..."
    python Data_fetch.py --soil-moisture $VERBOSE
    # git add new file
    git add SNOTEL_SMS.csv.gz
    # add "moisture data" to commit message
    COMMIT_MSG=$COMMIT_MSG+", moisture data"
    verbose_text "Soil moisture data refresh complete"
fi

if [[ $DRY_RUN -eq 0 ]]; then
    if [[ "$VERBOSE" = '-v' ]]; then
        echo "Preparing to commit and push..."
        git status
    fi
    #commit changes
    git commit -m "$COMMIT_MSG"
    # push changes
    git push
    verbose_text "Automatic data update complete."
fi
