#!/bin/sh -e
# `-e` to exit right after single command are failed, we don't want to continue with errors

cd functions/src

for dir in */;
do
  name="${dir%/}"
  cd "./${dir}"

  if [ ! -f "template.yaml" ]; then
    cd ../
    continue
  fi

  echo "Building AWS SAM for '${name}' function ..."

  sam build --use-container

  cd ../
done
cd ../../