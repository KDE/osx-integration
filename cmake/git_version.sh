#!/bin/sh

exec git describe | sed -e 's/-g.*//' -e 's/-/./'
