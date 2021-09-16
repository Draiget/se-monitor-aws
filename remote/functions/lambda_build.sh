#!/bin/sh -e
# `-e` to exit right after single command are failed, we don't want to continue with errors

rm -rf functions/target/* || true
mkdir -p functions/target

cd functions/src
for dir in */;
do
  name="${dir%/}"
  echo "Building zip for '${name}' function ..."
  cd "./${dir}"

  if [ ! -f "requirements.txt" ]; then
    cd ../
    continue
  fi

  image_name="${name}-lambda-build-img"
  container_name="${name}-lambda-build"

  docker build -t ${image_name} . -f ../Dockerfile
  docker rm -f ${container_name} > /dev/null 2>&1 || true

  docker run -i --name ${container_name} ${image_name}
  docker cp ${container_name}:/output/lambda.zip ../../target/${name}.zip
  docker rm -f ${container_name} > /dev/null

  cd ../
done
cd ../../