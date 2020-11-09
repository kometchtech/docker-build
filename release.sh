#!/usr/bin/env bash
# -*- coding: utf-8 -*-
set -ex

VAR1="$@"

usage() {
    cat << EOF
    $0 [-n] [-p] [-l] [-g] -d <dir>
        -n  : no-cache
        -p  : progress plane (default: auto)
        -l  : add latest tag
        -g  : git push
        -d  : directory
EOF
}


while getopts "d:gnl" OPTS; do
    case ${OPTS} in
        n)
            VAR="--no-cache"
            ;;
        p)
            VAR="${VAR} --progress=plane "
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
            ;;
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

shift $(($OPTIND - 1))

echo "release: ${TARGET[@]}"

# SET THE FOLLOWING VARIABLES
# docker hub username
USERNAME=kometchtech

    
for val in "${TARGET[@]}"
do
    # image name
    IMAGE=${val%/}
    
    # bump version
    version=`cat ${IMAGE}/VERSION`
    echo "version: ${version}"
    
    # run build
    echo "build options: " ${VAR1}
    ./build.sh ${VAR1}
    
    # tag it
    if [ ! -z ${GIT_ENABLE} ]; then
        git checkout develop
        git add ${IMAGE}/*
        git commit -m ":heavy_exclamation_mark: update ${IMAGE}: version ${version}"
        git push
    fi
    
    # add docker tag
    if [ ! -z ${LATEST} ]; then
        docker tag ${USERNAME}/${IMAGE}:latest ${USERNAME}/${IMAGE}:${version}
    fi
    docker tag ${USERNAME}/${IMAGE}:${version} docker.pkg.github.com/${USERNAME}/docker-build/${IMAGE}:${version}
    
    # Vulnerabilit Scan
    if [ "${IMAGE}" != "coredns" -a "${IMAGE}" != "dnscrypt-proxy" -a "${IMAGE}" != "glider" -a "${IMAGE}" != "gobetween" -a "${IMAGE}" != "zabbix-agent2"]; then
        #trivy --download-db-only -c
#        trivy --light --removed-pkgs --exit-code 0 -s HIGH ${USERNAME}/${IMAGE}:${version}
#        trivy --light --removed-pkgs --exit-code 1 -s CRITICAL ${USERNAME}/${IMAGE}:${version}
        docker pull aquasec/trivy
        docker run --rm -v ./cache:/root/.cache/ aquasec/trivy ${USERNAME}/${IMAGE}:${version}
    fi
    
    # push it
    if [ ! -z ${LATEST} ]; then
        docker push ${USERNAME}/${IMAGE}:latest
    fi
    docker push ${USERNAME}/${IMAGE}:${version}
    docker push docker.pkg.github.com/${USERNAME}/docker-build/${IMAGE}:${version}

    # image remove
    docker rmi ${USERNAME}/${IMAGE}:${version}
    docker rmi docker.pkg.github.com/${USERNAME}/docker-build/${IMAGE}:${version}
done

# image remove
docker rmi ${USERNAME}/${IMAGE}:${version}
docker rmi docker.pkg.github.com/${USERNAME}/docker-build/${IMAGE}:${version}

exit 0
