#!/bin/sh

aws configure
tofu init
tofu plan
tofu apply
