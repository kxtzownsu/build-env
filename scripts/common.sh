#!/bin/bash

randstr() {
    tr -dc 'a-zA-Z0-9' </dev/urandom | head -c8
}
