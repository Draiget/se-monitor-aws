#!/bin/sh -e
# `-e` to exit right after single command are failed, we don't want to continue with errors

rm -rf target/* || true
mkdir -p target

for dir in */;
do
  name="${dir%/}"
  name="${name#"function_"}"

  current_dir=$(pwd)
  cd "./${dir}"

  if [ ! $(find . -name "requirements.txt") ] || [ "${dir%/}" = "tests" ]; then
    cd ${current_dir}
    continue
  fi

  echo "Building zip for '${name}' function ..."

  extra_build_args=''
  if [ -d "python" ]; then
      extra_build_args='--build-arg BUILD_TARGET_PATH=./python'
  fi

  image_name="${name}-lambda-build-img"
  container_name="${name}-lambda-build"

  docker build ${extra_build_args} -t ${image_name} . -f ${current_dir}/Dockerfile
  docker rm -f ${container_name} > /dev/null 2>&1 || true

  docker run -i --name ${container_name} ${image_name}
  docker cp ${container_name}:/output/lambda.zip ${current_dir}/target/${name}.zip
  docker rm -f ${container_name} > /dev/null

  cd ${current_dir}
done