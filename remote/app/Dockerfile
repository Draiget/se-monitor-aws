FROM lambci/lambda:build-python3.7

ARG BUILD_TARGET_PATH='.'
COPY . ./

RUN pip --disable-pip-version-check install -t ${BUILD_TARGET_PATH} -r ${BUILD_TARGET_PATH}/requirements.txt && \
    rm -rf ${BUILD_TARGET_PATH}/*.dist-info *.pth && \
    rm ${BUILD_TARGET_PATH}/requirements.txt && \
    rm ${BUILD_TARGET_PATH}/template.yaml > /dev/null 2>&1 || true && \
    rm -rf ${BUILD_TARGET_PATH}/events ${BUILD_TARGET_PATH}/.aws-sam && \
    zip -X -r lambda.zip ./

CMD mkdir -p /output/ && mv lambda.zip /output/