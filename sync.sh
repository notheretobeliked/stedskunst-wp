#!/bin/bash
# orignal from https://discourse.roots.io/t/leveraging-wp-cli-aliases-in-your-wordpress-development-workflow/8414/12?u=allurewebsolutions

DEVDIR="web/app/uploads/"
DEVSITE="http://stedskunst-wp.test"
DEVCOLLATION="utf8mb4_unicode_ci"

PRODDIR="forge@stedskunst-admin.sans.website:/home/forge/stedskunst-admin.sans.website/public/shared/uploads/"
PRODSITE="https://stedskunst-admin.sans.website"
PRODCOLLATION="utf8mb4_0900_ai_ci"

# STAGDIR="forge@185.53.57.106:/home/forge/villa-arson-prototype.sans.website/current"
STAGDIR="forge@xxx.com:/home/forge/xxx.io/public/shared/uploads/"
STAGSITE="https://xxx.com"
STAGCOLLATION="utf8mb4_0900_ai_ci"

FROM=$1
TO=$2

case "$1-$2" in
  dev-prod) DIR="up";  FROMSITE=$DEVSITE;  FROMDIR=$DEVDIR;  TOSITE=$PRODSITE; TODIR=$PRODDIR; ;;
  dev-staging)    DIR="up"   FROMSITE=$DEVSITE;  FROMDIR=$DEVDIR;  TOSITE=$STAGSITE; TODIR=$STAGDIR; FROMCOL=$DEVCOPLLATION; TOCOL=$STAGCOLLATION ;;
  # dev-stagingcontenu)    DIR="up"   FROMSITE=$DEVSITE;  FROMDIR=$DEVDIR;  TOSITE=$STAGCONTSITE; TODIR=$STAGCONTDIR; ;;
  prod-dev) DIR="down" FROMSITE=$PRODSITE; FROMDIR=$PRODDIR; TOSITE=$DEVSITE;  TODIR=$DEVDIR; ;;
  # dev-remotedev)    DIR="up"   FROMSITE=$DEVSITE;  FROMDIR=$DEVDIR;  TOSITE=$REMOTEDEVSITE; TODIR=$REMOTEDEVDIR; ;;
  # remotedev-dev)    DIR="down"   FROMSITE=$REMOTEDEVSITE;  FROMDIR=$REMOTEDEVDIR;  TOSITE=$DEVSITE; TODIR=$DEVDIR; ;;
  staging-dev)    DIR="down" FROMSITE=$STAGSITE; FROMDIR=$STAGDIR; TOSITE=$DEVSITE;  TODIR=$DEVDIR; FROMCOL=$STAGCOPLLATION; TOCOL=$DEVCOLLATION ;;
  stagingcontenu-dev)    DIR="down" FROMSITE=$STAGCONTSITE; FROMDIR=$STAGCONTDIR; TOSITE=$DEVSITE;  TODIR=$DEVDIR; FROMCOL=$STAGCONTCOLLATION; TOCOL=$DEVCOLLATION ;;
  # staging-remotedev)    DIR="down" FROMSITE=$STAGSITE; FROMDIR=$STAGDIR; TOSITE=$REMOTEDEVSITE;  TODIR=$REMOTEDEVDIR; ;;
  *) echo "usage: $0 dev prod | dev staging | dev stagingcontenu | prod dev | staging dev | stagingcontenu dev" && exit 1 ;;
esac

read -r -p "Reset the $TO database and sync $DIR from $FROM? [y/N] " response
read -r -p "Sync the uploads folder? [y/N] " uploads

if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
  echo "Exporting $TO db" &&
  wp "@$TO" db export $TO-backup.sql --path=web/wp &&
  echo "Resetting $TO db" &&
  wp "@$TO" db reset --yes --path=web/wp &&
    # echo "Exporting $FROM db" &&
    # wp "@$FROM" db export --path=web/wp - > $FROM.sql &&
    # echo "Importing db" &&
    # wp "@$TO" db import ./$FROM.sql --path=web/wp && ## from production
  echo "Exporting db from @$FROM to @$TO" &&
  wp "@$FROM" db export --path=web/wp - > ./temp_export_import.sql &&
  # wp "@$TO" db import ./temp_export_import.sql --path=web/wp &&
  # if (( "$FROM" == "stagingcontenu")) 
  # then 
  #   echo "Correcting collations"
  #   IFS=''
  #   cat ./temp_export_import.sql |
  #   while read -r data; do
  #     echo "$(echo "${data//$FROMCOL/$TOCOL}")"
  #   done > temp_export_import.sql.t
  #   cat temp_export_import.sql.t > ./temp_export_import.sql
  #   rm temp_export_import.sql.t
  # fi

  cat ./temp_export_import.sql | wp "@$TO" db import - --path=web/wp && ## from dev
  echo "Modifying $TO db" &&
  wp "@$TO" search-replace $FROMSITE $TOSITE --recurse-objects --skip-columns=guid --path=web/wp
fi
if [[ "$uploads" =~ ^([yY][eE][sS]|[yY])$ ]]; then
  rsync -az --progress "$FROMDIR" "$TODIR"
fi
