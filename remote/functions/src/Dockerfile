FROM lambci/lambda:build-python3.7

COPY . ./

RUN pip --disable-pip-version-check install -t . -r ./requirements.txt && \
    rm -rf *.dist-info *.pth && \
    rm requirements.txt && \
    rm template.yaml > /dev/null 2>&1 || true && \
    rm -rf ./events ./.aws-sam && \
    zip -X -r lambda.zip ./

CMD mkdir -p /output/ && mv lambda.zip /output/