import pytest

from hello_world import app
from model.aws.ec2 import AWSEvent
from model.aws.ec2.ec2_instance_state_change_notification import EC2InstanceStateChangeNotification
from model.aws.ec2 import Marshaller

@pytest.fixture()
def eventBridgeec2InstanceEvent():
    """ Generates EventBridge EC2 Instance Notification Event"""

    return {

    }


def test_lambda_handler(eventBridgeec2InstanceEvent, mocker):

    ret = app.lambda_handler(eventBridgeec2InstanceEvent, "")

    awsEventRet:AWSEvent = Marshaller.unmarshall(ret, AWSEvent)
    detailRet:EC2InstanceStateChangeNotification = awsEventRet.detail

    assert detailRet.instance_id == "i-abcd1111"
    assert awsEventRet.detail_type.startswith("HelloWorldFunction updated event of ")