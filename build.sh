#!/usr/bin/env bash                                                                                                   [40/4517]
# -*- coding: utf-8 -*-
set -ex       
            
#VAR="--network=host --pull=true --progress=auto "
VAR="--pull=true --platform linux/arm64 "                                                                                     
              
usage() { 
    cat << EOF   
    $0 [-n] [-p] [-l] [-g] -d <dir>             
        -n  : no-cache
        -l  : add latest tag
        -g  : git push
        -d  : directory
EOF
}

while getopts "d:gfnl" OPTS
do
        case ${OPTS} in
        n)
                    VAR+="${VAR} --no-cache "
                    ;;
        d)
            echo $OPTARG
            TARGET+=("$OPTARG")
            ;;
        g)
            #no git push
            GIT_ENABLE=1
            ;;
        l)
            # add latest tag
            LATEST=1
            ;;                                                                                                         [6/4517]
        ?|h)
            usage
            exit 2
            ;;
        *)
            usage
            exit 1
            ;;
        esac
done

# SET THE FOLLOWING VARIABLES
# docker hub username
USERNAME=kometchtech

for val in "${TARGET[@]}"
do
        # image name
        IMAGE=${val%/}

        version=`cat ${IMAGE}/VERSION`

        if [ -n ${IMAGE} ]; then
            if [ -d ./${IMAGE} ]; then
                version=`cat ${IMAGE}/VERSION`
                docker buildx build ${VAR} \
                --build-arg VERSION=$version \
                --rm -t ${USERNAME}/${IMAGE}:${version} \
                ${IMAGE}/
            fi
        else
            exit 1
        fi
        if [ ! -z ${LATEST} ]; then
            docker tag ${USERNAME}/${IMAGE}:${version} ${USERNAME}/${IMAGE}:latest
        docker rmi ${USERNAME}/${IMAGE}:${version}
        fi
done
