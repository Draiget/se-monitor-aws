FROM python:3.9.7-slim-buster

ENV AWS_KEY_ID='' \
    AWS_KEY_SECRET=''

RUN apt-get update && \
    apt-get install -y curl unzip

RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install

RUN pip3 --disable-pip-version-check install --user boto3

WORKDIR /opt/se-mon/
COPY initialize.py /opt/se-mon/
VOLUME ["/var/tf"]

# Set the entrypoint as we might have to use arguments of our initialization script
ENTRYPOINT ["python3", "initialize.py"]