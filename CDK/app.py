#!/usr/bin/env python3
import os

import aws_cdk as cdk
from pkg_resources import Environment

from cdk.cdk_stack import CdkStack

myenvironment = cdk.Environment(account='861769000153', region='us-east-1')

app = cdk.App()

CdkStack(app, "CdkStack", env=myenvironment)

app.synth()
